enum ProductSourceType { own, supplier }

class QuoteProductSource {
  final String id;
  final ProductSourceType sourceType;
  final String sourceName;
  final String? location;
  final double price;
  final double maxStock;
  final String? tradeType;
  final bool isAccessible;
  final String? uomSymbolName;

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
    this.uomSymbolName,
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
      uomSymbolName: map['uom_symbol_name'],
    );
  }

  QuoteProductSource copyWith({double? selectedQuantity}) {
    return QuoteProductSource(
      id: id,
      sourceType: sourceType,
      sourceName: sourceName,
      location: location,
      price: price,
      maxStock: maxStock,
      tradeType: tradeType,
      isAccessible: isAccessible,
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
    );
  }
}
