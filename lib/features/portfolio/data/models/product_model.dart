import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? brand;
  final String? model;
  final String? specs; // Mapped from 'specifications'
  final String? category;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.userId,
    required this.name,
    this.brand,
    this.model,
    this.specs, // We use 'specs' in code, 'specifications' in DB
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
      brand: json['brand'],
      model: json['model'],
      specs: json['specifications'],
      category: json['category'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'brand': brand,
      'model': model,
      'specifications': specs,
      'category': category,
      'image_url': imageUrl,
      // created_at and updated_at are handled by DB
    };
  }

  Product copyWith({
    String? id,
    String? userId,
    String? name,
    String? brand,
    String? model,
    String? specs,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      specs: specs ?? this.specs,
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
    brand,
    model,
    specs,
    category,
    imageUrl,
    createdAt,
    updatedAt,
  ];
}
