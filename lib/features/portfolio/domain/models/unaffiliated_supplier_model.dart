import 'package:equatable/equatable.dart';

/// Represents a non-affiliated supplier registered by a user.
/// Affiliated (connected) suppliers use the full [Supplier] model via RPC.
class UnaffiliatedSupplier extends Equatable {
  final String id;
  final String name; // Nombre comercial / alias
  final String? legalName; // Razón social (nombre legal)
  final String? phone;
  final String? email;
  final String? taxId;
  final String? userId;
  final bool isVerified;
  final double minimumPurchaseAmount;

  const UnaffiliatedSupplier({
    required this.id,
    required this.name,
    this.legalName,
    this.phone,
    this.email,
    this.taxId,
    this.userId,
    this.isVerified = false,
    this.minimumPurchaseAmount = 0.0,
  });

  factory UnaffiliatedSupplier.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return UnaffiliatedSupplier(
      id: json['id'],
      name: json['name'],
      legalName: json['legal_name'],
      phone: json['phone'],
      email: json['email'],
      taxId: (json['tax_id'] as String?)?.trim(),
      userId: json['user_id'],
      isVerified: json['is_verified'] ?? false,
      minimumPurchaseAmount: parseDouble(json['minimum_purchase_amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'legal_name': legalName,
      'phone': phone,
      'email': email,
      'tax_id': taxId,
      'user_id': userId,
      'is_affiliated': false,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        legalName,
        phone,
        email,
        taxId,
        userId,
        isVerified,
        minimumPurchaseAmount,
      ];
}
