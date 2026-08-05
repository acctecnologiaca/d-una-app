import 'package:equatable/equatable.dart';

class Purchase extends Equatable {
  final String id;
  final String userId;
  final String? supplierId;
  final String? supplierOrderId;
  final String documentType; // 'invoice' | 'delivery_note'
  final String documentNumber;
  final DateTime date;
  final double subtotal;
  final double tax;
  final double total;
  final bool hasMissingSerials;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Derived field for UI
  final String? supplierName;
  final String? invoicePhotoUrl;
  final String? verificationStatus;

  const Purchase({
    required this.id,
    required this.userId,
    this.supplierId,
    this.supplierOrderId,
    required this.documentType,
    required this.documentNumber,
    required this.date,
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.total = 0.0,
    this.hasMissingSerials = false,
    required this.createdAt,
    required this.updatedAt,
    this.supplierName,
    this.invoicePhotoUrl,
    this.verificationStatus,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      userId: json['user_id'],
      supplierId: json['supplier_id'],
      supplierOrderId: json['supplier_order_id'],
      documentType: json['document_type'],
      documentNumber: json['document_number'],
      date: DateTime.parse(json['date']),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      hasMissingSerials: json['has_missing_serials'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      supplierName: json['supplier_name'],
      invoicePhotoUrl: json['invoice_photo_url'],
      verificationStatus: json['verification_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'supplier_id': supplierId,
      'supplier_order_id': supplierOrderId,
      'document_type': documentType,
      'document_number': documentNumber,
      'date': date.toIso8601String().split('T')[0],
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'has_missing_serials': hasMissingSerials,
      'invoice_photo_url': invoicePhotoUrl,
      'verification_status': verificationStatus,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    supplierId,
    supplierOrderId,
    documentType,
    documentNumber,
    date,
    subtotal,
    tax,
    total,
    hasMissingSerials,
    createdAt,
    updatedAt,
    supplierName,
    invoicePhotoUrl,
    verificationStatus,
  ];
}
