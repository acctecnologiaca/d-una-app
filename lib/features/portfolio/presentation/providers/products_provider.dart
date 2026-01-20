import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_products_repository.dart';
import '../../data/models/product_model.dart';

final productsRepositoryProvider = Provider<SupabaseProductsRepository>((ref) {
  return SupabaseProductsRepository(Supabase.instance.client);
});

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(
  () {
    return ProductsNotifier();
  },
);

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  FutureOr<List<Product>> build() async {
    return ref.read(productsRepositoryProvider).getProducts();
  }

  Future<void> createProduct(
    Product product, {
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(productsRepositoryProvider)
          .createProduct(
            product,
            imageBytes: imageBytes,
            imageExtension: imageExtension,
          );
      return ref.read(productsRepositoryProvider).getProducts();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> updateProduct(
    Product product, {
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(productsRepositoryProvider)
          .updateProduct(
            product,
            imageBytes: imageBytes,
            imageExtension: imageExtension,
          );
      return ref.read(productsRepositoryProvider).getProducts();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> deleteProduct(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(productsRepositoryProvider).deleteProduct(id);
      return ref.read(productsRepositoryProvider).getProducts();
    });
  }
}
