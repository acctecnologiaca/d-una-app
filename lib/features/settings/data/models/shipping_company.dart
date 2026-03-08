import 'package:equatable/equatable.dart';

class ShippingCompany extends Equatable {
  final String id;
  final String legalName;
  final String taxId;
  final String? name; // Commercial name
  final bool isVerified;
  final String? createdBy;

  const ShippingCompany({
    required this.id,
    required this.legalName,
    required this.taxId,
    this.name,
    this.isVerified = false,
    this.createdBy,
  });

  factory ShippingCompany.fromJson(Map<String, dynamic> json) {
    return ShippingCompany(
      id: json['id'] as String,
      legalName: json['legal_name'] as String,
      taxId: json['tax_id'] as String,
      name: json['name'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'legal_name': legalName,
      'tax_id': taxId,
      'name': name,
      'is_verified': isVerified,
    };
  }

  /// Returns the commercial name if available, otherwise the legal name.
  String get displayName => name?.isNotEmpty == true ? name! : legalName;

  @override
  List<Object?> get props => [
    id,
    legalName,
    taxId,
    name,
    isVerified,
    createdBy,
  ];
}
