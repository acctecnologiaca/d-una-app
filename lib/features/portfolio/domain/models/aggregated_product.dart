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
  });

  factory AggregatedProduct.fromJson(Map<String, dynamic> json) {
    return AggregatedProduct(
      name: json['name'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      category: json['category'] as String? ?? 'Sin Categoría',
      minPrice: (json['min_price'] as num).toDouble(),
      totalQuantity: (json['total_quantity'] as num)
          .toInt(), // Safer cast for SUM
      supplierCount: (json['supplier_count'] as num)
          .toInt(), // Safer cast for COUNT
      firstSupplierId: json['first_supplier_id'] as String?,
      firstSupplierName: json['first_supplier_name'] as String?,
      firstSupplierTradeType: json['first_supplier_trade_type'] as String?,
      uom: json['uom'] as String? ?? 'Unidad',
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
  ];
}
