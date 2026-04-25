import 'package:equatable/equatable.dart';

class ProductSerial extends Equatable {
  final String id;
  final String purchaseItemId;
  final String productId;
  final String serialNumber;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductSerial({
    required this.id,
    required this.purchaseItemId,
    required this.productId,
    required this.serialNumber,
    this.status = 'in_stock',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductSerial.fromJson(Map<String, dynamic> json) {
    return ProductSerial(
      id: json['id'],
      purchaseItemId: json['purchase_item_id'],
      productId: json['product_id'],
      serialNumber: json['serial_number'],
      status: json['status'] ?? 'in_stock',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchase_item_id': purchaseItemId,
      'product_id': productId,
      'serial_number': serialNumber,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
    id,
    purchaseItemId,
    productId,
    serialNumber,
    status,
    createdAt,
    updatedAt,
  ];
}
