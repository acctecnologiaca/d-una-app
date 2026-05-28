import 'package:equatable/equatable.dart';

class SupplierOrderItem extends Equatable {
  final String id;
  final String supplierOrderId;
  final String? productId;
  final String name;
  final String? brand;
  final String? model;
  final String uom;
  final double quantity;
  final double unitPrice;

  // Real-time validation fields (calculated on the fly for warnings)
  final double? currentSupplierPrice;
  final double? currentSupplierStock;

  const SupplierOrderItem({
    required this.id,
    required this.supplierOrderId,
    this.productId,
    required this.name,
    this.brand,
    this.model,
    required this.uom,
    required this.quantity,
    required this.unitPrice,
    this.currentSupplierPrice,
    this.currentSupplierStock,
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

  @override
  List<Object?> get props => [
    id,
    supplierOrderId,
    productId,
    name,
    brand,
    model,
    uom,
    quantity,
    unitPrice,
    currentSupplierPrice,
    currentSupplierStock,
  ];
}
