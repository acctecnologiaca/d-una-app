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
  final String uomIconName;
  final String? externalProviderName;
  final double reservedStock;
  final double minimumPurchaseAmount;
  final DateTime? lastUpdated;

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
    required this.uomIconName,
    this.externalProviderName,
    this.selectedQuantity = 0.0,
    this.reservedStock = 0.0,
    this.minimumPurchaseAmount = 0.0,
    this.lastUpdated,
  });

  factory QuoteProductSource.fromMap(Map<String, dynamic> map) {
    final rawLastUpdated = map['last_updated'] ?? map['updated_at'];

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
      uomIconName: map['uom_icon_name'] ?? '',
      externalProviderName: map['external_provider_name'],
      reservedStock: (map['reserved_stock'] as num?)?.toDouble() ?? 0.0,
      minimumPurchaseAmount: (map['minimum_purchase_amount'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: rawLastUpdated != null
          ? DateTime.tryParse(rawLastUpdated.toString())
          : null,
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
      uomIconName: '',
      reservedStock: 0.0,
      minimumPurchaseAmount: 0.0,
    );
  }

  QuoteProductSource copyWith({
    double? selectedQuantity,
    bool? isAccessible,
    String? externalProviderName,
    double? price,
    double? reservedStock,
    double? minimumPurchaseAmount,
  }) {
    return QuoteProductSource(
      id: id,
      sourceType: sourceType,
      sourceName: sourceName,
      location: location,
      price: price ?? this.price,
      maxStock: maxStock,
      tradeType: tradeType,
      isAccessible: isAccessible ?? this.isAccessible,
      uomIconName: uomIconName,
      externalProviderName: externalProviderName ?? this.externalProviderName,
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
      reservedStock: reservedStock ?? this.reservedStock,
      minimumPurchaseAmount: minimumPurchaseAmount ?? this.minimumPurchaseAmount,
    );
  }
}
