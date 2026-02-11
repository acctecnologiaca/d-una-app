import 'package:equatable/equatable.dart';

class ProductSearchFilters extends Equatable {
  final List<String> brands;
  final List<String> categories;
  final double? minPrice;
  final double? maxPrice;
  final List<String> supplierIds;

  const ProductSearchFilters({
    this.brands = const [],
    this.categories = const [],
    this.minPrice,
    this.maxPrice,
    this.supplierIds = const [],
  });

  ProductSearchFilters copyWith({
    List<String>? brands,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
    List<String>? supplierIds,
  }) {
    return ProductSearchFilters(
      brands: brands ?? this.brands,
      categories: categories ?? this.categories,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      supplierIds: supplierIds ?? this.supplierIds,
    );
  }

  @override
  List<Object?> get props => [
    brands,
    categories,
    minPrice,
    maxPrice,
    supplierIds,
  ];
}
