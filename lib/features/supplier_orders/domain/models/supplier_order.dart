import 'package:equatable/equatable.dart';
import 'supplier_order_status.dart';

class SupplierOrder extends Equatable {
  final String id;
  final String userId;
  final String supplierId;
  final String? supplierBranchId;
  final String? shippingMethodId;
  final String? receiverCollaboratorId;
  final String orderNumber;
  final DateTime date;
  final String? paymentMethod;
  final SupplierOrderStatus status;
  final double subtotal;
  final double tax;
  final double total;
  final String? invoicePhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields for UI rendering
  final String supplierName;
  final String? branchName;
  final String? shippingMethodLabel;
  final String? receiverName;

  const SupplierOrder({
    required this.id,
    required this.userId,
    required this.supplierId,
    this.supplierBranchId,
    this.shippingMethodId,
    this.receiverCollaboratorId,
    required this.orderNumber,
    required this.date,
    this.paymentMethod,
    required this.status,
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.total = 0.0,
    this.invoicePhotoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.supplierName = 'Desconocido',
    this.branchName,
    this.shippingMethodLabel,
    this.receiverName,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    supplierId,
    supplierBranchId,
    shippingMethodId,
    receiverCollaboratorId,
    orderNumber,
    date,
    paymentMethod,
    status,
    subtotal,
    tax,
    total,
    invoicePhotoUrl,
    createdAt,
    updatedAt,
    supplierName,
    branchName,
    shippingMethodLabel,
    receiverName,
  ];
}
