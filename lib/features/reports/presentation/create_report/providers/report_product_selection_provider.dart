import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../portfolio/data/models/product_model.dart';
import '../../../../portfolio/presentation/providers/products_provider.dart';

final reportOwnProductSuggestionsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final repo = ref.watch(productsRepositoryProvider);
  return repo.getProducts();
});
