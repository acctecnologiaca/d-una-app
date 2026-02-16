import 'package:equatable/equatable.dart';

/// Represents an aggregated product result from the search.
/// Data is aggregated from `supplier_products` and `product_stock` (Multi-Branch).
class AggregatedProduct extends Equatable {
  final String name;
  final String brand;
  final String model;
  final String category;
  final double minPrice;
  final int totalQuantity;
  final int supplierCount;
  final String? firstSupplierId;
  final String? firstSupplierName;
  final String? firstSupplierTradeType;
  final String uom;
  final bool isLocked;

  const AggregatedProduct({
    required this.name,
    required this.brand,
    required this.model,
    required this.category,
    required this.minPrice,
    required this.totalQuantity,
    required this.supplierCount,
    this.firstSupplierId,
    this.firstSupplierName,
    this.firstSupplierTradeType,
    required this.uom,
    this.isLocked = false,
  });

  factory AggregatedProduct.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse numbers
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return AggregatedProduct(
      name: json['name'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String? ?? '', // Handle potential null model
      category: json['category'] as String? ?? 'Sin Categoría',
      minPrice: parseDouble(json['min_price']),
      totalQuantity: parseInt(json['total_quantity']),
      supplierCount: parseInt(json['supplier_count']),
      firstSupplierId: json['first_supplier_id'] as String?,
      firstSupplierName: json['first_supplier_name'] as String?,
      firstSupplierTradeType: json['first_supplier_trade_type'] as String?,
      uom: json['uom'] as String? ?? 'Unidad',
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    name,
    brand,
    model,
    category,
    minPrice,
    totalQuantity,
    supplierCount,
    firstSupplierId,
    firstSupplierName,
    firstSupplierTradeType,
    uom,
    isLocked,
  ];
}
