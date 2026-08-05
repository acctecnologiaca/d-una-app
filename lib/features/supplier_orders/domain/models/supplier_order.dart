import 'package:equatable/equatable.dart';
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart' show StockStatus;
import 'supplier_order_status.dart';
import 'supplier_order_item.dart';

class SupplierOrder extends Equatable {
  final String id;
  final String userId;
  final String supplierId;
  final String? supplierBranchId;
  final String? shippingMethodId;
  final String? receiverCollaboratorId;
  final String? quoteId;
  final String? parentOrderId;
  final String orderNumber;
  final DateTime date;
  final String? paymentMethod;
  final SupplierOrderStatus status;
  final double subtotal;
  final double tax;
  final double total;
  final String? invoicePhotoUrl;
  final bool isArchived;
  final String verificationStatus; // 'pending_review' | 'approved' | 'rejected'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields for UI rendering
  final String supplierName;
  final String? branchName;
  final String? shippingMethodLabel;
  final String? receiverName;
  final List<SupplierOrderItem>? items;

  // Live stock & price alert validation fields
  final StockStatus stockStatus;
  final bool hasPriceIncrease;

  const SupplierOrder({
    required this.id,
    required this.userId,
    required this.supplierId,
    this.supplierBranchId,
    this.shippingMethodId,
    this.receiverCollaboratorId,
    this.quoteId,
    this.parentOrderId,
    required this.orderNumber,
    required this.date,
    this.paymentMethod,
    required this.status,
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.total = 0.0,
    this.invoicePhotoUrl,
    this.isArchived = false,
    this.verificationStatus = 'pending_review',
    required this.createdAt,
    required this.updatedAt,
    this.supplierName = 'Desconocido',
    this.branchName,
    this.shippingMethodLabel,
    this.receiverName,
    this.items,
    this.stockStatus = StockStatus.available,
    this.hasPriceIncrease = false,
  });

  bool get canShowAlerts =>
      status != SupplierOrderStatus.finalized &&
      status != SupplierOrderStatus.cancelled;

  String get shortOrderNumber {
    final parts = orderNumber.split('-');
    if (parts.length >= 3) {
      return parts.last;
    }
    return orderNumber;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    supplierId,
    supplierBranchId,
    shippingMethodId,
    receiverCollaboratorId,
    quoteId,
    parentOrderId,
    orderNumber,
    date,
    paymentMethod,
    status,
    subtotal,
    tax,
    total,
    invoicePhotoUrl,
    isArchived,
    verificationStatus,
    createdAt,
    updatedAt,
    supplierName,
    branchName,
    shippingMethodLabel,
    receiverName,
    items,
    stockStatus,
    hasPriceIncrease,
  ];
}
