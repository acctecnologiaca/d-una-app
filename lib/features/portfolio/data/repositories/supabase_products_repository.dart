import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class SupabaseProductsRepository {
  final SupabaseClient _supabase;

  SupabaseProductsRepository(this._supabase);

  Future<List<Product>> getProducts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      // Using computed columns for inventory_quantity and average_cost
      const selectQuery = '''
      *,
      brands (*),
      categories (*),
      uoms (*),
      inventory_quantity,
      average_cost,
      purchase_count
    ''';
      final response = await _supabase
          .from('products')
          .select(selectQuery)
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<List<Product>> getProductsPaginated({
    required int offset,
    String orderBy = 'created_at',
    bool ascending = false,
    String? searchQuery,
    String? categoryId,
    String? brandId,
    int limit = 25,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      var query = _supabase.from('products').select('''
      *,
      brands (*),
      categories (*),
      uoms (*),
      inventory_quantity,
      average_cost,
      purchase_count
      ''').eq('user_id', userId);

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }
      if (brandId != null && brandId.isNotEmpty) {
        query = query.eq('brand_id', brandId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryClean = searchQuery.trim().toLowerCase();
        query = query.or('name.ilike.%$queryClean%, model.ilike.%$queryClean%');
      }

      final response = await query
          .order(orderBy, ascending: ascending)
          .range(offset, offset + limit - 1);

      return (response as List).map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error fetching paginated products: $e');
    }
  }

  Future<Product?> getProduct(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, categories(*), brands(*), uoms(*)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  Future<void> createProduct(
    Product product, {
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      String? imageUrl = product.imageUrl;

      if (imageBytes != null && imageExtension != null) {
        imageUrl = await _uploadProductImage(
          userId,
          imageBytes,
          imageExtension,
        );
      }

      final productToSave = product.copyWith(
        userId: userId,
        imageUrl: imageUrl,
      );

      // JSON conversion excludes null IDs usually, but for insert we want DB to generate ID.
      // Product.toJson doesn't include ID. Great.
      // But we need to ensure 'user_id' is set. Product.toJson includes it.
      final productJson = productToSave.toJson();
      if (productJson['id'] == '') {
        productJson.remove('id');
      }

      await _supabase.from('products').insert(productJson);
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  Future<void> updateProduct(
    Product product, {
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      String? imageUrl = product.imageUrl;

      if (imageBytes != null && imageExtension != null) {
        imageUrl = await _uploadProductImage(
          userId,
          imageBytes,
          imageExtension,
        );
      }

      final productToSave = product.copyWith(imageUrl: imageUrl);

      await _supabase
          .from('products')
          .update(productToSave.toJson())
          .eq('id', product.id);
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _supabase.from('products').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  Future<String> _uploadProductImage(
    String userId,
    Uint8List bytes,
    String fileExt,
  ) async {
    try {
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_product.$fileExt';

      await _supabase.storage
          .from('product_images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from('product_images').getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Error uploading product image: $e');
    }
  }

  Future<Map<String, dynamic>> fetchProductDetailsFromAI(
    String brand,
    String model,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'autocomplete-product',
        body: {'brand': brand, 'model': model},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      } else {
        throw Exception('Invalid response format from AI');
      }
    } catch (e) {
      throw Exception('Error fetching AI details: $e');
    }
  }
}
