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
  final String description;
  final String? imageUrl;
  final List<Map<String, String>> suppliersInfo;

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
    this.description = '',
    this.imageUrl,
    this.suppliersInfo = const [],
    this.sources = const [],
  });

  factory QuoteAggregatedProduct.fromMap(Map<String, dynamic> map) {
    return QuoteAggregatedProduct(
      // Cambiamos las llaves para que coincidan con el nuevo SQL
      name: map['product_name'] ?? '',
      brand: map['product_brand'] ?? '',
      model: map['product_model'] ?? '',
      uom: map['product_uom'] ?? 'ud.',
      uomIconName: map['uom_icon_name'] ?? 'package_2',
      minPrice: (map['min_price'] as num?)?.toDouble() ?? 0.0,
      totalQuantity: (map['total_quantity'] as num?)?.toDouble() ?? 0.0,
      supplierCount: map['supplier_count'] ?? 0,
      hasOwnInventory: map['has_own_inventory'] ?? false,
      frequencyScore: map['frequency_score'] ?? 0,
      lastAddedAt: map['last_added_at'] != null
          ? DateTime.parse(map['last_added_at'])
          : DateTime.now(),
      category: map['product_category'] ?? '',
      firstSupplierTradeType: map['first_supplier_trade_type'],
      isLocked: map['is_locked'] ?? false,
      description: map['product_description'] ?? '',
      imageUrl: map['product_image_url'], // Actualizado

      suppliersInfo:
          (map['suppliers_info'] as List<dynamic>?)
              ?.map(
                (item) => {
                  'id': item['id'].toString(),
                  'name': item['name'].toString(),
                },
              )
              .toList() ??
          [],

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
