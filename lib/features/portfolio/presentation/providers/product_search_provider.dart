import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/aggregated_product.dart';
import 'suppliers_provider.dart';

part 'product_search_provider.g.dart';

@riverpod
Future<List<AggregatedProduct>> productSearch(Ref ref, String query) async {
  if (query.isEmpty) return [];

  final repository = ref.watch(suppliersRepositoryProvider);
  final result = await repository.searchAggregatedProducts(query);

  return result.map((json) => AggregatedProduct.fromJson(json)).toList();
}
