import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final String id;
  final String name;
  final String? bannerUrl;
  final String? logoUrl;
  final bool isActive;
  final String? tradeType;
  final List<String> allowedVerificationTypes;
  final Map<String, dynamic> contactInfo;
  final double minimumPurchaseAmount;
  final String? legalName;

  const Supplier({
    required this.id,
    required this.name,
    this.bannerUrl,
    this.logoUrl,
    this.isActive = true,
    this.tradeType,
    this.allowedVerificationTypes = const [],
    this.contactInfo = const {},
    this.minimumPurchaseAmount = 0.0,
    this.legalName,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Supplier(
      id: json['id'],
      name: json['name'],
      bannerUrl: json['banner_url'],
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
      tradeType: json['trade_type'],
      allowedVerificationTypes:
          (json['allowed_verification_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      contactInfo: json['contact_info'] ?? {},
      minimumPurchaseAmount: parseDouble(json['minimum_purchase_amount']),
      legalName: json['legal_name'],
    );
  }

  factory Supplier.empty() {
    return const Supplier(id: '', name: 'Desconocido');
  }

  @override
  List<Object?> get props => [
    id,
    name,
    bannerUrl,
    logoUrl,
    isActive,
    tradeType,
    allowedVerificationTypes,
    contactInfo,
    minimumPurchaseAmount,
    legalName,
  ];
}
