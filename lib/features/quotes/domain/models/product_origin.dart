enum OriginType { own, affiliated, external, temporal }

class ProductOrigin {
  final OriginType type;
  final String label;
  final double quantity;
  final double availableStock;

  const ProductOrigin({
    required this.type,
    required this.label,
    this.quantity = 0.0,
    this.availableStock = 0.0,
  });

  ProductOrigin copyWith({
    OriginType? type,
    String? label,
    double? quantity,
    double? availableStock,
  }) {
    return ProductOrigin(
      type: type ?? this.type,
      label: label ?? this.label,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock ?? this.availableStock,
    );
  }
}
