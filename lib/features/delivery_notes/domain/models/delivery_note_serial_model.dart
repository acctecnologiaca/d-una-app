class DeliveryNoteSerialModel {
  final String id;
  final String deliveryNoteItemId;
  final String? productId;
  final String? productSerialId;
  final String serialNumber;
  final DateTime? createdAt;

  const DeliveryNoteSerialModel({
    required this.id,
    required this.deliveryNoteItemId,
    this.productId,
    this.productSerialId,
    required this.serialNumber,
    this.createdAt,
  });

  factory DeliveryNoteSerialModel.fromJson(Map<String, dynamic> json) {
    return DeliveryNoteSerialModel(
      id: json['id'] as String,
      deliveryNoteItemId: json['delivery_note_item_id'] as String,
      productId: json['product_id'] as String?,
      productSerialId: json['product_serial_id'] as String?,
      serialNumber: json['serial_number'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_note_item_id': deliveryNoteItemId,
      if (productId != null) 'product_id': productId,
      if (productSerialId != null) 'product_serial_id': productSerialId,
      'serial_number': serialNumber,
    };
  }

  DeliveryNoteSerialModel copyWith({
    String? id,
    String? deliveryNoteItemId,
    String? productId,
    String? productSerialId,
    String? serialNumber,
    DateTime? createdAt,
  }) {
    return DeliveryNoteSerialModel(
      id: id ?? this.id,
      deliveryNoteItemId: deliveryNoteItemId ?? this.deliveryNoteItemId,
      productId: productId ?? this.productId,
      productSerialId: productSerialId ?? this.productSerialId,
      serialNumber: serialNumber ?? this.serialNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
