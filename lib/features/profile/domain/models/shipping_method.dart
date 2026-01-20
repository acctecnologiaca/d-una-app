class ShippingMethod {
  final String id;
  final String userId;
  final String label;
  final String company;
  final String deliveryOption;
  final String? branchCode;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final bool isPrimary;
  final bool useMainAddress;
  final DateTime? createdAt;

  ShippingMethod({
    required this.id,
    required this.userId,
    required this.label,
    required this.company,
    required this.deliveryOption,
    this.branchCode,
    this.address,
    this.city,
    this.state,
    this.country,
    this.isPrimary = false,
    this.useMainAddress = false,
    this.createdAt,
  });

  factory ShippingMethod.fromJson(Map<String, dynamic> json) {
    return ShippingMethod(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      label: json['label'] as String,
      company: json['company'] as String,
      deliveryOption: json['delivery_option'] as String,
      branchCode: json['branch_code'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      useMainAddress: json['use_main_address'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'label': label,
      'company': company,
      'delivery_option': deliveryOption,
      'branch_code': branchCode,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'is_primary': isPrimary,
      'use_main_address': useMainAddress,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ShippingMethod copyWith({
    String? label,
    String? company,
    String? deliveryOption,
    String? branchCode,
    String? address,
    String? city,
    String? state,
    String? country,
    bool? isPrimary,
    bool? useMainAddress,
  }) {
    return ShippingMethod(
      id: id,
      userId: userId,
      label: label ?? this.label,
      company: company ?? this.company,
      deliveryOption: deliveryOption ?? this.deliveryOption,
      branchCode: branchCode ?? this.branchCode,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      isPrimary: isPrimary ?? this.isPrimary,
      useMainAddress: useMainAddress ?? this.useMainAddress,
      createdAt: createdAt,
    );
  }
}
