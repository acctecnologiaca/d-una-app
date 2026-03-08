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
  final String? createdBy;
  final bool isVerified;

  const UnaffiliatedSupplier({
    required this.id,
    required this.name,
    this.legalName,
    this.phone,
    this.email,
    this.taxId,
    this.createdBy,
    this.isVerified = false,
  });

  factory UnaffiliatedSupplier.fromJson(Map<String, dynamic> json) {
    return UnaffiliatedSupplier(
      id: json['id'],
      name: json['name'],
      legalName: json['legal_name'],
      phone: json['phone'],
      email: json['email'],
      taxId: json['tax_id'],
      createdBy: json['created_by'],
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'legal_name': legalName,
      'phone': phone,
      'email': email,
      'tax_id': taxId,
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
    createdBy,
    isVerified,
  ];
}
