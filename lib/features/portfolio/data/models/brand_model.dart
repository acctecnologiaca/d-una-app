import 'package:equatable/equatable.dart';

class Brand extends Equatable {
  final String id;
  final String name;
  final String? createdBy;
  final bool isVerified;

  const Brand({
    required this.id,
    required this.name,
    this.createdBy,
    this.isVerified = false,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'],
      name: json['name'],
      createdBy: json['created_by'],
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_by': createdBy,
      'is_verified': isVerified,
    };
  }

  @override
  List<Object?> get props => [id, name, createdBy, isVerified];
}
