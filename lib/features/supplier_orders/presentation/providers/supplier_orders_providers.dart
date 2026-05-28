import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/supplier_orders_repository.dart';
import '../../data/repositories/supabase_supplier_orders_repository.dart';
import '../../domain/models/supplier_order.dart';
import '../../domain/models/supplier_order_item.dart';
import '../../../../shared/models/paginated_state.dart';

part 'supplier_orders_providers.g.dart';

@riverpod
SupplierOrdersRepository supplierOrdersRepository(Ref ref) {
  return SupabaseSupplierOrdersRepository(Supabase.instance.client);
}

@riverpod
class PaginatedSupplierOrders extends _$PaginatedSupplierOrders {
  String? _searchQuery;
  String? _statusFilter;

  @override
  FutureOr<PaginatedState<SupplierOrder>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<SupplierOrder>> _fetchPage(int offset) async {
    final items = await ref.read(supplierOrdersRepositoryProvider).getSupplierOrdersPaginated(
      offset: offset,
      limit: PaginatedState.pageSize,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
    );
    return PaginatedState(
      items: items,
      currentOffset: offset,
      hasReachedEnd: items.length < PaginatedState.pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final newPage = await _fetchPage(current.nextOffset);
      state = AsyncData(current.copyWith(
        items: [...current.items, ...newPage.items],
        currentOffset: newPage.currentOffset,
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
    if (_searchQuery == query) return;
    _searchQuery = query;
    refresh();
  }

  void updateFilters({String? status}) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    refresh();
  }
}

@riverpod
Future<({SupplierOrder order, List<SupplierOrderItem> items})> supplierOrderDetail(
  Ref ref,
  String id,
) {
  return ref.read(supplierOrdersRepositoryProvider).getSupplierOrderDetails(id);
}

@riverpod
Future<List<Map<String, dynamic>>> supplierBranches(Ref ref, String supplierId) async {
  final response = await Supabase.instance.client
      .from('supplier_branches')
      .select('id, name')
      .eq('supplier_id', supplierId);
  return List<Map<String, dynamic>>.from(response);
}
