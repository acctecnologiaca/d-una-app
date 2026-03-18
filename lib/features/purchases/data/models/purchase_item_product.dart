class PurchaseItemProduct {
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

  PurchaseItemProduct({
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

  PurchaseItemProduct copyWith({
    double? quantity,
    double? unitPrice,
    int? warrantyTime,
    String? warrantyUnit,
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
      requiresSerials: requiresSerials,
    );
  }
}
