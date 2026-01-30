import 'package:equatable/equatable.dart';
import 'category_model.dart';
import 'brand_model.dart';

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
  final String? imageUrl;
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
    this.imageUrl,
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
      imageUrl: json['image_url'],
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
    String? imageUrl,
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
      imageUrl: imageUrl ?? this.imageUrl,
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
    imageUrl,
    createdAt,
    updatedAt,
  ];
}
