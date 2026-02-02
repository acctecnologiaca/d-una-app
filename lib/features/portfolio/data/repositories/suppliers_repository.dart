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
    String query,
  ) async {
    try {
      final response = await _supabase.rpc(
        'search_supplier_products',
        params: {'query_text': query},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }
}
