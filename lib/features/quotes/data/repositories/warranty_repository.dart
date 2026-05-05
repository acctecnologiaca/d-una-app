import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WarrantyRepository {
  final SupabaseClient _client;
  WarrantyRepository(this._client);

  /// Fetches the residual warranty for an own product using FIFO logic.
  /// Returns a record with time, unit, and isExpired status.
  Future<({int time, String unit, bool isExpired})?> getResidualWarranty(String productId) async {
    try {
      final response = await _client
          .from('purchase_items')
          .select('warranty_time, warranty_unit, purchases!inner(date)')
          .eq('product_id', productId)
          .order('date', referencedTable: 'purchases', ascending: true) // FIFO
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      
      final warrantyTime = response['warranty_time'] as int?;
      final warrantyUnit = response['warranty_unit'] as String?;
      if (warrantyTime == null || warrantyTime <= 0) return null;

      final purchaseDate = DateTime.parse(response['purchases']['date']);
      final now = DateTime.now();

      // Convert warranty to days for calculation
      final warrantyDays = switch (warrantyUnit) {
        'years' => warrantyTime * 365,
        'months' => warrantyTime * 30,
        _ => warrantyTime, // days
      };

      final elapsedDays = now.difference(purchaseDate).inDays;
      final residualDays = warrantyDays - elapsedDays;

      if (residualDays <= 0) {
        return (time: 0, unit: 'days', isExpired: true);
      }

      // Convert back to the most readable unit, rounding DOWN
      if (residualDays >= 365) {
        return (time: residualDays ~/ 365, unit: 'years', isExpired: false);
      } else if (residualDays >= 30) {
        return (time: residualDays ~/ 30, unit: 'months', isExpired: false);
      } else {
        return (time: residualDays, unit: 'days', isExpired: false);
      }
    } catch (e) {
      return null;
    }
  }

  /// Fetches the warranty from the supplier product catalog.
  Future<({int time, String unit})?> getSupplierWarranty(String supplierBranchStockId) async {
    try {
      final response = await _client
          .from('supplier_branch_stock')
          .select('product_id, supplier_products!inner(warranty_time, warranty_unit)')
          .eq('id', supplierBranchStockId)
          .maybeSingle();

      if (response == null) return null;
      
      final sp = response['supplier_products'];
      if (sp == null) return null;

      final time = sp['warranty_time'] as int?;
      final unit = sp['warranty_unit'] as String?;
      if (time == null || time <= 0) return null;

      return (time: time, unit: unit ?? 'months');
    } catch (e) {
      return null;
    }
  }
}

final warrantyRepositoryProvider = Provider<WarrantyRepository>((ref) {
  return WarrantyRepository(Supabase.instance.client);
});
