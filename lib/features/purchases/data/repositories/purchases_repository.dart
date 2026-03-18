import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/models.dart';

class PurchasesRepository {
  final SupabaseClient _supabase;

  PurchasesRepository(this._supabase);

  Future<List<Purchase>> getPurchases() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('purchases')
        .select('''
          *,
          suppliers(name, legal_name)
        ''')
        .eq('user_id', currentUserId)
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((json) {
      String? supplierName;
      if (json['suppliers'] != null) {
        final supplier = json['suppliers'] as Map<String, dynamic>;
        supplierName = (supplier['legal_name'] as String?) ?? (supplier['name'] as String?);
      }
      
      json['supplier_name'] = supplierName ?? 'Desconocido';
      return Purchase.fromJson(json as Map<String, dynamic>);
    }).toList();
  }

  Future<void> createPurchase(
     Purchase purchase,
     List<PurchaseItem> items,
     List<ProductSerial> serials,
  ) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    // 1. Insert Purchase Header
    final headerResponse = await _supabase.from('purchases').insert({
       ...purchase.toJson(),
       'user_id': currentUserId,
    }).select('id').single();

    final purchaseId = headerResponse['id'] as String;

    // 2. Insert Purchase Items
    if (items.isNotEmpty) {
      final itemsToInsert = items.map((item) {
        final json = item.toJson();
        json['purchase_id'] = purchaseId;
        return json;
      }).toList();

      final itemsResponse = await _supabase
          .from('purchase_items')
          .insert(itemsToInsert)
          .select('id, product_id');

      // 3. Map the returned item IDs back to the product_id to correctly set purchase_item_id on serials
      final itemMap = {
        for (var row in itemsResponse) (row['product_id'] as String): (row['id'] as String)
      };

      if (serials.isNotEmpty) {
        final serialsToInsert = serials.map((s) {
           final json = s.toJson();
           // Find the correct purchase_item_id based on the product_id of the serial
           json['purchase_item_id'] = itemMap[s.productId];
           return json;
        }).toList();

        await _supabase.from('product_serials').insert(serialsToInsert);
      }
    }
  }
}
