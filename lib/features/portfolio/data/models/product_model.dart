import 'package:equatable/equatable.dart';
import 'category_model.dart';
import 'brand_model.dart';
import 'uom_model.dart';

class Product extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? brandId; // Replaces 'brand' string
  final Brand? brand; // Nested object
  final String? model;
  final String? specs; // Mapped from 'specifications'
  final String? categoryId;
  final Category? category;
  final String? uomId; // Replaces fixed unit text
  final String? uom; // Symbol of the UOM
  final Uom? uomModel; // Full UOM object
  final String? imageUrl;
  final double inventoryQuantity;
  final double averageCost;
  final int purchaseCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.userId,
    required this.name,
    this.brandId,
    this.brand,
    this.model,
    this.specs,
    this.categoryId,
    this.category,
    this.uomId,
    this.uom,
    this.uomModel,
    this.imageUrl,
    this.inventoryQuantity = 0.0,
    this.averageCost = 0.0,
    this.purchaseCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      brandId: json['brand_id'],
      brand: json['brands'] != null ? Brand.fromJson(json['brands']) : null,
      model: json['model'],
      specs: json['specifications'],
      categoryId: json['category_id'],
      category: json['categories'] != null
          ? Category.fromJson(json['categories'])
          : null,
      uomId: json['uom_id'],
      uom: json['uoms'] != null ? json['uoms']['symbol'] : null,
      uomModel: json['uoms'] != null ? Uom.fromJson(json['uoms']) : null,
      imageUrl: json['image_url'],
      inventoryQuantity:
          (json['inventory_quantity'] as num?)?.toDouble() ?? 0.0,
      averageCost: (json['average_cost'] as num?)?.toDouble() ?? 0.0,
      purchaseCount: (json['purchase_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'brand_id': brandId,
      // 'brands': brand?.toJson(),
      'model': model,
      'specifications': specs,
      'category_id': categoryId,
      // 'categories': category?.toJson(),
      'uom_id': uomId,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? userId,
    String? name,
    String? brandId,
    Brand? brand,
    String? model,
    String? specs,
    String? categoryId,
    Category? category,
    String? uomId,
    String? uom,
    Uom? uomModel,
    String? imageUrl,
    double? inventoryQuantity,
    double? averageCost,
    int? purchaseCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brandId: brandId ?? this.brandId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      specs: specs ?? this.specs,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      uomId: uomId ?? this.uomId,
      uom: uom ?? this.uom,
      uomModel: uomModel ?? this.uomModel,
      imageUrl: imageUrl ?? this.imageUrl,
      inventoryQuantity: inventoryQuantity ?? this.inventoryQuantity,
      averageCost: averageCost ?? this.averageCost,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    brandId,
    brand,
    model,
    specs,
    categoryId,
    category,
    uomId,
    uom,
    uomModel,
    imageUrl,
    inventoryQuantity,
    averageCost,
    purchaseCount,
    createdAt,
    updatedAt,
  ];
}
