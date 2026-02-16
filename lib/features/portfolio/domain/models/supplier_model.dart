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

  const Supplier({
    required this.id,
    required this.name,
    this.bannerUrl,
    this.logoUrl,
    this.isActive = true,
    this.tradeType,
    this.allowedVerificationTypes = const [],
    this.contactInfo = const {},
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
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
  ];
}
