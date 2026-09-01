import 'package:d_una_app/core/constants/draft_constants.dart';
import 'package:d_una_app/core/models/draft_data.dart';
import 'package:d_una_app/core/services/draft_storage_service.dart';
import 'package:d_una_app/core/providers/draft_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/supplier_order.dart';
import '../../../domain/models/supplier_order_item.dart';
import '../../../domain/models/supplier_order_status.dart';
import '../../supplier_orders_list/providers/supplier_orders_providers.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/core/utils/country_iso_codes.dart';

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
  final bool isDirty;

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
    this.isDirty = false,
    this.supplierName,
    this.branchName,
    this.shippingMethodLabel,
    this.receiverName,
    this.currentOrderNumber,
  }) : date = date ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get tax => subtotal * (taxRate / 100);
  double get total => subtotal + tax;

  bool isDetailsValid({bool hasBranches = false}) {
    final hasSupplier = supplierId != null && supplierId!.isNotEmpty;
    final hasBranch = !hasBranches ||
        (supplierBranchId != null && supplierBranchId!.isNotEmpty);
    final hasShipping =
        shippingMethodId != null && shippingMethodId!.isNotEmpty;
    final hasReceiver =
        receiverCollaboratorId != null && receiverCollaboratorId!.isNotEmpty;
    final hasPayment = paymentMethod != null && paymentMethod!.isNotEmpty;

    return hasSupplier &&
        hasBranch &&
        hasShipping &&
        hasReceiver &&
        hasPayment;
  }

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
    bool? isDirty,
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
      isDirty: isDirty ?? this.isDirty,
      supplierName: supplierName ?? this.supplierName,
      branchName: branchName ?? this.branchName,
      shippingMethodLabel: shippingMethodLabel ?? this.shippingMethodLabel,
      receiverName: receiverName ?? this.receiverName,
      currentOrderNumber: currentOrderNumber ?? this.currentOrderNumber,
    );
  }

  Map<String, dynamic> toDraftJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'supplier_branch_id': supplierBranchId,
      'shipping_method_id': shippingMethodId,
      'receiver_collaborator_id': receiverCollaboratorId,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      'tax_rate': taxRate,
      'items': items.map((i) => i.toJson()).toList(),
      'supplier_name': supplierName,
      'branch_name': branchName,
      'shipping_method_label': shippingMethodLabel,
      'receiver_name': receiverName,
      'current_order_number': currentOrderNumber,
    };
  }

  factory CreateSupplierOrderState.fromDraftJson(Map<String, dynamic> json) {
    return CreateSupplierOrderState(
      id: json['id'] as String?,
      supplierId: json['supplier_id'] as String?,
      supplierBranchId: json['supplier_branch_id'] as String?,
      shippingMethodId: json['shipping_method_id'] as String?,
      receiverCollaboratorId: json['receiver_collaborator_id'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      paymentMethod: json['payment_method'] as String?,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      items: (json['items'] as List? ?? [])
          .map((i) => SupplierOrderItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      supplierName: json['supplier_name'] as String?,
      branchName: json['branch_name'] as String?,
      shippingMethodLabel: json['shipping_method_label'] as String?,
      receiverName: json['receiver_name'] as String?,
      currentOrderNumber: json['current_order_number'] as String?,
      isDirty: true,
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
    isDirty,
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

  DraftStorageService get _draftStorage =>
      ref.read(draftStorageServiceProvider);

  String _getDraftKey({String? orderId}) {
    if (orderId != null && orderId.isNotEmpty) {
      return '${DraftConstants.supplierOrdersModule}_$orderId';
    }
    if (state.id != null && state.id!.isNotEmpty) {
      return '${DraftConstants.supplierOrdersModule}_${state.id}';
    }
    return DraftConstants.supplierOrdersModule;
  }

  void autoSaveDraft({int tabIndex = 0, String? orderId}) {
    final isEditing =
        (state.id != null && state.id!.isNotEmpty) ||
        (orderId != null && orderId.isNotEmpty);

    if (isEditing) {
      if (!state.isDirty) return;
    } else {
      final hasData =
          state.items.isNotEmpty ||
          state.supplierId != null ||
          state.shippingMethodId != null ||
          state.receiverCollaboratorId != null;

      if (!hasData) return;
    }

    final key = _getDraftKey(orderId: orderId);
    final draft = DraftData(
      moduleKey: key,
      savedAt: DateTime.now(),
      tabIndex: tabIndex,
      summaryTitle:
          state.supplierName != null
              ? '${isEditing ? "Modificación Orden" : "Orden de Compra"} - ${state.supplierName}'
              : 'Orden de Compra',
      data: state.toDraftJson(),
    );
    _draftStorage.saveDraftDebounced(draft);
  }

  Future<void> saveDraftNow({int tabIndex = 0, String? orderId}) async {
    final isEditing =
        (state.id != null && state.id!.isNotEmpty) ||
        (orderId != null && orderId.isNotEmpty);

    if (isEditing) {
      if (!state.isDirty) return;
    } else {
      final hasData =
          state.items.isNotEmpty ||
          state.supplierId != null ||
          state.shippingMethodId != null ||
          state.receiverCollaboratorId != null;

      if (!hasData) return;
    }

    final key = _getDraftKey(orderId: orderId);
    final draft = DraftData(
      moduleKey: key,
      savedAt: DateTime.now(),
      tabIndex: tabIndex,
      summaryTitle:
          state.supplierName != null
              ? '${isEditing ? "Modificación Orden" : "Orden de Compra"} - ${state.supplierName}'
              : 'Orden de Compra',
      data: state.toDraftJson(),
    );
    await _draftStorage.saveDraftNow(draft);
  }

  Future<DraftData?> checkAndRestoreDraft({String? orderId}) async {
    final key = _getDraftKey(orderId: orderId);
    final draft = await _draftStorage.getDraft(key);
    if (draft != null && draft.data.isNotEmpty) {
      state = CreateSupplierOrderState.fromDraftJson(draft.data);
      return draft;
    }
    return null;
  }

  Future<void> clearDraft({String? orderId}) async {
    final key = _getDraftKey(orderId: orderId);
    await _draftStorage.clearDraft(key);
  }

  void reset({bool clearPersistedDraft = false, String? orderId}) {
    final isEditing =
        (state.id != null && state.id!.isNotEmpty) ||
        (orderId != null && orderId.isNotEmpty);
    final currentId = orderId ?? state.id;
    state = CreateSupplierOrderState();
    if (clearPersistedDraft) {
      clearDraft(orderId: isEditing ? currentId : null);
    }
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

  /// Builds the user code: ISO country (2 chars) + hex user number (4 chars, zero-padded).
  /// Example: VE000A (Venezuela, user #10)
  String _getUserCode() {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return 'XX0000';

    final countryCode = CountryIsoCodes.getCode(profile.mainCountry);
    final userNum = profile.userNumber ?? 0;
    final hexPart = userNum.toRadixString(16).toUpperCase().padLeft(4, '0');
    return '$countryCode$hexPart';
  }

  /// Generates the next order number in format: DU-[USER_CODE]-[YY][SEQ]
  /// Generates the next order number in format: OC-[USER_CODE]-[YY][SEQ]
  /// Example: OC-VE000A-26005
  String _generateNextOrderNumber(String? lastNumber) {
    final userCode = _getUserCode();
    final currentYear = DateTime.now().year % 100; // e.g. 26 for 2026
    final yearPrefix = currentYear.toString().padLeft(2, '0');

    int nextSeq = 1;

    if (lastNumber != null) {
      // Format: OC-XXXXXX-YYSEQ
      // Extract the last segment after the final '-'
      final parts = lastNumber.split('-');
      if (parts.length >= 3) {
        final ocPart = parts.last; // e.g. "26005"
        if (ocPart.length == 5) {
          final yearInLast = ocPart.substring(0, 2); // e.g. "26"
          final seqInLast = ocPart.substring(2);     // e.g. "005"
          if (yearInLast == yearPrefix) {
            final parsed = int.tryParse(seqInLast);
            if (parsed != null) {
              nextSeq = parsed + 1;
            }
          }
          // If year is different, nextSeq stays at 1 (new year reset)
        }
      }
    }

    final seqFormatted = nextSeq.toString().padLeft(3, '0');
    return 'OC-$userCode-$yearPrefix$seqFormatted';
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
        supplierBranchId: null,
        branchName: null,
        items: const [],
        isDirty: true,
      );
      autoSaveDraft();
    }
  }

  void setBranch(String? id, String? name) {
    state =
        state.copyWith(supplierBranchId: id, branchName: name, isDirty: true);
    autoSaveDraft();
  }

  void setShippingMethod(String? id, String? label) {
    state = state.copyWith(
      shippingMethodId: id,
      shippingMethodLabel: label,
      isDirty: true,
    );
    autoSaveDraft();
  }

  void setReceiver(String? id, String? name) {
    state = state.copyWith(
      receiverCollaboratorId: id,
      receiverName: name,
      isDirty: true,
    );
    autoSaveDraft();
  }

  void setPaymentMethod(String? method) {
    state = state.copyWith(paymentMethod: method, isDirty: true);
    autoSaveDraft();
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date, isDirty: true);
    autoSaveDraft();
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
    state = state.copyWith(items: [...state.items, newItem], isDirty: true);
    autoSaveDraft();
  }

  void updateItem(
    String itemId, {
    double? quantity,
    double? unitPrice,
    String? supplierBranchStockId,
    double? currentSupplierStock,
  }) {
    state = state.copyWith(
      isDirty: true,
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
    autoSaveDraft();
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      isDirty: true,
      items: state.items.where((item) => item.id != itemId).toList(),
    );
    autoSaveDraft();
  }

  void replaceProductItems(String productKey, List<SupplierOrderItem> newItems) {
    final List<SupplierOrderItem> result = [];
    bool inserted = false;
    for (final item in state.items) {
      final key = "${item.name}|${item.brand ?? ''}|${item.model ?? ''}";
      if (key == productKey) {
        if (!inserted) {
          result.addAll(newItems);
          inserted = true;
        }
      } else {
        result.add(item);
      }
    }
    state = state.copyWith(items: result, isDirty: true);
    autoSaveDraft();
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

    final List<SupplierOrderItem> result = [];
    bool inserted = false;
    for (final item in state.items) {
      final key = "${item.name}|${item.brand ?? ''}|${item.model ?? ''}";
      if (key == productKey) {
        if (!inserted) {
          result.addAll(updatedGroupItems);
          inserted = true;
        }
      } else {
        result.add(item);
      }
    }
    state = state.copyWith(items: result, isDirty: true);
    autoSaveDraft();
  }

  Future<String?> saveOrder() async {
    if (state.supplierId == null) {
      state = state.copyWith(error: 'Debe seleccionar un proveedor');
      return null;
    }
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Debe agregar al menos un producto');
      return null;
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
        orderNumber: state.currentOrderNumber ?? '',
        date: state.date,
        paymentMethod: state.paymentMethod,
        status: SupplierOrderStatus.draft,
        subtotal: subtotal,
        tax: tax,
        total: total,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final wasEditing = state.id != null && state.id!.isNotEmpty;
      final previousOrderId = state.id;

      String orderId;
      if (wasEditing) {
        await repo.updateSupplierOrder(order, state.items);
        orderId = state.id!;
        await clearDraft(orderId: previousOrderId);
      } else {
        orderId = await repo.createSupplierOrder(order, state.items);
        await clearDraft(orderId: null);
      }

      ref.invalidate(paginatedSupplierOrdersProvider);
      ref.invalidate(paginatedSupplierOrderSearchProvider);
      if (state.id != null) {
        ref.invalidate(supplierOrderDetailProvider(state.id!));
      }
      state = state.copyWith(isLoading: false);
      return orderId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}
