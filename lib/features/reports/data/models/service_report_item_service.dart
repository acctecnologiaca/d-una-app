class ServiceReportItemService {
  final String id;
  final String reportId;
  final String? serviceId;
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
  final int? warrantyTime;
  final String? warrantyUnit;

  // Persisted Snapshots
  final String rateSymbol;
  final String? rateIconName;
  final String? categoryName;
  final String? executionTimeLabel;
  final int orderIndex;

  ServiceReportItemService({
    required this.id,
    required this.reportId,
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
    this.warrantyUnit,
    this.rateSymbol = 'ud.',
    this.rateIconName,
    this.categoryName,
    this.executionTimeLabel,
    this.orderIndex = 0,
  });

  factory ServiceReportItemService.fromJson(Map<String, dynamic> json) {
    return ServiceReportItemService(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      serviceId: json['service_id'] as String?,
      executionTimeId: json['execution_time_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      warrantyTime: json['warranty_time'] as int?,
      warrantyUnit: json['warranty_unit'] as String?,
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
      'report_id': reportId,
      if (serviceId != null) 'service_id': serviceId,
      if (executionTimeId != null) 'execution_time_id': executionTimeId,
      'name': name,
      if (description != null) 'description': description,
      'quantity': quantity,
      'cost_price': costPrice,
      'profit_margin': profitMargin,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_price': totalPrice,
      if (warrantyTime != null) 'warranty_time': warrantyTime,
      if (warrantyUnit != null) 'warranty_unit': warrantyUnit,
      'rate_symbol': rateSymbol,
      if (rateIconName != null) 'rate_icon_name': rateIconName,
      if (categoryName != null) 'category_name': categoryName,
      if (executionTimeLabel != null) 'execution_time_label': executionTimeLabel,
      'order_index': orderIndex,
    };
  }

  ServiceReportItemService copyWith({
    String? id,
    String? reportId,
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
    int? warrantyTime,
    String? warrantyUnit,
    String? rateSymbol,
    String? rateIconName,
    String? categoryName,
    String? executionTimeLabel,
    int? orderIndex,
  }) {
    return ServiceReportItemService(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
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
      warrantyUnit: warrantyUnit ?? this.warrantyUnit,
      rateSymbol: rateSymbol ?? this.rateSymbol,
      rateIconName: rateIconName ?? this.rateIconName,
      categoryName: categoryName ?? this.categoryName,
      executionTimeLabel: executionTimeLabel ?? this.executionTimeLabel,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
