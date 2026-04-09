enum ProductSourceType { own, supplier, externalManagement }

class QuoteProductSource {
  final String id;
  final ProductSourceType sourceType;
  final String sourceName;
  final String? location;
  final double price;
  final double maxStock;
  final String? tradeType;
  final bool isAccessible;
  final String? uomIconName;

  // Mutable UI state for draft selection
  double selectedQuantity;

  QuoteProductSource({
    required this.id,
    required this.sourceType,
    required this.sourceName,
    this.location,
    required this.price,
    required this.maxStock,
    this.tradeType,
    this.isAccessible = true,
    this.uomIconName,
    this.selectedQuantity = 0.0,
  });

  factory QuoteProductSource.fromMap(Map<String, dynamic> map) {
    return QuoteProductSource(
      id: map['source_id'] ?? '',
      sourceType: map['source_type'] == 'OWN'
          ? ProductSourceType.own
          : ProductSourceType.supplier,
      sourceName: map['source_name'] ?? '',
      location: map['location'],
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      maxStock: (map['stock'] as num?)?.toDouble() ?? 0.0,
      tradeType: map['trade_type'],
      isAccessible: map['is_accessible'] as bool? ?? false,
      uomIconName: map['uom_icon_name'],
    );
  }

  /// Creates a virtual "External Management" source.
  /// This source is not backed by any physical inventory or supplier.
  /// The user can freely set quantity and cost.
  factory QuoteProductSource.externalManagement({double suggestedPrice = 0.0}) {
    return QuoteProductSource(
      id: 'external-management',
      sourceType: ProductSourceType.externalManagement,
      sourceName: 'Proveedor Externo',
      location: null,
      price: suggestedPrice,
      maxStock: 999999.0,
      tradeType: null,
      isAccessible: true,
      uomIconName: null,
    );
  }

  QuoteProductSource copyWith({double? selectedQuantity, double? price}) {
    return QuoteProductSource(
      id: id,
      sourceType: sourceType,
      sourceName: sourceName,
      location: location,
      price: price ?? this.price,
      maxStock: maxStock,
      tradeType: tradeType,
      isAccessible: isAccessible,
      uomIconName: uomIconName,
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
    );
  }
}
