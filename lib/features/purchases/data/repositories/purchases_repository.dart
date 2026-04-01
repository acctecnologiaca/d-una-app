import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/models.dart';
import '../models/purchase_item_product.dart';

class PurchasesRepository {
  final SupabaseClient _supabase;

  PurchasesRepository(this._supabase);

  Future<List<Purchase>> getPurchases({String? productId}) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    var query = _supabase
        .from('purchases')
        .select('''
          *,
          suppliers(name, legal_name)${productId != null ? ', purchase_items!inner(product_id)' : ''}
        ''');
    
    query = query.eq('user_id', currentUserId);

    if (productId != null) {
      query = query.eq('purchase_items.product_id', productId);
    }

    final response = await query
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

      await _supabase.from('purchase_items').insert(itemsToInsert);

      // 3. Insert Serials (they already have the correct purchase_item_id from the draft)
      if (serials.isNotEmpty) {
        final serialsToInsert = serials.map((s) => s.toJson()).toList();
        await _supabase.from('product_serials').insert(serialsToInsert);
      }
    }
  }

  Future<void> updatePurchase(
     Purchase purchase,
     List<PurchaseItem> items,
     List<ProductSerial> serials,
  ) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    // 1. Update Purchase Header
    final headerJson = purchase.toJson();
    headerJson.remove('id'); // Don't try to update the ID
    headerJson.remove('user_id'); // Don't try to update the user_id
    
    await _supabase.from('purchases').update(headerJson).eq('id', purchase.id);

    // 2. Delete existing items and serials to replace them cleanly
    // Deleting items should cascade to serials in a proper DB schema, but let's be explicit just in case.
    await _supabase.from('purchase_items').delete().eq('purchase_id', purchase.id);

    // 3. Insert new items and serials
    if (items.isNotEmpty) {
      final itemsToInsert = items.map((item) {
        final json = item.toJson();
        json['purchase_id'] = purchase.id;
        return json;
      }).toList();

      await _supabase.from('purchase_items').insert(itemsToInsert);

      // 4. Insert Serials
      if (serials.isNotEmpty) {
        final serialsToInsert = serials.map((s) => s.toJson()).toList();
        await _supabase.from('product_serials').insert(serialsToInsert);
      }
    }
  }

  Future<({Purchase purchase, List<PurchaseItemProduct> items, List<ProductSerial> serials, String? supplierTaxId})> getPurchaseDetails(String purchaseId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    // 1. Fetch the purchase header
    final headerResponse = await _supabase
        .from('purchases')
        .select('''
          *,
          suppliers(name, legal_name, tax_id)
        ''')
        .eq('id', purchaseId)
        .eq('user_id', currentUserId)
        .single();
    
    String? supplierName;
    String? supplierTaxId;
    if (headerResponse['suppliers'] != null) {
      final supplier = headerResponse['suppliers'] as Map<String, dynamic>;
      supplierName = (supplier['legal_name'] as String?) ?? (supplier['name'] as String?);
      supplierTaxId = supplier['tax_id'] as String?;
    }
    
    final purchaseMap = Map<String, dynamic>.from(headerResponse);
    purchaseMap['supplier_name'] = supplierName ?? 'Desconocido';
    final purchase = Purchase.fromJson(purchaseMap);

    // 2. Fetch items with product details
    final itemsResponse = await _supabase
        .from('purchase_items')
        .select('''
          *,
          products(name, model, brands(name), uoms(symbol))
        ''')
        .eq('purchase_id', purchaseId);

    final items = (itemsResponse as List<dynamic>).map((json) {
      final itemMap = Map<String, dynamic>.from(json);
      final productMap = itemMap['products'] as Map<String, dynamic>?;
      final brandMap = productMap?['brands'] as Map<String, dynamic>?;
      final uomMap = productMap?['uoms'] as Map<String, dynamic>?;
      
      return PurchaseItemProduct(
        id: itemMap['id'] as String,
        productId: itemMap['product_id'] as String,
        name: productMap?['name'] as String? ?? 'Desconocido',
        brand: brandMap?['name'] as String?,
        model: productMap?['model'] as String?,
        uom: uomMap?['symbol'] as String? ?? 'Ud',
        quantity: (itemMap['quantity'] as num?)?.toDouble() ?? 0.0,
        unitPrice: (itemMap['unit_price'] as num?)?.toDouble() ?? 0.0,
        warrantyTime: itemMap['warranty_time'] as int?,
        warrantyUnit: itemMap['warranty_unit'] as String?,
        requiresSerials: itemMap['requires_serials'] as bool? ?? false,
      );
    }).toList();

    // 3. Fetch serials
    final itemIds = items.map((i) => i.id).toList();
    List<ProductSerial> serials = [];
    if (itemIds.isNotEmpty) {
      final serialsResponse = await _supabase
          .from('product_serials')
          .select()
          .inFilter('purchase_item_id', itemIds);
      
      serials = (serialsResponse as List<dynamic>)
          .map((json) => ProductSerial.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return (
      purchase: purchase,
      items: items,
      serials: serials,
      supplierTaxId: supplierTaxId,
    );
  }

  Future<void> deletePurchase(String id) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    await _supabase
        .from('purchases')
        .delete()
        .eq('id', id)
        .eq('user_id', currentUserId);
  }
}
