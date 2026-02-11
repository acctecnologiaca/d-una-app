import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/aggregated_product.dart';
import 'suppliers_provider.dart';

import 'package:equatable/equatable.dart';
import '../../domain/models/product_search_filters.dart';

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
  );

  return result.map((json) => AggregatedProduct.fromJson(json)).toList();
}
