import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/aggregated_product.dart';
import '../../../quotes/domain/models/quote_aggregated_product.dart';
import 'suppliers_provider.dart';
import 'package:equatable/equatable.dart';

import '../../domain/models/product_search_filters.dart';
import '../../../../shared/models/paginated_state.dart';

part 'product_search_provider.g.dart';

class ProductSearchParams extends Equatable {
  final String query;
  final ProductSearchFilters filters;

  const ProductSearchParams({
    required this.query,
    this.filters = const ProductSearchFilters(),
  });

  @override
  List<Object?> get props => [query, filters];
}

@riverpod
class PaginatedQuoteProductSearch extends _$PaginatedQuoteProductSearch {
  static const int _limit = 25;
  String? _query;
  ProductSearchFilters _filters = const ProductSearchFilters();

  @override
  FutureOr<PaginatedState<QuoteAggregatedProduct>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<QuoteAggregatedProduct>> _fetchPage(int offset) async {
    final queryText = _query ?? '';
    
    // We can't paginate if everything is empty and no query, return empty.
    if (queryText.isEmpty &&
        _filters.brands.isEmpty &&
        _filters.categories.isEmpty &&
        _filters.supplierIds.isEmpty &&
        _filters.minPrice == null &&
        _filters.maxPrice == null) {
      return PaginatedState<QuoteAggregatedProduct>(
        items: [],
        hasReachedEnd: true,
        currentOffset: offset,
        isLoadingMore: false,
      );
    }

    final repository = ref.read(suppliersRepositoryProvider);
    final result = await repository.searchAggregatedProducts(
      queryText,
      brands: _filters.brands,
      categories: _filters.categories,
      supplierIds: _filters.supplierIds,
      minPrice: _filters.minPrice,
      maxPrice: _filters.maxPrice,
      offset: offset,
      limit: _limit,
    );

    final items = result.map((json) => QuoteAggregatedProduct.fromMap(json)).toList();

    return PaginatedState<QuoteAggregatedProduct>(
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
}


@riverpod
Future<List<AggregatedProduct>> productSearch(
  Ref ref,
  ProductSearchParams params,
) async {
  if (params.query.isEmpty &&
      params.filters.brands.isEmpty &&
      params.filters.categories.isEmpty &&
      params.filters.supplierIds.isEmpty &&
      params.filters.minPrice == null &&
      params.filters.maxPrice == null) {
    return [];
  }

  final repository = ref.watch(suppliersRepositoryProvider);
  final result = await repository.searchAggregatedProducts(
    params.query,
    brands: params.filters.brands,
    categories: params.filters.categories,
    supplierIds: params.filters.supplierIds,
    minPrice: params.filters.minPrice,
    maxPrice: params.filters.maxPrice,
  // Added offset and limit for pagination compatibility, ignoring in unpaginated version for now
  );

  return result.map((json) => AggregatedProduct.fromJson(json)).toList();
}
