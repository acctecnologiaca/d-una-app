class FinancialParameter {
  final String id;
  final double profitMargin;
  final double taxRate;
  final String currencyCode;
  final DateTime updatedAt;

  FinancialParameter({
    required this.id,
    required this.profitMargin,
    required this.taxRate,
    required this.currencyCode,
    required this.updatedAt,
  });

  factory FinancialParameter.fromJson(Map<String, dynamic> json) {
    return FinancialParameter(
      id: json['id'] as String,
      profitMargin: (json['profit_margin'] as num).toDouble(),
      taxRate: (json['tax_rate'] as num).toDouble(),
      currencyCode: json['currency_code'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profit_margin': profitMargin,
      'tax_rate': taxRate,
      'currency_code': currencyCode,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
