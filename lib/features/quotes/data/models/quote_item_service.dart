class QuoteItemService {
  final String id;
  final String quoteId;
  final String? serviceId; // Own
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
  final double taxAmount;
  final double totalPrice;
  final String? warrantyTime;

  // Persisted Snapshots
  final String rateSymbol;
  final String? rateIconName;
  final String? categoryName;
  final String? executionTimeLabel;
  final int orderIndex;

  QuoteItemService({
    required this.id,
    required this.quoteId,
    this.serviceId,
    this.executionTimeId,
    required this.name,
    this.description,
    required this.quantity,
    required this.costPrice,
    required this.profitMargin,
    required this.unitPrice,
    required this.taxRate,
    this.taxAmount = 0,
    required this.totalPrice,
    this.warrantyTime,
    this.rateSymbol = 'ud.',
    this.rateIconName,
    this.categoryName,
    this.executionTimeLabel,
    this.orderIndex = 0,
  });

  factory QuoteItemService.fromJson(Map<String, dynamic> json) {
    return QuoteItemService(
      id: json['id'] as String,
      quoteId: json['quote_id'] as String,
      serviceId: json['service_id'] as String?,
      executionTimeId: json['execution_time_id'] as String?,

      name: json['name'] as String,
      description: json['description'] as String?,

      quantity: (json['quantity'] as num).toDouble(),
      costPrice: (json['cost_price'] as num).toDouble(),
      profitMargin: (json['profit_margin'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      taxRate: (json['tax_rate'] as num).toDouble(),
      taxAmount: json['tax_amount'] != null
          ? (json['tax_amount'] as num).toDouble()
          : 0,
      totalPrice: (json['total_price'] as num).toDouble(),

      warrantyTime: json['warranty_time'] as String?,
      rateSymbol: json['rate_symbol'] as String? ?? 'ud.',
      rateIconName: json['rate_icon_name'] as String?,
      categoryName: json['category_name'] as String?,
      executionTimeLabel: json['execution_time_label'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quote_id': quoteId,
      'service_id': serviceId,
      'execution_time_id': executionTimeId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'cost_price': costPrice,
      'profit_margin': profitMargin,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_price': totalPrice,
      'warranty_time': warrantyTime,
      'rate_symbol': rateSymbol,
      'rate_icon_name': rateIconName,
      'category_name': categoryName,
      'execution_time_label': executionTimeLabel,
      'order_index': orderIndex,
    };
  }

  QuoteItemService copyWith({
    String? id,
    String? quoteId,
    String? serviceId,
    String? executionTimeId,
    String? name,
    String? description,
    double? quantity,
    double? costPrice,
    double? profitMargin,
    double? unitPrice,
    double? taxRate,
    double? taxAmount,
    double? totalPrice,
    String? warrantyTime,
    String? rateSymbol,
    String? rateIconName,
    String? categoryName,
    String? executionTimeLabel,
    int? orderIndex,
  }) {
    return QuoteItemService(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      serviceId: serviceId ?? this.serviceId,
      executionTimeId: executionTimeId ?? this.executionTimeId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      profitMargin: profitMargin ?? this.profitMargin,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      warrantyTime: warrantyTime ?? this.warrantyTime,
      rateSymbol: rateSymbol ?? this.rateSymbol,
      rateIconName: rateIconName ?? this.rateIconName,
      categoryName: categoryName ?? this.categoryName,
      executionTimeLabel: executionTimeLabel ?? this.executionTimeLabel,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
