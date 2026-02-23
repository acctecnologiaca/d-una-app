enum ProductSourceType { own, supplier }

class QuoteProductSource {
  final String id;
  final ProductSourceType sourceType;
  final String sourceName;
  final String? location;
  final double price;
  final double maxStock;
  final String? tradeType;
  final String accessLevel;

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
    this.accessLevel = 'full',
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
      accessLevel: map['access_level'] ?? 'full',
    );
  }

  QuoteProductSource copyWith({double? selectedQuantity}) {
    return QuoteProductSource(
      id: this.id,
      sourceType: this.sourceType,
      sourceName: this.sourceName,
      location: this.location,
      price: this.price,
      maxStock: this.maxStock,
      tradeType: this.tradeType,
      accessLevel: this.accessLevel,
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
    );
  }
}
