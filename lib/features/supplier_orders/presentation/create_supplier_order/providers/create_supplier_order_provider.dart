import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/supplier_order.dart';
import '../../../domain/models/supplier_order_item.dart';
import '../../../domain/models/supplier_order_status.dart';
import '../../supplier_orders_list/providers/supplier_orders_providers.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';

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
  final String? currentOrderNumber;

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
    this.currentOrderNumber,
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
    String? currentOrderNumber,
  }) {
    return CreateSupplierOrderState(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierBranchId: supplierBranchId ?? this.supplierBranchId,
      shippingMethodId: shippingMethodId ?? this.shippingMethodId,
      receiverCollaboratorId:
          receiverCollaboratorId ?? this.receiverCollaboratorId,
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
      currentOrderNumber: currentOrderNumber ?? this.currentOrderNumber,
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
    currentOrderNumber,
  ];
}

@Riverpod(keepAlive: true)
class CreateSupplierOrder extends _$CreateSupplierOrder {
  @override
  CreateSupplierOrderState build() {
    return CreateSupplierOrderState();
  }

  Future<void> fetchNextOrderNumber() async {
    try {
      final repo = ref.read(supplierOrdersRepositoryProvider);
      final lastNumber = await repo.getLastOrderNumber();
      final nextNumber = _generateNextOrderNumber(lastNumber);
      state = state.copyWith(currentOrderNumber: nextNumber);
    } catch (e) {
      state = state.copyWith(error: 'Error al generar número: $e');
    }
  }

  String _generateNextOrderNumber(String? lastNumber) {
    if (lastNumber == null) return 'OC-000001';

    final digitsMatch = RegExp(r'\d+').firstMatch(lastNumber);
    if (digitsMatch == null) return 'OC-000001';

    final numericPart = digitsMatch.group(0)!;
    final nextInt = int.parse(numericPart) + 1;

    return 'OC-${nextInt.toString().padLeft(6, '0')}';
  }

  Future<void> loadFinancialParameters() async {
    try {
      final quotesRepo = ref.read(quotesRepositoryProvider);
      final params = await quotesRepo.getFinancialParameters();
      state = state.copyWith(taxRate: params.taxRate);
    } catch (e) {
      state = state.copyWith(taxRate: 0.0);
    }
  }

