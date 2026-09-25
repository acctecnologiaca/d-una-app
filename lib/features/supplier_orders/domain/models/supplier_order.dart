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
  final String? parentOrderNumber;
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
  final String? supplierFeedback;
  final DateTime? supplierFeedbackAt;
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
  // Dropshipping & Recipient fields
  final bool isDropshipping;
  final String? clientId;
  final String? recipientName;
  final String? recipientContactName;
  final String? recipientAddress;
  final String? recipientPhone;
  final String? deliveryInstructions;

  const SupplierOrder({
    required this.id,
    required this.userId,
    required this.supplierId,
    this.supplierBranchId,
    this.shippingMethodId,
    this.receiverCollaboratorId,
    this.quoteId,
    this.parentOrderId,
    this.parentOrderNumber,
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
    this.supplierFeedback,
    this.supplierFeedbackAt,
    required this.createdAt,
    required this.updatedAt,
    this.supplierName = 'Desconocido',
    this.branchName,
    this.shippingMethodLabel,
    this.receiverName,
    this.items,
    this.stockStatus = StockStatus.available,
    this.hasPriceIncrease = false,
    this.isDropshipping = false,
    this.clientId,
    this.recipientName,
    this.recipientContactName,
    this.recipientAddress,
    this.recipientPhone,
    this.deliveryInstructions,
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

  String? get shortParentOrderNumber {
    if (parentOrderNumber == null || parentOrderNumber!.isEmpty) return null;
    final parts = parentOrderNumber!.split('-');
    if (parts.length >= 3) {
      return '#${parts.last}';
    }
    return parentOrderNumber;
  }

  SupplierOrder copyWith({
    String? id,
    String? userId,
    String? supplierId,
    String? supplierBranchId,
    String? shippingMethodId,
    String? receiverCollaboratorId,
    String? quoteId,
    String? parentOrderId,
    String? parentOrderNumber,
    String? orderNumber,
    DateTime? date,
    String? paymentMethod,
    SupplierOrderStatus? status,
    double? subtotal,
    double? tax,
    double? total,
    String? invoicePhotoUrl,
    bool? isArchived,
    String? verificationStatus,
    String? supplierFeedback,
    DateTime? supplierFeedbackAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? supplierName,
    String? branchName,
    String? shippingMethodLabel,
    String? receiverName,
    List<SupplierOrderItem>? items,
    StockStatus? stockStatus,
    bool? hasPriceIncrease,
    bool? isDropshipping,
    String? clientId,
    String? recipientName,
    String? recipientContactName,
    String? recipientAddress,
    String? recipientPhone,
    String? deliveryInstructions,
  }) {
    return SupplierOrder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      supplierId: supplierId ?? this.supplierId,
      supplierBranchId: supplierBranchId ?? this.supplierBranchId,
      shippingMethodId: shippingMethodId ?? this.shippingMethodId,
      receiverCollaboratorId: receiverCollaboratorId ?? this.receiverCollaboratorId,
      quoteId: quoteId ?? this.quoteId,
      parentOrderId: parentOrderId ?? this.parentOrderId,
      parentOrderNumber: parentOrderNumber ?? this.parentOrderNumber,
      orderNumber: orderNumber ?? this.orderNumber,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      invoicePhotoUrl: invoicePhotoUrl ?? this.invoicePhotoUrl,
      isArchived: isArchived ?? this.isArchived,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      supplierFeedback: supplierFeedback ?? this.supplierFeedback,
      supplierFeedbackAt: supplierFeedbackAt ?? this.supplierFeedbackAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      supplierName: supplierName ?? this.supplierName,
      branchName: branchName ?? this.branchName,
      shippingMethodLabel: shippingMethodLabel ?? this.shippingMethodLabel,
      receiverName: receiverName ?? this.receiverName,
      items: items ?? this.items,
      stockStatus: stockStatus ?? this.stockStatus,
      hasPriceIncrease: hasPriceIncrease ?? this.hasPriceIncrease,
      isDropshipping: isDropshipping ?? this.isDropshipping,
      clientId: clientId ?? this.clientId,
      recipientName: recipientName ?? this.recipientName,
      recipientContactName: recipientContactName ?? this.recipientContactName,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
    );
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
    parentOrderNumber,
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
    supplierFeedback,
    supplierFeedbackAt,
    createdAt,
    updatedAt,
    supplierName,
    branchName,
    shippingMethodLabel,
    receiverName,
    items,
    stockStatus,
    hasPriceIncrease,
    isDropshipping,
    clientId,
    recipientName,
    recipientContactName,
    recipientAddress,
    recipientPhone,
    deliveryInstructions,
  ];
}
