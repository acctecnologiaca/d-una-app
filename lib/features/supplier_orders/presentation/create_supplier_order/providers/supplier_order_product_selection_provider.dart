import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../portfolio/domain/models/aggregated_product.dart';
import '../../../../portfolio/domain/models/product_search_filters.dart';
import '../../../../portfolio/presentation/providers/suppliers_provider.dart';
import '../../../../../shared/models/paginated_state.dart';
import 'create_supplier_order_provider.dart';

part 'supplier_order_product_selection_provider.g.dart';

@riverpod
Future<List<AggregatedProduct>> supplierOrderProductSuggestions(
  Ref ref, {
  required String supplierId,
  String query = '',
}) async {
  final repo = ref.watch(suppliersRepositoryProvider);
  final results = await repo.searchAggregatedProducts(
    query,
    supplierIds: [supplierId],
  );
  return results.map((json) => AggregatedProduct.fromJson(json)).toList();
}

@riverpod
Future<List<Map<String, dynamic>>> supplierOrderProductBranches(
  Ref ref, {
  required String supplierId,
  required AggregatedProduct product,
}) async {
  final repository = ref.read(suppliersRepositoryProvider);
  return repository.getProductSuppliers(
    name: product.name,
    brand: product.brand,
    model: product.model,
    uom: product.uom,
    supplierIds: [supplierId],
  );
}

@riverpod
Future<Set<String>> branchProductKeys(Ref ref, String branchId) async {
  final response = await Supabase.instance.client
      .from('supplier_branch_stock')
      .select('supplier_products(name, brand, model, uom)')
      .eq('branch_id', branchId);

  final keys = <String>{};
  final list = response as List<dynamic>;
  for (final row in list) {
    final sp = row['supplier_products'];
    if (sp is Map<String, dynamic>) {
      final name = sp['name'] as String? ?? '';
      final brand = sp['brand'] as String? ?? '';
      final model = sp['model'] as String? ?? '';
      final uom = sp['uom'] as String? ?? '';
      keys.add('$name|$brand|$model|$uom'.toUpperCase());
    }
  }
  return keys;
}

@riverpod
class PaginatedSupplierOrderProductSearch extends _$PaginatedSupplierOrderProductSearch {
  static const int _limit = 25;
  String? _query;
  ProductSearchFilters _filters = const ProductSearchFilters();
  List<String> _selectedBranchIds = const [];

  @override
  FutureOr<PaginatedState<AggregatedProduct>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<AggregatedProduct>> _fetchPage(int offset) async {
    final supplierId = ref.read(createSupplierOrderProvider).supplierId;
    if (supplierId == null || supplierId.isEmpty) {
      return PaginatedState<AggregatedProduct>(
        items: const [],
        hasReachedEnd: true,
        currentOffset: offset,
      );
    }

    final repository = ref.read(suppliersRepositoryProvider);
    final results = await repository.searchAggregatedProducts(
      _query ?? '',
      supplierIds: [supplierId],
      brands: _filters.brands.isNotEmpty ? _filters.brands : null,
      categories: _filters.categories.isNotEmpty ? _filters.categories : null,
      minPrice: _filters.minPrice,
      maxPrice: _filters.maxPrice,
      offset: offset,
      limit: _limit,
    );

    var items = results.map((json) => AggregatedProduct.fromJson(json)).toList();

    // Client-side branch filtering
    if (_selectedBranchIds.isNotEmpty) {
      final keys = <String>{};
      for (final branchId in _selectedBranchIds) {
        final branchKeys = await ref.read(branchProductKeysProvider(branchId).future);
        keys.addAll(branchKeys);
      }
      items = items.where((item) {
        final key = '${item.name}|${item.brand}|${item.model}|${item.uom}'.toUpperCase();
        return keys.contains(key);
      }).toList();
    }

    return PaginatedState<AggregatedProduct>(
      items: items,
      hasReachedEnd: items.length < _limit,
      currentOffset: offset,
      isLoadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final nextOffset = current.currentOffset + _limit;
      final newPage = await _fetchPage(nextOffset);

      state = AsyncData(current.copyWith(
        items: [...current.items, ...newPage.items],
        currentOffset: nextOffset,
        hasReachedEnd: newPage.hasReachedEnd,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  void updateSearch(String? query) {
    _query = query;
    refresh();
  }

  void updateFilters(ProductSearchFilters filters) {
    _filters = filters;
    refresh();
  }

  void updateBranchFilter(List<String> branchIds) {
    _selectedBranchIds = branchIds;
    refresh();
  }
}
