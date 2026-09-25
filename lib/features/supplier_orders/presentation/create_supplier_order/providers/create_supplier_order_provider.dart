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
  final SupplierOrder? initialOrder;
  final List<SupplierOrderItem>? initialItems;

  // Dropshipping & Recipient fields
  final bool isDropshipping;
  final String? clientId;
  final String? recipientName;
  final String? recipientContactName;
  final String? recipientAddress;
  final String? recipientPhone;
  final String? deliveryInstructions;

  // For UI display
  final String? supplierName;
  final String? branchName;
  final String? shippingMethodLabel;
  final String? receiverName;
  final String? currentOrderNumber;

  final String? quoteId;

  CreateSupplierOrderState({
    this.id,
    this.quoteId,
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
    this.initialOrder,
    this.initialItems,
    bool? isDirty,
    this.isDropshipping = false,
    this.clientId,
    this.recipientName,
    this.recipientContactName,
    this.recipientAddress,
    this.recipientPhone,
    this.deliveryInstructions,
  }) : date = date ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get tax => subtotal * (taxRate / 100);
  double get total => subtotal + tax;

  bool isDetailsValid({bool hasBranches = false}) {
    final hasSupplier = supplierId != null && supplierId!.isNotEmpty;
    final hasBranch = !hasBranches ||
        (supplierBranchId != null && supplierBranchId!.isNotEmpty);

    if (isDropshipping) {
      final hasRecipient = (recipientName != null && recipientName!.trim().isNotEmpty) ||
          (clientId != null && clientId!.isNotEmpty);
      final hasAddress = recipientAddress != null && recipientAddress!.trim().isNotEmpty;
      return hasSupplier && hasBranch && hasRecipient && hasAddress;
    }

    final hasShipping =
        shippingMethodId != null && shippingMethodId!.isNotEmpty;
    final hasReceiver =
        receiverCollaboratorId != null && receiverCollaboratorId!.isNotEmpty;

    return hasSupplier &&
        hasBranch &&
        hasShipping &&
        hasReceiver;
  }

  bool get hasChanges {
    if (initialOrder == null || initialOrder!.id.isEmpty) {
      return items.isNotEmpty ||
          (supplierId != null && supplierId!.isNotEmpty) ||
          isDropshipping ||
          (clientId != null && clientId!.isNotEmpty);
    }

    if (supplierId != initialOrder!.supplierId) return true;
    if (supplierBranchId != initialOrder!.supplierBranchId) return true;
    if (shippingMethodId != initialOrder!.shippingMethodId) return true;
    if (receiverCollaboratorId != initialOrder!.receiverCollaboratorId) return true;
    if (paymentMethod != initialOrder!.paymentMethod) return true;
    if (quoteId != initialOrder!.quoteId) return true;
    if (isDropshipping != initialOrder!.isDropshipping) return true;
    if (clientId != initialOrder!.clientId) return true;
    if (recipientName != initialOrder!.recipientName) return true;
    if (recipientAddress != initialOrder!.recipientAddress) return true;
    if (recipientPhone != initialOrder!.recipientPhone) return true;
    if (deliveryInstructions != initialOrder!.deliveryInstructions) return true;

    if (date.year != initialOrder!.date.year ||
        date.month != initialOrder!.date.month ||
        date.day != initialOrder!.date.day) {
      return true;
    }

    final origTaxRate = initialOrder!.tax == 0.0
        ? 0.0
        : (initialOrder!.subtotal > 0
            ? (initialOrder!.tax / initialOrder!.subtotal) * 100
            : 0.0);
    if ((taxRate - origTaxRate).abs() > 0.001) return true;

    final origItems = initialItems ?? initialOrder!.items ?? [];
    if (items.length != origItems.length) return true;

    final origMap = <String, SupplierOrderItem>{};
    for (final op in origItems) {
      final key = op.id.isNotEmpty
          ? op.id
          : '${op.productId}_${op.supplierBranchStockId}_${op.name}';
      origMap[key] = op;
    }

    for (final p in items) {
      final key = p.id.isNotEmpty
          ? p.id
          : '${p.productId}_${p.supplierBranchStockId}_${p.name}';
      final op = origMap[key];
      if (op == null) return true;
      if (p.productId != op.productId ||
          p.quantity != op.quantity ||
          p.unitPrice != op.unitPrice ||
          p.name != op.name ||
          p.brand != op.brand ||
          p.model != op.model ||
          p.uom != op.uom ||
          p.supplierBranchStockId != op.supplierBranchStockId) {
        return true;
      }
    }

    return false;
  }

  bool get isDirty => hasChanges;

  CreateSupplierOrderState copyWith({
    String? id,
    String? quoteId,
    bool clearQuoteId = false,
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
    SupplierOrder? initialOrder,
    List<SupplierOrderItem>? initialItems,
    bool? isDirty,
    String? supplierName,
    String? branchName,
    String? shippingMethodLabel,
    String? receiverName,
    String? currentOrderNumber,
    bool? isDropshipping,
    String? clientId,
    String? recipientName,
    String? recipientContactName,
    String? recipientAddress,
    String? recipientPhone,
    String? deliveryInstructions,
  }) {
    return CreateSupplierOrderState(
      id: id ?? this.id,
      quoteId: clearQuoteId ? null : (quoteId ?? this.quoteId),
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
      initialOrder: initialOrder ?? this.initialOrder,
      initialItems: initialItems ?? this.initialItems,
      supplierName: supplierName ?? this.supplierName,
      branchName: branchName ?? this.branchName,
      shippingMethodLabel: shippingMethodLabel ?? this.shippingMethodLabel,
      receiverName: receiverName ?? this.receiverName,
      currentOrderNumber: currentOrderNumber ?? this.currentOrderNumber,
      isDropshipping: isDropshipping ?? this.isDropshipping,
      clientId: clientId ?? this.clientId,
      recipientName: recipientName ?? this.recipientName,
      recipientContactName: recipientContactName ?? this.recipientContactName,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
    );
  }

  Map<String, dynamic> toDraftJson() {
    return {
      'id': id,
      'quote_id': quoteId,
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
      'is_dropshipping': isDropshipping,
      'client_id': clientId,
      'recipient_name': recipientName,
      'recipient_contact_name': recipientContactName,
      'recipient_address': recipientAddress,
      'recipient_phone': recipientPhone,
      'delivery_instructions': deliveryInstructions,
    };
  }

  factory CreateSupplierOrderState.fromDraftJson(Map<String, dynamic> json) {
    return CreateSupplierOrderState(
      id: json['id'] as String?,
      quoteId: json['quote_id'] as String?,
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
      isDropshipping: json['is_dropshipping'] as bool? ?? false,
      clientId: json['client_id'] as String?,
      recipientName: json['recipient_name'] as String?,
      recipientContactName: json['recipient_contact_name'] as String?,
      recipientAddress: json['recipient_address'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
      deliveryInstructions: json['delivery_instructions'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    quoteId,
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
    initialOrder,
    initialItems,
    isDirty,
    supplierName,
    branchName,
    shippingMethodLabel,
    receiverName,
    currentOrderNumber,
    isDropshipping,
    clientId,
    recipientName,
    recipientContactName,
    recipientAddress,
    recipientPhone,
    deliveryInstructions,
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
      final hasData = state.items.isNotEmpty ||
          (state.supplierId != null && state.supplierId!.isNotEmpty);

      if (!hasData) return;
    }

    final key = _getDraftKey(orderId: orderId);
    final draft = DraftData(
      moduleKey: key,
      savedAt: DateTime.now(),
      tabIndex: tabIndex,
      summaryTitle:
          state.supplierName != null && state.supplierName!.isNotEmpty
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
      final hasData = state.items.isNotEmpty ||
          (state.supplierId != null && state.supplierId!.isNotEmpty);

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

  Future<DraftData?> checkAndRestoreDraft({
    String? orderId,
    SupplierOrder? originalOrder,
    List<SupplierOrderItem>? originalItems,
  }) async {
    final key = _getDraftKey(orderId: orderId);
    final draft = await _draftStorage.getDraft(key);
    if (draft != null && draft.data.isNotEmpty) {
      final restored = CreateSupplierOrderState.fromDraftJson(draft.data);
      state = restored.copyWith(
        initialOrder: originalOrder ?? state.initialOrder,
        initialItems: originalItems ?? state.initialItems,
      );
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
      state = state.copyWith(
        taxRate: params.taxRate,
        paymentMethod: state.paymentMethod ?? params.defaultPaymentMethod,
      );
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
      quoteId: order.quoteId,
      supplierId: order.supplierId,
      supplierBranchId: order.supplierBranchId,
      shippingMethodId: order.shippingMethodId,
      receiverCollaboratorId: order.receiverCollaboratorId,
      date: order.date,
      paymentMethod: order.paymentMethod,
      taxRate: order.tax == 0.0
          ? 0.0
          : (order.subtotal > 0 ? (order.tax / order.subtotal) * 100 : 0.0),
      items: List<SupplierOrderItem>.from(items),
      supplierName: order.supplierName,
      branchName: order.branchName,
      shippingMethodLabel: order.shippingMethodLabel,
      receiverName: order.receiverName,
      currentOrderNumber: order.orderNumber,
      initialOrder: order,
      initialItems: List<SupplierOrderItem>.from(items),
      isDropshipping: order.isDropshipping,
      clientId: order.clientId,
      recipientName: order.recipientName,
      recipientContactName: order.recipientContactName,
      recipientAddress: order.recipientAddress,
      recipientPhone: order.recipientPhone,
      deliveryInstructions: order.deliveryInstructions,
    );
  }

  void setQuoteId(String? quoteId) {
    if (quoteId == null) {
      state = state.copyWith(clearQuoteId: true);
    } else {
      state = state.copyWith(quoteId: quoteId);
    }
    autoSaveDraft();
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
        quoteId: source.order.quoteId,
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
          currentSupplierPrice: item.currentSupplierPrice,
          currentSupplierStock: item.currentSupplierStock,
          supplierBranchStockId: item.supplierBranchStockId,
          branchName: item.branchName,
        )).toList(),
        supplierName: source.order.supplierName,
        branchName: source.order.branchName,
        shippingMethodLabel: source.order.shippingMethodLabel,
        receiverName: source.order.receiverName,
        currentOrderNumber: newNumber,
        isDropshipping: source.order.isDropshipping,
        clientId: source.order.clientId,
        recipientName: source.order.recipientName,
        recipientContactName: source.order.recipientContactName,
        recipientAddress: source.order.recipientAddress,
        recipientPhone: source.order.recipientPhone,
        deliveryInstructions: source.order.deliveryInstructions,
      );

      // Sincronizar borrador: limpiar borrador huérfano y auto-guardar copia
      await clearDraft();
      autoSaveDraft();
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

  void setIsDropshipping(bool value) {
    state = state.copyWith(
      isDropshipping: value,
      isDirty: true,
    );
    autoSaveDraft();
  }

  void setRecipientClient({
    required String? clientId,
    required String? name,
    String? contactName,
    String? address,
    String? phone,
  }) {
    state = state.copyWith(
      clientId: clientId,
      recipientName: name,
      recipientContactName: contactName,
      recipientAddress: address,
      recipientPhone: phone,
      isDirty: true,
    );
    autoSaveDraft();
  }

  void setRecipientContactName(String? contactName) {
    state = state.copyWith(recipientContactName: contactName, isDirty: true);
    autoSaveDraft();
  }

  void setRecipientAddress(String address) {
    state = state.copyWith(recipientAddress: address, isDirty: true);
    autoSaveDraft();
  }

  void setRecipientPhone(String phone) {
    state = state.copyWith(recipientPhone: phone, isDirty: true);
    autoSaveDraft();
  }

  void setDeliveryInstructions(String instructions) {
    state = state.copyWith(deliveryInstructions: instructions, isDirty: true);
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
        quoteId: state.quoteId,
        orderNumber: state.currentOrderNumber ?? '',
        date: state.date,
        paymentMethod: state.paymentMethod,
        status: SupplierOrderStatus.draft,
        subtotal: subtotal,
        tax: tax,
        total: total,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDropshipping: state.isDropshipping,
        clientId: state.clientId,
        recipientName: state.recipientName,
        recipientContactName: state.recipientContactName,
        recipientAddress: state.recipientAddress,
        recipientPhone: state.recipientPhone,
        deliveryInstructions: state.deliveryInstructions,
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
      state = state.copyWith(
        isLoading: false,
        initialOrder: order,
        initialItems: List<SupplierOrderItem>.from(state.items),
      );
      return orderId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}
