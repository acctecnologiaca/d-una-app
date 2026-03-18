class FinancialParameter {
  final String id;
  final String? userId;
  final double profitMargin;
  final double taxRate;
  final String currencyCode;
  final String pricingMethod; // 'markup' or 'margin'
  final DateTime updatedAt;

  FinancialParameter({
    required this.id,
    this.userId,
    required this.profitMargin,
    required this.taxRate,
    required this.currencyCode,
    this.pricingMethod = 'margin',
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
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
