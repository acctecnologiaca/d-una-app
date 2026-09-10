class FinancialParameter {
  final String id;
  final String? userId;
  final double profitMargin;
  final double taxRate;
  final String currencyCode;
  final String pricingMethod; // 'markup' or 'margin'
  final String defaultPaymentMethod;
  final DateTime updatedAt;

  FinancialParameter({
    required this.id,
    this.userId,
    required this.profitMargin,
    required this.taxRate,
    required this.currencyCode,
    this.pricingMethod = 'margin',
    this.defaultPaymentMethod = 'Transferencia bancaria en bolívares',
    required this.updatedAt,
  });

  factory FinancialParameter.fromJson(Map<String, dynamic> json) {
    return FinancialParameter(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      profitMargin: (json['profit_margin'] as num).toDouble(),
      taxRate: (json['tax_rate'] as num).toDouble(),
      currencyCode: json['currency_code'] as String,
      pricingMethod: json['pricing_method'] as String? ?? 'margin',
      defaultPaymentMethod: json['default_payment_method'] as String? ??
          'Transferencia bancaria en bolívares',
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'profit_margin': profitMargin,
      'tax_rate': taxRate,
      'currency_code': currencyCode,
      'pricing_method': pricingMethod,
      'default_payment_method': defaultPaymentMethod,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
