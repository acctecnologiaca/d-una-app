import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String type; // 'product', 'service', 'both', 'other'
  final String? userId;
  final bool isVerified;
  final bool isGlobal;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.userId,
    this.isVerified = false,
    this.isGlobal = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      type: json['type'] ?? 'other',
      userId: json['user_id'],
      isVerified: json['is_verified'] ?? false,
      isGlobal: json['is_global'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'user_id': userId,
      'is_verified': isVerified,
      'is_global': isGlobal,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? userId,
    bool? isVerified,
    bool? isGlobal,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      isVerified: isVerified ?? this.isVerified,
      isGlobal: isGlobal ?? this.isGlobal,
    );
  }

  @override
  List<Object?> get props => [id, name, type, userId, isVerified, isGlobal];
}