  Future<void> initializeNew({
    required String supplierId,
    String? supplierName,
    String? branchId,
    String? branchName,
  }) async {
    state = CreateSupplierOrderState(
      supplierId: supplierId,
      supplierName: supplierName,
      supplierBranchId: branchId,
      branchName: branchName,
    );
    await fetchNextOrderNumber();
    await loadFinancialParameters();
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
      currentOrderNumber: order.orderNumber,
    );
  }

  Future<void> loadSupplierOrderAsCopy(String sourceOrderId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final repo = ref.read(supplierOrdersRepositoryProvider);
      final source = await repo.getSupplierOrderDetails(sourceOrderId);
      final lastNumber = await repo.getLastOrderNumber();
      final newNumber = _generateNextOrderNumber(lastNumber);

      await loadFinancialParameters();

      state = CreateSupplierOrderState(
        id: null, // New order copy
        supplierId: source.order.supplierId,
        supplierBranchId: source.order.supplierBranchId,
        shippingMethodId: source.order.shippingMethodId,
        receiverCollaboratorId: source.order.receiverCollaboratorId,
        date: DateTime.now(),
        paymentMethod: source.order.paymentMethod,
        taxRate: state.taxRate,
        items: source.items.map((item) => SupplierOrderItem(
          id: const Uuid().v4(),
          supplierOrderId: '',
          productId: item.productId,
          name: item.name,
          brand: item.brand,
          model: item.model,
          uom: item.uom,
          uomIconName: item.uomIconName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          supplierBranchStockId: item.supplierBranchStockId,
          currentSupplierStock: item.currentSupplierStock,
        )).toList(),
        supplierName: source.order.supplierName,
        branchName: source.order.branchName,
        shippingMethodLabel: source.order.shippingMethodLabel,
        receiverName: source.order.receiverName,
        currentOrderNumber: newNumber,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSupplier(String id, String name) {
    if (state.supplierId != id) {
      state = state.copyWith(
        supplierId: id,
        supplierName: name,
        supplierBranchId: null, // Limpiar sucursal anterior ya que pertenece a otro proveedor
        branchName: null,
        items: const [],        // Vaciar la lista de ítems para evitar inconsistencias
      );
    }
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
    String? uomIconName,
    required double quantity,
    required double unitPrice,
    String? supplierBranchStockId,
    double? currentSupplierStock,
  }) {
    final newItem = SupplierOrderItem(
      id: const Uuid().v4(),
      supplierOrderId: state.id ?? '',
      productId: productId,
      name: name,
      brand: brand,
      model: model,
      uom: uom,
      uomIconName: uomIconName,
      quantity: quantity,
      unitPrice: unitPrice,
      supplierBranchStockId: supplierBranchStockId,
      currentSupplierStock: currentSupplierStock,
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  void updateItem(
    String itemId, {
    double? quantity,
    double? unitPrice,
    String? supplierBranchStockId,
    double? currentSupplierStock,
  }) {
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
            uomIconName: item.uomIconName,
            quantity: quantity ?? item.quantity,
            unitPrice: unitPrice ?? item.unitPrice,
            supplierBranchStockId:
                supplierBranchStockId ?? item.supplierBranchStockId,
            currentSupplierStock:
                currentSupplierStock ?? item.currentSupplierStock,
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

  void replaceProductItems(String productKey, List<SupplierOrderItem> newItems) {
    state = state.copyWith(
      items: [
        ...state.items.where((item) {
          final key = "${item.name}|${item.brand ?? ''}|${item.model ?? ''}";
          return key != productKey;
        }),
        ...newItems,
      ],
    );
  }

  void updateGroupQuantity(String productKey, double newTotalQty) {
    final groupItems = state.items.where((item) {
      final key = "${item.name}|${item.brand ?? ''}|${item.model ?? ''}";
      return key == productKey;
    }).toList();

    if (groupItems.isEmpty) return;

    final currentTotal = groupItems.fold(0.0, (sum, item) => sum + item.quantity);
    if (currentTotal == newTotalQty) return;

    List<SupplierOrderItem> updatedGroupItems = [];

    if (newTotalQty > currentTotal) {
      final sortedItems = List<SupplierOrderItem>.from(groupItems)
        ..sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
      
      final diff = newTotalQty - currentTotal;
      final cheapest = sortedItems.first;
      final updatedCheapest = SupplierOrderItem(
        id: cheapest.id,
        supplierOrderId: cheapest.supplierOrderId,
        productId: cheapest.productId,
        name: cheapest.name,
        brand: cheapest.brand,
        model: cheapest.model,
        uom: cheapest.uom,
        uomIconName: cheapest.uomIconName,
        quantity: cheapest.quantity + diff,
        unitPrice: cheapest.unitPrice,
        currentSupplierPrice: cheapest.currentSupplierPrice,
        currentSupplierStock: cheapest.currentSupplierStock,
        supplierBranchStockId: cheapest.supplierBranchStockId,
      );

      updatedGroupItems = sortedItems.map((item) {
        return item.id == cheapest.id ? updatedCheapest : item;
      }).toList();
    } else {
      final sortedItems = List<SupplierOrderItem>.from(groupItems)
        ..sort((a, b) => b.unitPrice.compareTo(a.unitPrice));

      double diff = currentTotal - newTotalQty;
      final List<SupplierOrderItem> results = [];

      for (final item in sortedItems) {
        if (diff <= 0) {
          results.add(item);
        } else if (item.quantity > diff) {
          results.add(SupplierOrderItem(
            id: item.id,
            supplierOrderId: item.supplierOrderId,
            productId: item.productId,
            name: item.name,
            brand: item.brand,
            model: item.model,
            uom: item.uom,
            uomIconName: item.uomIconName,
            quantity: item.quantity - diff,
            unitPrice: item.unitPrice,
            currentSupplierPrice: item.currentSupplierPrice,
            currentSupplierStock: item.currentSupplierStock,
            supplierBranchStockId: item.supplierBranchStockId,
          ));
          diff = 0;
        } else {
          diff -= item.quantity;
        }
      }

      updatedGroupItems = results;
    }

    state = state.copyWith(
      items: [
        ...state.items.where((item) {
          final key = "${item.name}|${item.brand ?? ''}|${item.model ?? ''}";
          return key != productKey;
        }),
        ...updatedGroupItems,
      ],
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
      ref.invalidate(paginatedSupplierOrderSearchProvider);
      if (state.id != null) {
        ref.invalidate(supplierOrderDetailProvider(state.id!));
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
