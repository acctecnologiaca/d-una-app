class QuoteItemService {
  final String id;
  final String quoteId;
  final String? serviceId; // Own
  final String? serviceRateId;
  final String? executionTimeId;

  // Snapshot
  final String name;
  final String? description;

  // Economic
  final double quantity;
  final double costPrice;
  final double profitMargin;
  final double unitPrice;
  final double taxRate;
  final double totalPrice;
  final String? warrantyTime;

  QuoteItemService({
    required this.id,
    required this.quoteId,
    this.serviceId,
    this.serviceRateId,
    this.executionTimeId,
    required this.name,
    this.description,
    required this.quantity,
    required this.costPrice,
    required this.profitMargin,
    required this.unitPrice,
    required this.taxRate,
    required this.totalPrice,
    this.warrantyTime,
  });

  factory QuoteItemService.fromJson(Map<String, dynamic> json) {
    return QuoteItemService(
      id: json['id'] as String,
      quoteId: json['quote_id'] as String,
      serviceId: json['service_id'] as String?,
      serviceRateId: json['service_rate_id'] as String?,
      executionTimeId: json['execution_time_id'] as String?,

      name: json['name'] as String,
      description: json['description'] as String?,

      quantity: (json['quantity'] as num).toDouble(),
      costPrice: (json['cost_price'] as num).toDouble(),
      profitMargin: (json['profit_margin'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      taxRate: (json['tax_rate'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),

      warrantyTime: json['warranty_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quote_id': quoteId,
      'service_id': serviceId,
      'service_rate_id': serviceRateId,
      'execution_time_id': executionTimeId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'cost_price': costPrice,
      'profit_margin': profitMargin,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
      'total_price': totalPrice,
      'warranty_time': warrantyTime,
    };
  }
}
