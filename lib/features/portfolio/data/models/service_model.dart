import 'service_rate_model.dart';
import 'package:equatable/equatable.dart';
import 'category_model.dart';

class ServiceModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final double price;
  final String serviceRateId; // Stores the service_rate_id (UUID)
  final ServiceRate? serviceRate; // Nested object
  final String? categoryId;
  final Category? category;
  final bool hasWarranty;
  final int? warrantyTime;
  final String? warrantyUnit; // 'days', 'months', 'years'
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.price,
    required this.serviceRateId,
    this.serviceRate,
    this.categoryId,
    this.category,
    this.hasWarranty = false,
    this.warrantyTime,
    this.warrantyUnit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      serviceRateId: json['service_rate_id'] ?? '',
      serviceRate: json['service_rates'] != null
          ? ServiceRate.fromJson(json['service_rates'])
          : null,
      categoryId: json['category_id'],
      category: json['categories'] != null
          ? Category.fromJson(json['categories'])
          : null,
      hasWarranty: json['has_warranty'] ?? false,
      warrantyTime: json['warranty_time'],
      warrantyUnit: json['warranty_unit'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'price': price,
      'service_rate_id': serviceRateId,
      'category_id': categoryId,
      'has_warranty': hasWarranty,
      'warranty_time': warrantyTime,
      'warranty_unit': warrantyUnit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ServiceModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? price,
    String? serviceRateId,
    ServiceRate? serviceRate,
    String? categoryId,
    Category? category,
    bool? hasWarranty,
    int? warrantyTime,
    String? warrantyUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      serviceRateId: serviceRateId ?? this.serviceRateId,
      serviceRate: serviceRate ?? this.serviceRate,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      hasWarranty: hasWarranty ?? this.hasWarranty,
      warrantyTime: warrantyTime ?? this.warrantyTime,
      warrantyUnit: warrantyUnit ?? this.warrantyUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    description,
    price,
    serviceRateId,
    serviceRate,
    categoryId,
    category,
    createdAt,
    updatedAt,
  ];
}
