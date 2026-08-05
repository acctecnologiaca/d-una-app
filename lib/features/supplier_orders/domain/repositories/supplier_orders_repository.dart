import 'dart:io';
import '../models/supplier_order.dart';
import '../models/supplier_order_item.dart';
import '../models/quote_supplier_oc_status.dart';

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
  
  Future<String?> finalizeSupplierOrder({
    required String orderId,
    required File photoFile,
    required String documentType, // 'invoice' or 'delivery_note'
    required String documentNumber,
    required bool createPurchaseRecord,
  });

  // Batch generation from quote. Returns map with 'generatedCount' and 'skippedSuppliers'
  Future<Map<String, dynamic>> batchGenerateFromQuote(
    String quoteId, {
    List<String>? selectedSupplierIds,
  });

  Future<List<QuoteSupplierOcStatus>> getQuoteSuppliersOcStatus(String quoteId);

  Future<List<SupplierOrder>> getSupplierOrdersByQuoteId(String quoteId);
  Future<void> cancelDraftOrdersByQuoteId(String quoteId);

  /// Returns the last order number for the current user, or null if none.
  Future<String?> getLastOrderNumber();

  /// Consolidates multiple supplier orders from the same supplier into one primary order.
  Future<SupplierOrder> mergeSupplierOrders(List<String> orderIds);

  /// Returns secondary orders that were merged into the specified parent order ID.
  Future<List<SupplierOrder>> getMergedChildOrders(String parentOrderId);

  /// Returns parent order for a merged child order by parent order ID.
  Future<SupplierOrder?> getParentSupplierOrder(String parentOrderId);

  /// Unmerges a consolidated child order and restores it to draft status.
  Future<void> unmergeSupplierOrder(String childOrderId);

  /// Batch unmerges a list of consolidated child orders.
  Future<void> batchUnmergeSupplierOrders(List<String> childOrderIds);

  Future<void> archiveSupplierOrder(String id, bool isArchived);
  Future<void> updateSupplierOrderStatus(String id, String status);

  Future<Map<String, ({double price, double quantity})>> validateSupplierOrderItems({
    required List<String> stockIds,
  });

  Future<String> generateActionToken(String orderId);

  Future<Map<String, dynamic>?> getLinkedPurchase(String supplierOrderId);
  Future<String> createPurchaseFromOrder(String orderId);
}


