import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/supplier_model.dart';

class SuppliersRepository {
  final SupabaseClient _supabase;

  SuppliersRepository(this._supabase);

  Future<List<Supplier>> getSuppliers({
    required List<String> occupationIds,
  }) async {
    if (occupationIds.isEmpty) return [];

    try {
      // Use the RPC to get suppliers based on occupation -> sector -> supplier
      final response = await _supabase.rpc(
        'get_relevant_suppliers_by_id',
        params: {'occupation_ids': occupationIds},
      );

      final data = response as List<dynamic>;
      return data.map((json) => Supplier.fromJson(json)).toList();
    } catch (e) {
      // Handle error gracefully or rethrow
      // print('Error fetching suppliers via RPC: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchAggregatedProducts(
    String query, {
    List<String>? brands,
    List<String>? categories,
    List<String>? supplierIds,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final response = await _supabase.rpc(
        'search_supplier_products',
        params: {
          'query_text': query,
          // ... filters remain same but RPC now queries product_stock
          'brand_filter': brands?.isNotEmpty == true ? brands : null,
          'category_filter': categories?.isNotEmpty == true ? categories : null,
          'supplier_filter': supplierIds?.isNotEmpty == true
              ? supplierIds
              : null,
          'min_price_filter': minPrice,
          'max_price_filter': maxPrice,
        },
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProductSuppliers({
    required String name,
    required String brand,
    required String model,
    required String uom,
    List<String>? supplierIds,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_product_suppliers',
        params: {
          'p_name': name,
          'p_brand': brand,
          'p_model': model,
          'p_uom': uom,
          'p_supplier_ids': supplierIds?.isNotEmpty == true
              ? supplierIds
              : null,
          'p_min_price': minPrice,
          'p_max_price': maxPrice,
        },
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching product suppliers: $e');
    }
  }
}
