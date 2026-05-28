import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/supplier_order.dart';
import '../../domain/models/supplier_order_item.dart';
import '../../domain/models/supplier_order_status.dart';
import 'supplier_orders_providers.dart';

part 'create_supplier_order_provider.g.dart';

class CreateSupplierOrderState extends Equatable {
  final String? id;
  final String? supplierId;
  final String? supplierBranchId;
  final String? shippingMethodId;
  final String? receiverCollaboratorId;
  final DateTime date;
  final String? paymentMethod;
  final double taxRate;
  final List<SupplierOrderItem> items;
  final bool isLoading;
  final String? error;

  // For UI display
  final String? supplierName;
  final String? branchName;
  final String? shippingMethodLabel;
  final String? receiverName;

  CreateSupplierOrderState({
    this.id,
    this.supplierId,
    this.supplierBranchId,
    this.shippingMethodId,
    this.receiverCollaboratorId,
    DateTime? date,
    this.paymentMethod,
    this.taxRate = 0.0,
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.supplierName,
    this.branchName,
    this.shippingMethodLabel,
    this.receiverName,
  }) : date = date ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get tax => subtotal * (taxRate / 100);
  double get total => subtotal + tax;

  CreateSupplierOrderState copyWith({
    String? id,
    String? supplierId,
    String? supplierBranchId,
    String? shippingMethodId,
    String? receiverCollaboratorId,
    DateTime? date,
    String? paymentMethod,
    double? taxRate,
    List<SupplierOrderItem>? items,
    bool? isLoading,
    String? error,
    String? supplierName,
    String? branchName,
    String? shippingMethodLabel,
    String? receiverName,
  }) {
    return CreateSupplierOrderState(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierBranchId: supplierBranchId ?? this.supplierBranchId,
      shippingMethodId: shippingMethodId ?? this.shippingMethodId,
      receiverCollaboratorId: receiverCollaboratorId ?? this.receiverCollaboratorId,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      taxRate: taxRate ?? this.taxRate,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      supplierName: supplierName ?? this.supplierName,
      branchName: branchName ?? this.branchName,
      shippingMethodLabel: shippingMethodLabel ?? this.shippingMethodLabel,
      receiverName: receiverName ?? this.receiverName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        supplierId,
        supplierBranchId,
        shippingMethodId,
        receiverCollaboratorId,
        date.year,
        date.month,
        date.day,
        paymentMethod,
        taxRate,
        items,
        isLoading,
        error,
        supplierName,
        branchName,
        shippingMethodLabel,
        receiverName,
      ];
}

@riverpod
class CreateSupplierOrder extends _$CreateSupplierOrder {
  @override
  CreateSupplierOrderState build() {
    return CreateSupplierOrderState();
  }

  void initializeNew({
    required String supplierId,
    String? supplierName,
    String? branchId,
    String? branchName,
  }) {
    state = CreateSupplierOrderState(
      supplierId: supplierId,
      supplierName: supplierName,
      supplierBranchId: branchId,
      branchName: branchName,
    );
  }

  void loadFromExisting(SupplierOrder order, List<SupplierOrderItem> items) {
    state = CreateSupplierOrderState(
      id: order.id,
      supplierId: order.supplierId,
      supplierBranchId: order.supplierBranchId,
      shippingMethodId: order.shippingMethodId,
      receiverCollaboratorId: order.receiverCollaboratorId,
      date: order.date,
      paymentMethod: order.paymentMethod,
      taxRate: order.tax == 0.0 ? 0.0 : (order.tax / order.subtotal) * 100,
      items: items,
      supplierName: order.supplierName,
      branchName: order.branchName,
      shippingMethodLabel: order.shippingMethodLabel,
      receiverName: order.receiverName,
    );
  }

  void setSupplier(String id, String name) {
    state = state.copyWith(supplierId: id, supplierName: name);
  }

  void setBranch(String? id, String? name) {
    state = state.copyWith(supplierBranchId: id, branchName: name);
  }

  void setShippingMethod(String? id, String? label) {
    state = state.copyWith(shippingMethodId: id, shippingMethodLabel: label);
  }

  void setReceiver(String? id, String? name) {
    state = state.copyWith(receiverCollaboratorId: id, receiverName: name);
  }

  void setPaymentMethod(String? method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void addItem({
    String? productId,
    required String name,
    String? brand,
    String? model,
    required String uom,
    required double quantity,
    required double unitPrice,
  }) {
    final newItem = SupplierOrderItem(
      id: const Uuid().v4(),
      supplierOrderId: state.id ?? '',
      productId: productId,
      name: name,
      brand: brand,
      model: model,
      uom: uom,
      quantity: quantity,
      unitPrice: unitPrice,
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  void updateItem(String itemId, {double? quantity, double? unitPrice}) {
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id == itemId) {
          return SupplierOrderItem(
            id: item.id,
            supplierOrderId: item.supplierOrderId,
            productId: item.productId,
            name: item.name,
            brand: item.brand,
            model: item.model,
            uom: item.uom,
            quantity: quantity ?? item.quantity,
            unitPrice: unitPrice ?? item.unitPrice,
          );
        }
        return item;
      }).toList(),
    );
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != itemId).toList(),
    );
  }

  Future<bool> saveOrder() async {
    if (state.supplierId == null) {
      state = state.copyWith(error: 'Debe seleccionar un proveedor');
      return false;
    }
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Debe agregar al menos un producto');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(supplierOrdersRepositoryProvider);
      
      final subtotal = state.subtotal;
      final tax = state.tax;
      final total = state.total;

      final order = SupplierOrder(
        id: state.id ?? '',
        userId: '', // handled by repository
        supplierId: state.supplierId!,
        supplierBranchId: state.supplierBranchId,
        shippingMethodId: state.shippingMethodId,
        receiverCollaboratorId: state.receiverCollaboratorId,
        orderNumber: '', // auto-generated
        date: state.date,
        paymentMethod: state.paymentMethod,
        status: SupplierOrderStatus.draft,
        subtotal: subtotal,
        tax: tax,
        total: total,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (state.id == null) {
        await repo.createSupplierOrder(order, state.items);
      } else {
        await repo.updateSupplierOrder(order, state.items);
      }

      ref.invalidate(paginatedSupplierOrdersProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
