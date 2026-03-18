import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String type; // 'product', 'service', 'both', 'other'
  final String? userId;
  final bool isVerified;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.userId,
    this.isVerified = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      type: json['type'] ?? 'other',
      userId: json['user_id'],
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'user_id': userId,
      'is_verified': isVerified,
    };
  }

  @override
  List<Object?> get props => [id, name, type, userId, isVerified];
}
