import 'package:equatable/equatable.dart';

class Brand extends Equatable {
  final String id;
  final String name;
  final String? userId;
  final bool isVerified;

  const Brand({
    required this.id,
    required this.name,
    this.userId,
    this.isVerified = false,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'],
      name: json['name'],
      userId: json['user_id'],
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'is_verified': isVerified,
    };
  }

  @override
  List<Object?> get props => [id, name, userId, isVerified];
}
