import 'package:equatable/equatable.dart';

/// Represents an aggregated product result from the search.
class AggregatedProduct extends Equatable {
  final String name;
  final String brand;
  final String model;
  final double minPrice;
  final int totalQuantity;
  final int supplierCount;

  const AggregatedProduct({
    required this.name,
    required this.brand,
    required this.model,
    required this.minPrice,
    required this.totalQuantity,
    required this.supplierCount,
  });

  factory AggregatedProduct.fromJson(Map<String, dynamic> json) {
    return AggregatedProduct(
      name: json['name'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      minPrice: (json['min_price'] as num).toDouble(),
      totalQuantity: json['total_quantity'] as int,
      supplierCount: json['supplier_count'] as int,
    );
  }

  @override
  List<Object?> get props => [
    name,
    brand,
    model,
    minPrice,
    totalQuantity,
    supplierCount,
  ];
}
