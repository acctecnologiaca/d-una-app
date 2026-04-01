import 'package:equatable/equatable.dart';

class Uom extends Equatable {
  final String id;
  final String name;
  final String symbol;
  final String? userId;
  final bool isVerified;
  final String? iconName;

  const Uom({
    required this.id,
    required this.name,
    required this.symbol,
    this.userId,
    this.isVerified = false,
    this.iconName,
  });

  factory Uom.fromJson(Map<String, dynamic> json) {
    return Uom(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'] ?? '',
      userId: json['user_id'],
      isVerified: json['is_verified'] ?? false,
      iconName: json['icon_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'user_id': userId,
      'is_verified': isVerified,
      'icon_name': iconName,
    };
  }

  @override
  List<Object?> get props => [id, name, symbol, userId, isVerified, iconName];
}
