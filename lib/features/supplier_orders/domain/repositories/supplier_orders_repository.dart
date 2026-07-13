import 'dart:io';
import '../models/supplier_order.dart';
import '../models/supplier_order_item.dart';

abstract class SupplierOrdersRepository {
  Future<List<SupplierOrder>> getSupplierOrders();
  Future<List<SupplierOrder>> getSupplierOrdersPaginated({
    required int offset,
    int limit = 25,
    String? searchQuery,
    String? statusFilter,
    bool includeArchived = false,
  });
  Future<({SupplierOrder order, List<SupplierOrderItem> items})> getSupplierOrderDetails(String id);
  Future<String> createSupplierOrder(SupplierOrder order, List<SupplierOrderItem> items);
  Future<void> updateSupplierOrder(SupplierOrder order, List<SupplierOrderItem> items);
  Future<void> deleteSupplierOrder(String id);
  
  // Transition status to finalized (requires photo upload + optional purchase record insertion)
  Future<void> finalizeSupplierOrder({
    required String orderId,
    required File photoFile,
    required String documentType, // 'invoice' or 'delivery_note'
    required bool createPurchaseRecord,
  });

  // Batch generation from quote. Returns map with 'generatedCount' and 'skippedSuppliers'
  Future<Map<String, dynamic>> batchGenerateFromQuote(String quoteId);

  /// Returns the last order number for the current user, or null if none.
  Future<String?> getLastOrderNumber();

  Future<void> archiveSupplierOrder(String id, bool isArchived);
  Future<void> updateSupplierOrderStatus(String id, String status);
}
