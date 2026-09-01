import 'package:equatable/equatable.dart';

class SupplierOrderItem extends Equatable {
  final String id;
  final String supplierOrderId;
  final String? productId;
  final String name;
  final String? brand;
  final String? model;
  final String uom;
  final String? uomIconName;
  final double quantity;
  final double unitPrice;

  // Real-time validation fields (calculated on the fly for warnings)
  final double? currentSupplierPrice;
  final double? currentSupplierStock;
  final String? supplierBranchStockId;
  final String? branchName;

  const SupplierOrderItem({
    required this.id,
    required this.supplierOrderId,
    this.productId,
    required this.name,
    this.brand,
    this.model,
    required this.uom,
    this.uomIconName,
    required this.quantity,
    required this.unitPrice,
    this.currentSupplierPrice,
    this.currentSupplierStock,
    this.supplierBranchStockId,
    this.branchName,
  });

  double get total => quantity * unitPrice;

  // Alerts
  bool get hasPriceIncrease =>
      currentSupplierPrice != null && currentSupplierPrice! > (unitPrice + 0.01);
  bool get isOutOfStock =>
      currentSupplierStock != null && currentSupplierStock! <= 0;
  bool get hasLowStock =>
      currentSupplierStock != null &&
      currentSupplierStock! > 0 &&
      currentSupplierStock! < quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_order_id': supplierOrderId,
      'product_id': productId,
      'name': name,
      'brand': brand,
      'model': model,
      'uom': uom,
      'uom_icon_name': uomIconName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'current_supplier_price': currentSupplierPrice,
      'current_supplier_stock': currentSupplierStock,
      'supplier_branch_stock_id': supplierBranchStockId,
      'branch_name': branchName,
    };
  }

  factory SupplierOrderItem.fromJson(Map<String, dynamic> json) {
    return SupplierOrderItem(
      id: json['id'] as String,
      supplierOrderId: json['supplier_order_id'] as String? ?? '',
      productId: json['product_id'] as String?,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      uom: json['uom'] as String? ?? '',
      uomIconName: json['uom_icon_name'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      currentSupplierPrice:
          (json['current_supplier_price'] as num?)?.toDouble(),
      currentSupplierStock:
          (json['current_supplier_stock'] as num?)?.toDouble(),
      supplierBranchStockId: json['supplier_branch_stock_id'] as String?,
      branchName: json['branch_name'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    supplierOrderId,
    productId,
    name,
    brand,
    model,
    uom,
    uomIconName,
    quantity,
    unitPrice,
    currentSupplierPrice,
    currentSupplierStock,
    supplierBranchStockId,
    branchName,
  ];
}
