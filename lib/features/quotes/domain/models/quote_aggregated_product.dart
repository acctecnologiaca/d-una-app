import '../../../../core/utils/string_extensions.dart';

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
  final List<QuoteAggregatedSource> sources;

  const QuoteAggregatedProduct({
    required this.name,
    required this.brand,
    required this.model,
    required this.uom,
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
    this.sources = const [],
  });

  factory QuoteAggregatedProduct.fromMap(Map<String, dynamic> map) {
    return QuoteAggregatedProduct(
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      uom: map['uom'] ?? 'ud.',
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
      sources:
          (map['sources'] as List<dynamic>?)
              ?.map(
                (s) => QuoteAggregatedSource.fromMap(s as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  /// Returns a new instance where the aggregated values only reflect the selected suppliers.
  /// If the set is empty, returns this instance unchanged.
  QuoteAggregatedProduct filterBySuppliers(Set<String> selectedSuppliers) {
    if (selectedSuppliers.isEmpty) return this;

    final selectedLower = selectedSuppliers
        .map((s) => s.toLowerCase().trim())
        .toSet();

    final filteredSources = sources.where((s) {
      final sourceNameLower = s.supplierName.toLowerCase().trim();
      return selectedLower.contains(sourceNameLower);
    }).toList();

    double newMinPrice = double.infinity;
    double newTotalQuantity = 0.0;
    bool newHasOwnInventory = false;
    final Set<String> uniqueSuppliers = {};
    bool newIsLocked = true;

    for (final src in filteredSources) {
      if (src.isAccessible && src.price < newMinPrice && src.price > 0) {
        newMinPrice = src.price;
      }
      if (src.isOwn) {
        newHasOwnInventory = true;
      } else {
        uniqueSuppliers.add(src.supplierName);
      }
      newTotalQuantity += src.quantity;
      if (src.isAccessible) {
        newIsLocked = false;
      }
    }

    // Fallback if no accessible valid price was found
    if (newMinPrice == double.infinity && filteredSources.isNotEmpty) {
      for (final src in filteredSources) {
        if (src.price < newMinPrice && src.price > 0) {
          newMinPrice = src.price;
        }
      }
    }

    if (newMinPrice == double.infinity) newMinPrice = 0.0;

    final newSupplierCount =
        uniqueSuppliers.length + (newHasOwnInventory ? 1 : 0);

    return QuoteAggregatedProduct(
      name: name,
      brand: brand,
      model: model,
      uom: uom,
      minPrice: newMinPrice,
      totalQuantity: newTotalQuantity,
      supplierCount: newSupplierCount,
      hasOwnInventory: newHasOwnInventory,
      frequencyScore: frequencyScore,
      lastAddedAt: lastAddedAt,
      category: category,
      firstSupplierTradeType: firstSupplierTradeType,
      isLocked: filteredSources.isEmpty ? false : newIsLocked,
      supplierNames: supplierNames,
      sources: filteredSources,
    );
  }
}
