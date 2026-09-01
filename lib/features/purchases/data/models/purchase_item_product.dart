import 'package:equatable/equatable.dart';

class PurchaseItemProduct extends Equatable {
  final String id;
  final String productId;
  final String name;
  final String? brand;
  final String? model;
  final String uom;

  final double quantity;
  final double unitPrice;
  final int? warrantyTime;
  final String? warrantyUnit; // 'days', 'months', 'years'
  final bool requiresSerials;

  const PurchaseItemProduct({
    required this.id,
    required this.productId,
    required this.name,
    this.brand,
    this.model,
    required this.uom,
    required this.quantity,
    required this.unitPrice,
    this.warrantyTime,
    this.warrantyUnit,
    this.requiresSerials = false,
  });

  double get subtotal => quantity * unitPrice;

  @override
  List<Object?> get props => [
    id,
    productId,
    name,
    brand,
    model,
    uom,
    quantity,
    unitPrice,
    warrantyTime,
    warrantyUnit,
    requiresSerials,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'brand': brand,
      'model': model,
      'uom': uom,
      'quantity': quantity,
      'unit_price': unitPrice,
      'warranty_time': warrantyTime,
      'warranty_unit': warrantyUnit,
      'requires_serials': requiresSerials,
    };
  }

  factory PurchaseItemProduct.fromJson(Map<String, dynamic> json) {
    return PurchaseItemProduct(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      uom: json['uom'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      warrantyTime: (json['warranty_time'] as num?)?.toInt(),
      warrantyUnit: json['warranty_unit'] as String?,
      requiresSerials: json['requires_serials'] as bool? ?? false,
    );
  }

  PurchaseItemProduct copyWith({
    double? quantity,
    double? unitPrice,
    int? warrantyTime,
    String? warrantyUnit,
    bool? requiresSerials,
  }) {
    return PurchaseItemProduct(
      id: id,
      productId: productId,
      name: name,
      brand: brand,
      model: model,
      uom: uom,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      warrantyTime: warrantyTime ?? this.warrantyTime,
      warrantyUnit: warrantyUnit ?? this.warrantyUnit,
      requiresSerials: requiresSerials ?? this.requiresSerials,
    );
  }
}
