import 'delivery_note_serial_model.dart';

class DeliveryNoteItemModel {
  final String id;
  final String deliveryNoteId;
  final String? productId;
  final String name;
  final String? brand;
  final String? model;
  final String uom;
  final String? description;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double taxAmount;
  final double totalPrice;
  final int orderIndex;
  final int? warrantyTime;
  final String? warrantyUnit;
  final String sourceType; // 'own', 'affiliated', 'external', 'temporal'
  final bool requiresSerials;
  final bool isDropshipping;
  final List<DeliveryNoteSerialModel> serials;

  const DeliveryNoteItemModel({
    required this.id,
    required this.deliveryNoteId,
    this.productId,
    required this.name,
    this.brand,
    this.model,
    this.uom = 'Ud',
    this.description,
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.totalPrice = 0.0,
    this.orderIndex = 0,
    this.warrantyTime,
    this.warrantyUnit = 'months',
    this.sourceType = 'own',
    this.requiresSerials = false,
    this.isDropshipping = false,
    this.serials = const [],
  });

  int get missingSerialsCount {
    if (!requiresSerials || isDropshipping) return 0;
    final needed = quantity.round();
    final current = serials.length;
    return (needed - current).clamp(0, 99999);
  }

  bool get hasMissingSerials => missingSerialsCount > 0;

  factory DeliveryNoteItemModel.fromJson(Map<String, dynamic> json) {
    final rawSerials = json['delivery_note_serials'] as List<dynamic>? ?? [];
    final serialsList = rawSerials
        .map((s) => DeliveryNoteSerialModel.fromJson(s as Map<String, dynamic>))
        .toList();

    return DeliveryNoteItemModel(
      id: json['id'] as String,
      deliveryNoteId: json['delivery_note_id'] as String? ?? '',
      productId: json['product_id'] as String?,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      uom: json['uom'] as String? ?? 'Ud',
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      warrantyTime: (json['warranty_time'] as num?)?.toInt(),
      warrantyUnit: json['warranty_unit'] as String? ?? 'months',
      sourceType: json['source_type'] as String? ?? 'own',
      requiresSerials: json['requires_serials'] == true,
      isDropshipping: json['is_dropshipping'] == true,
      serials: serialsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_note_id': deliveryNoteId,
      if (productId != null) 'product_id': productId,
      'name': name,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      'uom': uom,
      if (description != null) 'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_price': totalPrice,
      'order_index': orderIndex,
      if (warrantyTime != null) 'warranty_time': warrantyTime,
      if (warrantyUnit != null) 'warranty_unit': warrantyUnit,
      'source_type': sourceType,
      'requires_serials': requiresSerials,
      'is_dropshipping': isDropshipping,
    };
  }

  DeliveryNoteItemModel copyWith({
    String? id,
    String? deliveryNoteId,
    String? productId,
    String? name,
    String? brand,
    String? model,
    String? uom,
    String? description,
    double? quantity,
    double? unitPrice,
    double? taxRate,
    double? taxAmount,
    double? totalPrice,
    int? orderIndex,
    int? warrantyTime,
    String? warrantyUnit,
    String? sourceType,
    bool? requiresSerials,
    bool? isDropshipping,
    List<DeliveryNoteSerialModel>? serials,
  }) {
    return DeliveryNoteItemModel(
      id: id ?? this.id,
      deliveryNoteId: deliveryNoteId ?? this.deliveryNoteId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      uom: uom ?? this.uom,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      orderIndex: orderIndex ?? this.orderIndex,
      warrantyTime: warrantyTime ?? this.warrantyTime,
      warrantyUnit: warrantyUnit ?? this.warrantyUnit,
      sourceType: sourceType ?? this.sourceType,
      requiresSerials: requiresSerials ?? this.requiresSerials,
      isDropshipping: isDropshipping ?? this.isDropshipping,
      serials: serials ?? this.serials,
    );
  }
}
