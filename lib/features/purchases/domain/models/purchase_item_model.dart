import 'package:equatable/equatable.dart';

class PurchaseItem extends Equatable {
  final String id;
  final String purchaseId;
  final String productId;
  final double quantity;
  final double unitPrice;
  final int? warrantyTime;
  final String? warrantyUnit; // 'days', 'months', 'years'
  final bool requiresSerials;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.warrantyTime,
    this.warrantyUnit,
    this.requiresSerials = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'],
      purchaseId: json['purchase_id'],
      productId: json['product_id'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      warrantyTime: json['warranty_time'],
      warrantyUnit: json['warranty_unit'],
      requiresSerials: json['requires_serials'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'warranty_time': warrantyTime,
      'warranty_unit': warrantyUnit,
      'requires_serials': requiresSerials,
    };
  }

  @override
  List<Object?> get props => [
    id,
    purchaseId,
    productId,
    quantity,
    unitPrice,
    warrantyTime,
    warrantyUnit,
    requiresSerials,
    createdAt,
    updatedAt,
  ];
}
