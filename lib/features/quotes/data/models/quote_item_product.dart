class QuoteItemProduct {
  final String id;
  final String quoteId;
  final String? productId; // Own
  final String? supplierProductId; // Supplier
  final String? deliveryTimeId;

  // Snapshot
  final String name;
  final String? brand;
  final String? model;
  final String uom;
  final String? uomSymbolName;
  final String? description;
  final double? availableStock; // UI helper for tracking total stock available

  // Economic
  final double quantity;
  final double costPrice;
  final double profitMargin;
  final double unitPrice;
  final double taxRate;
  final double taxAmount;
  final double totalPrice;
  final String? warrantyTime;

  // Runtime-only flag, not persisted to DB
  final bool isTemporal;

  QuoteItemProduct({
    required this.id,
    required this.quoteId,
    this.productId,
    this.supplierProductId,
    this.deliveryTimeId,
    required this.name,
    this.brand,
    this.model,
    required this.uom,
    this.uomSymbolName,
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
    this.isTemporal = false,
  });

  factory QuoteItemProduct.fromJson(Map<String, dynamic> json) {
    return QuoteItemProduct(
      id: json['id'] as String,
      quoteId: json['quote_id'] as String,
      productId: json['product_id'] as String?,
      supplierProductId: json['supplier_product_id'] as String?,
      deliveryTimeId: json['delivery_time_id'] as String?,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      uom: json['uom'] as String,
      uomSymbolName: json['uom_symbol_name'] as String?,
      description: json['description'] as String?,
      availableStock: json['available_stock'] != null
          ? (json['available_stock'] as num).toDouble()
          : null,

      quantity: (json['quantity'] as num).toDouble(),
      costPrice: (json['cost_price'] as num).toDouble(),
      profitMargin: (json['profit_margin'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      taxRate: (json['tax_rate'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),

      warrantyTime: json['warranty_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quote_id': quoteId,
      'product_id': productId,
      'supplier_product_id': supplierProductId,
      'delivery_time_id': deliveryTimeId,
      'name': name,
      'brand': brand,
      'model': model,
      'uom': uom,
      'uom_symbol_name': uomSymbolName,
      'description': description,
      'available_stock': availableStock,
      'quantity': quantity,
      'cost_price': costPrice,
      'profit_margin': profitMargin,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_price': totalPrice,
      'warranty_time': warrantyTime,
    };
  }
}
