class QuoteAggregatedSource {
  final String supplierName;
  final double price;
  final double quantity;
  final bool isOwn;
  final bool isAccessible;
  final String? supplierTradeType;

  const QuoteAggregatedSource({
    required this.supplierName,
    required this.price,
    required this.quantity,
    required this.isOwn,
    required this.isAccessible,
    this.supplierTradeType,
  });

  factory QuoteAggregatedSource.fromMap(Map<String, dynamic> map) {
    return QuoteAggregatedSource(
      supplierName: map['supplier_name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      isOwn: map['is_own'] ?? false,
      isAccessible: map['is_accessible'] ?? false,
      supplierTradeType: map['supplier_trade_type'],
    );
  }
}

class QuoteAggregatedProduct {
  final String name;
  final String brand;
  final String model;
  final String uom;
  final String uomIconName;
  final double minPrice;
  final double totalQuantity;
  final int supplierCount;
  final bool hasOwnInventory;
  final int frequencyScore;
  final DateTime lastAddedAt;
  final String category;
  final String? firstSupplierTradeType;
  final bool isLocked;
  final List<String> supplierNames;
  final List<String> supplierIds;
  final List<QuoteAggregatedSource> sources;

  const QuoteAggregatedProduct({
    required this.name,
    required this.brand,
    required this.model,
    required this.uom,
    required this.uomIconName,
    required this.minPrice,
    required this.totalQuantity,
    required this.supplierCount,
    required this.hasOwnInventory,
    required this.frequencyScore,
    required this.lastAddedAt,
    required this.category,
    this.firstSupplierTradeType,
    this.isLocked = false,
    this.supplierNames = const [],
    this.supplierIds = const [],
    this.sources = const [],
  });

  factory QuoteAggregatedProduct.fromMap(Map<String, dynamic> map) {
    return QuoteAggregatedProduct(
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      uom: map['uom'] ?? 'ud.',
      uomIconName: map['uom_icon_name'] ?? 'package_2',
      minPrice: (map['min_price'] as num?)?.toDouble() ?? 0.0,
      totalQuantity: (map['total_quantity'] as num?)?.toDouble() ?? 0.0,
      supplierCount: map['supplier_count'] ?? 0,
      hasOwnInventory: map['has_own_inventory'] ?? false,
      frequencyScore: map['frequency_score'] ?? 0,
      lastAddedAt: map['last_added_at'] != null
          ? DateTime.parse(map['last_added_at'])
          : DateTime.now(),
      category: map['category'] ?? '',
      firstSupplierTradeType: map['first_supplier_trade_type'],
      isLocked: map['is_locked'] ?? false,
      supplierNames: List<String>.from(map['supplier_names'] ?? []),
      supplierIds: List<String>.from(map['supplier_ids'] ?? []),
      sources:
          (map['sources'] as List<dynamic>?)
              ?.map(
                (s) => QuoteAggregatedSource.fromMap(s as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
