import 'package:equatable/equatable.dart';

class ServiceRate extends Equatable {
  final String id;
  final String name;
  final String symbol;
  final String? createdBy;
  final bool isVerified;

  const ServiceRate({
    required this.id,
    required this.name,
    required this.symbol,
    this.createdBy,
    this.isVerified = false,
  });

  factory ServiceRate.fromJson(Map<String, dynamic> json) {
    return ServiceRate(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'] ?? '',
      createdBy: json['created_by'],
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'created_by': createdBy,
      'is_verified': isVerified,
    };
  }

  @override
  List<Object?> get props => [id, name, symbol, createdBy, isVerified];
}
