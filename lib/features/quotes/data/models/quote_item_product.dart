enum QuoteItemSourceType { own, affiliated, external, temporal }

class QuoteItemProduct {
  final String id;
  final String quoteId;
  final String? productId; // Own
  final String? supplierBranchStockId; // From supplier_branch_stock(id)
  final String? deliveryTimeId;
  final String? externalProviderName;
  final String? supplierName; // Read-only from Join
  final int groupIndex;

  // Snapshot
  final String name;
  final String? brand;
  final String? model;
  final String uom;
  final String? uomIconName;
  final String? description;
  final double? availableStock; // UI helper for tracking total stock available
  final double? reservedStock; // UI helper for tracking reserved own stock

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

  final QuoteItemSourceType sourceType;

  QuoteItemProduct({
    required this.id,
    required this.quoteId,
    this.productId,
    this.supplierBranchStockId,
    this.deliveryTimeId,
    required this.name,
    this.brand,
    this.model,
    required this.uom,
    this.uomIconName,
    this.description,
    this.availableStock,
    this.reservedStock,
    required this.quantity,
    required this.costPrice,
    required this.profitMargin,
    required this.unitPrice,
    required this.taxRate,
    required this.taxAmount,
    required this.totalPrice,
    this.warrantyTime,
    this.warrantyUnit,
    this.externalProviderName,
    this.supplierName,
    required this.sourceType,
    required this.groupIndex,
  });

  factory QuoteItemProduct.fromJson(Map<String, dynamic> json) {
    QuoteItemSourceType determineSourceType() {
      if (json['source_type'] != null) {
        return QuoteItemSourceType.values.firstWhere(
          (e) => e.name == json['source_type'],
          orElse: () => QuoteItemSourceType.own,
        );
      }
      // Fallback for legacy data
      if (json['product_id'] != null) return QuoteItemSourceType.own;
      if (json['supplier_branch_stock_id'] != null) return QuoteItemSourceType.affiliated;
      if (json['external_provider_name'] != null) return QuoteItemSourceType.external;
      return QuoteItemSourceType.temporal;
    }

    return QuoteItemProduct(
      id: json['id'] as String,
      quoteId: json['quote_id'] as String,
      productId: json['product_id'] as String?,
      supplierBranchStockId: json['supplier_branch_stock_id'] as String?,
      deliveryTimeId: json['delivery_time_id'] as String?,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      uom: json['uom'] as String,
      uomIconName: json['uom_icon_name'] as String?,
      description: json['description'] as String?,
      availableStock: json['available_stock'] != null
          ? (json['available_stock'] as num?)?.toDouble()
          : null,
      reservedStock: json['reserved_stock'] != null
          ? (json['reserved_stock'] as num?)?.toDouble()
          : null,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      warrantyTime: json['warranty_time'] as int?,
      warrantyUnit: json['warranty_unit'] as String?,
      externalProviderName: json['external_provider_name'] as String?,
      supplierName: _extractSupplierName(json),
      sourceType: determineSourceType(),
      groupIndex: json['group_index'] as int? ?? 0,
    );
  }

  static String? _extractSupplierName(Map<String, dynamic> json) {
    final sbs = json['supplier_branch_stock'];
    if (sbs is Map<String, dynamic>) {
      final sb = sbs['supplier_branches'];
      if (sb is Map<String, dynamic>) {
        final supplier = sb['suppliers'];
        if (supplier is Map<String, dynamic>) {
          return supplier['name'] as String?;
        }
      }
    }
    return null;
  }

  /// Returns a human-readable warranty string, e.g., "30 Días"
  String? get warrantyDisplay {
    if (warrantyTime == null || warrantyTime == 0) return null;
    final unitLabel = switch (warrantyUnit) {
      'days' => 'Días',
      'months' => 'Meses',
      'years' => 'Años',
      _ => 'Días',
    };
    return '$warrantyTime $unitLabel';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quote_id': quoteId,
      'product_id': productId,
      'supplier_branch_stock_id': supplierBranchStockId,
      'delivery_time_id': deliveryTimeId,
      'name': name,
      'brand': brand,
      'model': model,
      'uom': uom,
      'uom_icon_name': uomIconName,
      'description': description,
      'available_stock': availableStock,
      'reserved_stock': reservedStock,
      'quantity': quantity,
      'cost_price': costPrice,
      'profit_margin': profitMargin,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_price': totalPrice,
      'warranty_time': warrantyTime,
      'warranty_unit': warrantyUnit,
      'external_provider_name': externalProviderName,
      'source_type': sourceType.name,
      'group_index': groupIndex,
    };
  }

  QuoteItemProduct copyWith({
    String? id,
    String? quoteId,
    String? productId,
    String? supplierBranchStockId,
    Object? deliveryTimeId = _sentinel,
    String? name,
    String? brand,
    String? model,
    String? uom,
    String? uomIconName,
    String? description,
    double? availableStock,
    double? reservedStock,
    double? quantity,
    double? costPrice,
    double? profitMargin,
    double? unitPrice,
    double? taxRate,
    double? taxAmount,
    double? totalPrice,
    Object? warrantyTime = _sentinel,
    Object? warrantyUnit = _sentinel,
    String? externalProviderName,
    String? supplierName,
    QuoteItemSourceType? sourceType,
    int? groupIndex,
  }) {
    return QuoteItemProduct(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      productId: productId ?? this.productId,
      supplierBranchStockId:
          supplierBranchStockId ?? this.supplierBranchStockId,
      deliveryTimeId: deliveryTimeId == _sentinel
          ? this.deliveryTimeId
          : (deliveryTimeId as String?),
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      uom: uom ?? this.uom,
      uomIconName: uomIconName ?? this.uomIconName,
      description: description ?? this.description,
      availableStock: availableStock ?? this.availableStock,
      reservedStock: reservedStock ?? this.reservedStock,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      profitMargin: profitMargin ?? this.profitMargin,
      unitPrice: unitPrice ?? this.unitPrice,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      warrantyTime: warrantyTime == _sentinel
          ? this.warrantyTime
          : (warrantyTime as int?),
      warrantyUnit: warrantyUnit == _sentinel
          ? this.warrantyUnit
          : (warrantyUnit as String?),
      externalProviderName: externalProviderName ?? this.externalProviderName,
      supplierName: supplierName ?? this.supplierName,
      sourceType: sourceType ?? this.sourceType,
      groupIndex: groupIndex ?? this.groupIndex,
    );
  }
}

const _sentinel = Object();
