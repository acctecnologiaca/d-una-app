enum ReportProductSourceType { own, temporal }

class ServiceReportItemProduct {
  final String id;
  final String reportId;
  final String? productId; // Own product id or null if temporal
  final int groupIndex;

  // Snapshot
  final String name;
  final String? brand;
  final String? model;
  final String uom;
  final String? uomIconName;
  final String? description;
  final double? availableStock;

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

  final ReportProductSourceType sourceType;

  ServiceReportItemProduct({
    required this.id,
    required this.reportId,
    this.productId,
    required this.name,
    this.brand,
    this.model,
    required this.uom,
    this.uomIconName,
    this.description,
    this.availableStock,
    required this.quantity,
    required this.costPrice,
    required this.profitMargin,
    required this.unitPrice,
    required this.taxRate,
    required this.taxAmount,
    required this.totalPrice,
    this.warrantyTime,
    this.warrantyUnit,
    this.sourceType = ReportProductSourceType.own,
    this.groupIndex = 0,
  });

  factory ServiceReportItemProduct.fromJson(Map<String, dynamic> json) {
    return ServiceReportItemProduct(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      productId: json['product_id'] as String?,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      uom: json['uom'] as String? ?? 'ud.',
      uomIconName: json['uom_icon_name'] as String?,
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      groupIndex: json['group_index'] as int? ?? 0,
      warrantyTime: json['warranty_time'] as int?,
      warrantyUnit: json['warranty_unit'] as String?,
      sourceType: json['product_id'] != null
          ? ReportProductSourceType.own
          : ReportProductSourceType.temporal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      if (productId != null) 'product_id': productId,
      'name': name,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      'uom': uom,
      if (uomIconName != null) 'uom_icon_name': uomIconName,
      if (description != null) 'description': description,
      'quantity': quantity,
      'cost_price': costPrice,
      'profit_margin': profitMargin,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_price': totalPrice,
      'group_index': groupIndex,
      if (warrantyTime != null) 'warranty_time': warrantyTime,
      if (warrantyUnit != null) 'warranty_unit': warrantyUnit,
    };
  }

  ServiceReportItemProduct copyWith({
    String? id,
    String? reportId,
    String? productId,
    String? name,
    String? brand,
    String? model,
    String? uom,
    String? uomIconName,
    String? description,
    double? availableStock,
    double? quantity,
    double? costPrice,
    double? profitMargin,
    double? unitPrice,
    double? taxRate,
    double? taxAmount,
    double? totalPrice,
    int? warrantyTime,
    String? warrantyUnit,
    ReportProductSourceType? sourceType,
    int? groupIndex,
  }) {
    return ServiceReportItemProduct(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      uom: uom ?? this.uom,
      uomIconName: uomIconName ?? this.uomIconName,
      description: description ?? this.description,
      availableStock: availableStock ?? this.availableStock,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      profitMargin: profitMargin ?? this.profitMargin,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      warrantyTime: warrantyTime ?? this.warrantyTime,
      warrantyUnit: warrantyUnit ?? this.warrantyUnit,
      sourceType: sourceType ?? this.sourceType,
      groupIndex: groupIndex ?? this.groupIndex,
    );
  }
}
