import '../../domain/models/supplier_order.dart';
import '../../domain/models/supplier_order_item.dart';
import '../../domain/models/supplier_order_status.dart';

class SupplierOrderDto {
  static SupplierOrder fromJson(Map<String, dynamic> json) {
    String? supplierName;
    if (json['suppliers'] != null) {
      supplierName = json['suppliers']['legal_name'] as String? ?? json['suppliers']['name'] as String?;
    }
    String? branchName = json['supplier_branches']?['name'] as String?;
    String? shippingLabel = json['shipping_methods']?['label'] as String?;
    String? receiverName = json['collaborators']?['full_name'] as String?;

    List<SupplierOrderItem>? items;
    if (json['supplier_order_items'] != null && json['supplier_order_items'] is List) {
      items = (json['supplier_order_items'] as List).map((i) {
        final branchStock = i['supplier_branch_stock'] as Map<String, dynamic>?;
        final branch = branchStock?['supplier_branches'] as Map<String, dynamic>?;
        final itemBranchName = branch?['name'] as String?;

        return SupplierOrderItem(
          id: i['id'],
          supplierOrderId: i['supplier_order_id'],
          productId: i['product_id'],
          name: i['name'],
          brand: i['brand'],
          model: i['model'],
          uom: i['uom'] ?? 'Ud',
          uomIconName: i['uom_icon_name'],
          quantity: (i['quantity'] ?? 0.0).toDouble(),
          unitPrice: (i['unit_price'] ?? 0.0).toDouble(),
          supplierBranchStockId: i['supplier_branch_stock_id'],
          branchName: itemBranchName,
        );
      }).toList();
    }

    return SupplierOrder(
      id: json['id'],
      userId: json['user_id'],
      supplierId: json['supplier_id'],
      supplierBranchId: json['supplier_branch_id'],
      shippingMethodId: json['shipping_method_id'],
      receiverCollaboratorId: json['receiver_collaborator_id'],
      orderNumber: json['order_number'] ?? 'S/N',
      date: DateTime.parse(json['date']),
      paymentMethod: json['payment_method'],
      status: SupplierOrderStatus.fromDbValue(json['status'] ?? 'draft'),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      invoicePhotoUrl: json['invoice_photo_url'],
      isArchived: json['is_archived'] as bool? ?? false,
      verificationStatus: json['verification_status'] as String? ?? 'pending_review',
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
      supplierName: supplierName ?? 'Desconocido',
      branchName: branchName,
      shippingMethodLabel: shippingLabel,
      receiverName: receiverName,
      items: items,
    );
  }

  static Map<String, dynamic> toJson(SupplierOrder order) {
    return {
      'supplier_id': order.supplierId,
      'supplier_branch_id': order.supplierBranchId,
      'shipping_method_id': order.shippingMethodId,
      'receiver_collaborator_id': order.receiverCollaboratorId,
      'date': order.date.toIso8601String().split('T')[0],
      'payment_method': order.paymentMethod,
      'status': order.status.dbValue,
      'subtotal': order.subtotal,
      'tax': order.tax,
      'total': order.total,
      'invoice_photo_url': order.invoicePhotoUrl,
      'is_archived': order.isArchived,
      'verification_status': order.verificationStatus,
      'order_number': order.orderNumber,
    };
  }
}
