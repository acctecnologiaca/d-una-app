import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String type; // 'product', 'service', 'both', 'other'

  const Category({required this.id, required this.name, required this.type});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      type: json['type'] ?? 'other',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'type': type};
  }

  @override
  List<Object?> get props => [id, name, type];
}
