import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:d_una_app/core/constants/draft_constants.dart';
import 'package:d_una_app/core/models/draft_data.dart';
import 'package:d_una_app/core/services/draft_storage_service.dart';
import 'package:d_una_app/core/providers/draft_providers.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/quotes/data/models/quote.dart';
import 'package:d_una_app/features/quotes/data/models/quote_item_product.dart';
import 'package:d_una_app/features/supplier_orders/domain/models/supplier_order.dart';
import 'package:d_una_app/features/supplier_orders/domain/models/supplier_order_item.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../../../domain/models/delivery_note_status.dart';
import '../../../domain/models/delivery_note_item_model.dart';
import '../../../domain/models/delivery_note_serial_model.dart';
import '../../../domain/models/delivery_note_observation_model.dart';
import '../../../data/repositories/supabase_delivery_notes_repository.dart';

class DeliveryNoteCreateState extends Equatable {
  final String? id;
  final String? deliveryNoteNumber;
  final String? clientId;
  final String? clientName;
  final String? clientTaxId;
  final String? contactId;
  final String? contactName;
  final String? quoteId;
  final String? supplierOrderId;
  final String? clientPoNumber;
  final String? tag;
  final String? notes;
  final DeliveryNoteStatus status;
  final DateTime date;
  final DateTime? deliveryDate;
  final String deliveryType; // 'direct_delivery', 'pickup', 'courier'
  final String? shippingCompanyId;
  final String? shippingCompanyName;
  final String? trackingNumber;
  final String? recipientAddress;
  final String? recipientCity;
  final String? recipientState;
  final String? deliveryInstructions;
  final String? receivedByName;
  final String? receivedById;
  final String? receivedByPhone;
  final String? receiverRelationship;
  final DateTime? receivedAt;
  final String? signatureData;
  final double taxRate;
  final List<DeliveryNoteItemModel> items;
  final List<DeliveryNoteObservationModel> observations;
  final bool isDropshipping;
  final bool isLoading;
  final String? error;
  final bool isDirty;

  DeliveryNoteCreateState({
    this.id,
    this.deliveryNoteNumber,
    this.clientId,
    this.clientName,
    this.clientTaxId,
    this.contactId,
    this.contactName,
    this.quoteId,
    this.supplierOrderId,
    this.clientPoNumber,
    this.tag,
    this.notes,
    this.status = DeliveryNoteStatus.draft,
    DateTime? date,
    this.deliveryDate,
    this.deliveryType = 'direct_delivery',
    this.shippingCompanyId,
    this.shippingCompanyName,
    this.trackingNumber,
    this.recipientAddress,
    this.recipientCity,
    this.recipientState,
    this.deliveryInstructions,
    this.receivedByName,
    this.receivedById,
    this.receivedByPhone,
    this.receiverRelationship,
    this.receivedAt,
    this.signatureData,
    this.taxRate = 0.0,
    this.items = const [],
    this.observations = const [],
    this.isDropshipping = false,
    this.isLoading = false,
    this.error,
    this.isDirty = false,
  }) : date = date ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;
  int get missingSerialsCount =>
      items.fold(0, (sum, i) => sum + i.missingSerialsCount);
  bool get hasMissingSerials => items.any((i) => i.hasMissingSerials);

  bool get isDetailsValid =>
      clientId != null && clientId!.isNotEmpty && clientName != null;

  bool get isDeliveryValid {
    if (deliveryType == 'courier') {
      return shippingCompanyId != null &&
          shippingCompanyId!.isNotEmpty &&
          trackingNumber != null &&
          trackingNumber!.trim().isNotEmpty;
    }
    if (deliveryType == 'direct_delivery') {
      return recipientAddress != null && recipientAddress!.trim().isNotEmpty;
    }
    return true; // 'pickup' is always valid
  }

  DeliveryNoteCreateState copyWith({
    String? id,
    String? deliveryNoteNumber,
    String? clientId,
    String? clientName,
    String? clientTaxId,
    String? contactId,
    String? contactName,
    String? quoteId,
    String? supplierOrderId,
    String? clientPoNumber,
    String? tag,
    String? notes,
    DeliveryNoteStatus? status,
    DateTime? date,
    DateTime? deliveryDate,
    String? deliveryType,
    String? shippingCompanyId,
    String? shippingCompanyName,
    String? trackingNumber,
    String? recipientAddress,
    String? recipientCity,
    String? recipientState,
    String? deliveryInstructions,
    String? receivedByName,
    String? receivedById,
    String? receivedByPhone,
    String? receiverRelationship,
    DateTime? receivedAt,
    String? signatureData,
    double? taxRate,
    List<DeliveryNoteItemModel>? items,
    List<DeliveryNoteObservationModel>? observations,
    bool? isDropshipping,
    bool? isLoading,
    String? error,
    bool? isDirty,
  }) {
    return DeliveryNoteCreateState(
      id: id ?? this.id,
      deliveryNoteNumber: deliveryNoteNumber ?? this.deliveryNoteNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientTaxId: clientTaxId ?? this.clientTaxId,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      quoteId: quoteId ?? this.quoteId,
      supplierOrderId: supplierOrderId ?? this.supplierOrderId,
      clientPoNumber: clientPoNumber ?? this.clientPoNumber,
      tag: tag ?? this.tag,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      date: date ?? this.date,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryType: deliveryType ?? this.deliveryType,
      shippingCompanyId: shippingCompanyId ?? this.shippingCompanyId,
      shippingCompanyName: shippingCompanyName ?? this.shippingCompanyName,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      recipientCity: recipientCity ?? this.recipientCity,
      recipientState: recipientState ?? this.recipientState,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      receivedByName: receivedByName ?? this.receivedByName,
      receivedById: receivedById ?? this.receivedById,
      receivedByPhone: receivedByPhone ?? this.receivedByPhone,
      receiverRelationship: receiverRelationship ?? this.receiverRelationship,
      receivedAt: receivedAt ?? this.receivedAt,
      signatureData: signatureData ?? this.signatureData,
      taxRate: taxRate ?? this.taxRate,
      items: items ?? this.items,
      observations: observations ?? this.observations,
      isDropshipping: isDropshipping ?? this.isDropshipping,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  Map<String, dynamic> toDraftJson() {
    return {
      'id': id,
      'delivery_note_number': deliveryNoteNumber,
      'client_id': clientId,
      'client_name': clientName,
      'client_tax_id': clientTaxId,
      'contact_id': contactId,
      'contact_name': contactName,
      'quote_id': quoteId,
      'supplier_order_id': supplierOrderId,
      'client_po_number': clientPoNumber,
      'tag': tag,
      'notes': notes,
      'status': status.dbValue,
      'date': date.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'delivery_type': deliveryType,
      'shipping_company_id': shippingCompanyId,
      'shipping_company_name': shippingCompanyName,
      'tracking_number': trackingNumber,
      'recipient_address': recipientAddress,
      'recipient_city': recipientCity,
      'recipient_state': recipientState,
      'delivery_instructions': deliveryInstructions,
      'tax_rate': taxRate,
      'is_dropshipping': isDropshipping,
      'items': items.map((i) => i.toJson()).toList(),
      'observations': observations.map((o) => o.toJson()).toList(),
    };
  }

  factory DeliveryNoteCreateState.fromDraftJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((i) => DeliveryNoteItemModel.fromJson(i as Map<String, dynamic>))
        .toList();

    final rawObs = json['observations'] as List<dynamic>? ?? [];
    final obsList = rawObs
        .map((o) => DeliveryNoteObservationModel.fromJson(o as Map<String, dynamic>))
        .toList();

    return DeliveryNoteCreateState(
      id: json['id'] as String?,
      deliveryNoteNumber: json['delivery_note_number'] as String?,
      clientId: json['client_id'] as String?,
      clientName: json['client_name'] as String?,
      clientTaxId: json['client_tax_id'] as String?,
      contactId: json['contact_id'] as String?,
      contactName: json['contact_name'] as String?,
      quoteId: json['quote_id'] as String?,
      supplierOrderId: json['supplier_order_id'] as String?,
      clientPoNumber: json['client_po_number'] as String?,
      tag: json['tag'] as String?,
      notes: json['notes'] as String?,
      status: DeliveryNoteStatus.fromDbValue(json['status'] as String? ?? 'draft'),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.tryParse(json['delivery_date'] as String)
          : null,
      deliveryType: json['delivery_type'] as String? ?? 'direct_delivery',
      shippingCompanyId: json['shipping_company_id'] as String?,
      shippingCompanyName: json['shipping_company_name'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      recipientAddress: json['recipient_address'] as String?,
      recipientCity: json['recipient_city'] as String?,
      recipientState: json['recipient_state'] as String?,
      deliveryInstructions: json['delivery_instructions'] as String?,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      isDropshipping: json['is_dropshipping'] == true,
      items: itemsList,
      observations: obsList,
      isDirty: true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    deliveryNoteNumber,
    clientId,
    clientName,
    contactId,
    quoteId,
    supplierOrderId,
    clientPoNumber,
    tag,
    notes,
    status,
    date.year,
    date.month,
    date.day,
    deliveryDate?.year,
    deliveryDate?.month,
    deliveryDate?.day,
    deliveryType,
    shippingCompanyId,
    trackingNumber,
    recipientAddress,
    recipientCity,
    recipientState,
    deliveryInstructions,
    receivedByName,
    receivedById,
    signatureData,
    taxRate,
    items,
    observations,
    isDropshipping,
    isLoading,
    error,
    isDirty,
  ];
}

final createDeliveryNoteProvider =
    StateNotifierProvider.autoDispose<CreateDeliveryNoteNotifier, DeliveryNoteCreateState>((
  ref,
) {
  return CreateDeliveryNoteNotifier(ref);
});

class CreateDeliveryNoteNotifier
    extends StateNotifier<DeliveryNoteCreateState> {
  final Ref ref;

  CreateDeliveryNoteNotifier(this.ref) : super(DeliveryNoteCreateState()) {
    _initDefaults();
  }

  DraftStorageService get _draftStorage =>
      ref.read(draftStorageServiceProvider);

  String _getDraftKey({String? noteId}) {
    if (noteId != null && noteId.isNotEmpty) {
      return '${DraftConstants.deliveryNotesModule}_$noteId';
    }
    if (state.id != null && state.id!.isNotEmpty) {
      return '${DraftConstants.deliveryNotesModule}_${state.id}';
    }
    return DraftConstants.deliveryNotesModule;
  }

  Future<void> _initDefaults() async {
    // Load default commercial conditions if available
    try {
      final conditions = await ref.read(commercialConditionsProvider.future);
      final defaultConditions = conditions
          .where((c) => c.isDefaultReport || c.isDefaultQuote)
          .map((c) => DeliveryNoteObservationModel(
                description: c.description,
                observationId: c.id,
              ))
          .toList();

      if (defaultConditions.isNotEmpty && state.observations.isEmpty) {
        state = state.copyWith(observations: defaultConditions);
      }
    } catch (_) {}

    // Fetch next number preview
    try {
      final repo = ref.read(deliveryNotesRepositoryProvider);
      final lastNum = await repo.getLastDeliveryNoteNumber();
      if (lastNum != null && state.deliveryNoteNumber == null) {
        state = state.copyWith(deliveryNoteNumber: 'NE-... (Autogenerado)');
      }
    } catch (_) {}
  }

  void autoSaveDraft({int tabIndex = 0, String? noteId}) {
    final isEditing =
        (state.id != null && state.id!.isNotEmpty) ||
        (noteId != null && noteId.isNotEmpty);

    if (isEditing) {
      if (!state.isDirty) return;
    } else {
      final hasData =
          state.items.isNotEmpty ||
          state.clientId != null ||
          state.recipientAddress != null ||
          (state.notes != null && state.notes!.trim().isNotEmpty);

      if (!hasData) return;
    }

    final key = _getDraftKey(noteId: noteId);
    final draft = DraftData(
      moduleKey: key,
      savedAt: DateTime.now(),
      tabIndex: tabIndex,
      summaryTitle: state.clientName != null
          ? '${isEditing ? "Modificación Nota" : "Nota de Entrega"} - ${state.clientName}'
          : 'Nota de Entrega',
      data: state.toDraftJson(),
    );
    _draftStorage.saveDraftDebounced(draft);
  }

  Future<void> saveDraftNow({int tabIndex = 0, String? noteId}) async {
    final isEditing =
        (state.id != null && state.id!.isNotEmpty) ||
        (noteId != null && noteId.isNotEmpty);

    if (isEditing) {
      if (!state.isDirty) return;
    } else {
      final hasData =
          state.items.isNotEmpty ||
          state.clientId != null ||
          state.recipientAddress != null ||
          (state.notes != null && state.notes!.trim().isNotEmpty);

      if (!hasData) return;
    }

    final key = _getDraftKey(noteId: noteId);
    final draft = DraftData(
      moduleKey: key,
      savedAt: DateTime.now(),
      tabIndex: tabIndex,
      summaryTitle: state.clientName != null
          ? '${isEditing ? "Modificación Nota" : "Nota de Entrega"} - ${state.clientName}'
          : 'Nota de Entrega',
      data: state.toDraftJson(),
    );
    await _draftStorage.saveDraftNow(draft);
  }

  void restoreDraft(DraftData draft) {
    state = DeliveryNoteCreateState.fromDraftJson(draft.data);
  }

  Future<void> discardDraft({String? noteId}) async {
    final key = _getDraftKey(noteId: noteId);
    await _draftStorage.clearDraft(key);
  }

  Future<DraftData?> checkExistingDraft({String? noteId}) async {
    final key = _getDraftKey(noteId: noteId);
    return _draftStorage.getDraft(key);
  }

  // Load from quote
  void loadFromQuote(Quote quote, {List<QuoteItemProduct>? filteredItems}) {
    final itemsToUse = filteredItems ?? (quote.products ?? []);
    final convertedItems = itemsToUse.map((p) {
      return DeliveryNoteItemModel(
        id: '',
        deliveryNoteId: '',
        productId: p.productId,
        name: p.name,
        brand: p.brand,
        model: p.model,
        uom: p.uom,
        description: p.description,
        quantity: p.quantity,
        unitPrice: p.unitPrice,
        taxRate: p.taxRate,
        taxAmount: p.taxAmount,
        totalPrice: p.totalPrice,
        warrantyTime: p.warrantyTime,
        warrantyUnit: p.warrantyUnit,
        sourceType: p.sourceType == QuoteItemSourceType.affiliated
            ? 'affiliated'
            : (p.sourceType == QuoteItemSourceType.external ? 'external' : 'own'),
        requiresSerials: false,
        isDropshipping: false,
      );
    }).toList();

    state = state.copyWith(
      quoteId: quote.id,
      clientId: quote.clientId,
      clientName: quote.clientName,
      clientTaxId: quote.clientTaxId,
      contactId: quote.contactId,
      contactName: quote.contactName,
      recipientAddress: state.recipientAddress ?? quote.clientAddress,
      recipientCity: state.recipientCity ?? quote.clientCity,
      recipientState: state.recipientState ?? quote.clientState,
      items: convertedItems,
      isDirty: true,
    );
  }

  // Load from supplier order
  void loadFromSupplierOrder(SupplierOrder order, [List<SupplierOrderItem>? items]) {
    final itemsList = items ?? order.items ?? [];
    final convertedItems = itemsList.map((i) {
      return DeliveryNoteItemModel(
        id: '',
        deliveryNoteId: '',
        productId: i.productId,
        name: i.name,
        brand: i.brand,
        model: i.model,
        uom: i.uom,
        quantity: i.quantity,
        unitPrice: i.unitPrice,
        totalPrice: i.quantity * i.unitPrice,
        sourceType: 'affiliated',
        requiresSerials: false,
        isDropshipping: true,
      );
    }).toList();

    state = state.copyWith(
      supplierOrderId: order.id,
      quoteId: order.quoteId,
      items: convertedItems,
      isDropshipping: true,
      isDirty: true,
    );
  }

  // Load existing note for editing
  void loadExistingDeliveryNote(DeliveryNoteModel note) {
    state = DeliveryNoteCreateState(
      id: note.id,
      deliveryNoteNumber: note.deliveryNoteNumber,
      clientId: note.clientId,
      clientName: note.clientName,
      clientTaxId: note.clientTaxId,
      contactId: note.contactId,
      contactName: note.contactName,
      quoteId: note.quoteId,
      supplierOrderId: note.supplierOrderId,
      clientPoNumber: note.clientPoNumber,
      tag: note.tag,
      notes: note.notes,
      status: note.status,
      date: note.date,
      deliveryDate: note.deliveryDate,
      deliveryType: note.deliveryType,
      shippingCompanyId: note.shippingCompanyId,
      shippingCompanyName: note.shippingCompanyName,
      trackingNumber: note.trackingNumber,
      recipientAddress: note.recipientAddress,
      recipientCity: note.recipientCity,
      recipientState: note.recipientState,
      deliveryInstructions: note.deliveryInstructions,
      receivedByName: note.receivedByName,
      receivedById: note.receivedById,
      receivedByPhone: note.receivedByPhone,
      receiverRelationship: note.receiverRelationship,
      receivedAt: note.receivedAt,
      signatureData: note.signatureData,
      taxRate: note.taxRate,
      items: note.items,
      observations: note.observations,
      isDropshipping: note.isDropshipping,
      isDirty: false,
    );
  }

  // Client and header setters
  void setClient(Client client, {String? contactId, String? contactName}) {
    state = state.copyWith(
      clientId: client.id,
      clientName: client.name,
      clientTaxId: client.taxId,
      contactId: contactId,
      contactName: contactName,
      recipientAddress: state.recipientAddress ?? client.address,
      recipientCity: state.recipientCity ?? client.city,
      recipientState: state.recipientState ?? client.state,
      isDirty: true,
    );
  }

  void setContact(String? contactId, String? contactName) {
    state = state.copyWith(
      contactId: contactId,
      contactName: contactName,
      isDirty: true,
    );
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date, isDirty: true);
  }

  void setDeliveryDate(DateTime? date) {
    state = state.copyWith(deliveryDate: date, isDirty: true);
  }

  void setDeliveryType(String type) {
    state = state.copyWith(deliveryType: type, isDirty: true);
  }

  void setShippingInfo({
    String? shippingCompanyId,
    String? shippingCompanyName,
    String? trackingNumber,
  }) {
    state = state.copyWith(
      shippingCompanyId: shippingCompanyId,
      shippingCompanyName: shippingCompanyName,
      trackingNumber: trackingNumber,
      isDirty: true,
    );
  }

  void setRecipientAddress({
    String? address,
    String? city,
    String? stateName,
    String? instructions,
  }) {
    state = state.copyWith(
      recipientAddress: address ?? state.recipientAddress,
      recipientCity: city ?? state.recipientCity,
      recipientState: stateName ?? state.recipientState,
      deliveryInstructions: instructions ?? state.deliveryInstructions,
      isDirty: true,
    );
  }

  void setClientPoNumber(String? poNumber) {
    state = state.copyWith(clientPoNumber: poNumber, isDirty: true);
  }

  void setTag(String? tag) {
    state = state.copyWith(tag: tag, isDirty: true);
  }

  void setNotes(String? notes) {
    state = state.copyWith(notes: notes, isDirty: true);
  }

  void setTaxRate(double rate) {
    state = state.copyWith(taxRate: rate, isDirty: true);
  }

  // Items manipulation
  void addItem(DeliveryNoteItemModel item) {
    final updated = List<DeliveryNoteItemModel>.from(state.items)..add(item);
    state = state.copyWith(items: updated, isDirty: true);
  }

  void updateItem(int index, DeliveryNoteItemModel item) {
    if (index < 0 || index >= state.items.length) return;
    final updated = List<DeliveryNoteItemModel>.from(state.items)..[index] = item;
    state = state.copyWith(items: updated, isDirty: true);
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updated = List<DeliveryNoteItemModel>.from(state.items)..removeAt(index);
    state = state.copyWith(items: updated, isDirty: true);
  }

  void reorderItems(int oldIndex, int newIndex) {
    final updated = List<DeliveryNoteItemModel>.from(state.items);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(items: updated, isDirty: true);
  }

  void reset() {
    state = DeliveryNoteCreateState();
    _initDefaults();
  }

  void setReceptionData({
    String? receivedByName,
    String? receivedById,
    String? receivedByPhone,
    String? receiverRelationship,
    String? signatureData,
    DeliveryNoteStatus? status,
  }) {
    state = state.copyWith(
      receivedByName: receivedByName,
      receivedById: receivedById,
      receivedByPhone: receivedByPhone,
      receiverRelationship: receiverRelationship,
      receivedAt: (receivedByName != null && receivedById != null)
          ? DateTime.now()
          : null,
      signatureData: signatureData,
      status: status ?? state.status,
      isDirty: true,
    );
  }

  void clearSignature() {
    state = state.copyWith(signatureData: null, isDirty: true);
  }

  void setSerialsForItem(int itemIndex, List<DeliveryNoteSerialModel> serials) {
    if (itemIndex < 0 || itemIndex >= state.items.length) return;
    final currentItem = state.items[itemIndex];
    final updatedItem = currentItem.copyWith(serials: serials);
    updateItem(itemIndex, updatedItem);
  }

  void removeSerialFromItem(int itemIndex, int serialIndex) {
    if (itemIndex < 0 || itemIndex >= state.items.length) return;
    final currentItem = state.items[itemIndex];
    final updatedSerials =
        List<DeliveryNoteSerialModel>.from(currentItem.serials);
    if (serialIndex < 0 || serialIndex >= updatedSerials.length) return;
    updatedSerials.removeAt(serialIndex);
    updateItem(itemIndex, currentItem.copyWith(serials: updatedSerials));
  }

  // Observations manipulation
  void addObservation(DeliveryNoteObservationModel observation) {
    final updated = List<DeliveryNoteObservationModel>.from(state.observations)
      ..add(observation);
    state = state.copyWith(observations: updated, isDirty: true);
  }

  void removeObservation(int index) {
    if (index < 0 || index >= state.observations.length) return;
    final updated = List<DeliveryNoteObservationModel>.from(state.observations)
      ..removeAt(index);
    state = state.copyWith(observations: updated, isDirty: true);
  }

  void reorderObservations(int oldIndex, int newIndex) {
    final updated = List<DeliveryNoteObservationModel>.from(state.observations);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final obs = updated.removeAt(oldIndex);
    updated.insert(newIndex, obs);
    state = state.copyWith(observations: updated, isDirty: true);
  }

  // Save delivery note
  Future<DeliveryNoteModel> saveDeliveryNote() async {
    if (state.clientId == null || state.clientId!.isEmpty) {
      throw Exception('Debe seleccionar un cliente.');
    }
    if (state.items.isEmpty) {
      throw Exception('Debe agregar al menos un producto a la nota de entrega.');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(deliveryNotesRepositoryProvider);

      final noteModel = DeliveryNoteModel(
        id: state.id ?? '',
        userId: '',
        deliveryNoteNumber: state.deliveryNoteNumber ?? 'NE-PENDIENTE',
        clientId: state.clientId!,
        contactId: state.contactId,
        quoteId: state.quoteId,
        supplierOrderId: state.supplierOrderId,
        clientPoNumber: state.clientPoNumber,
        tag: state.tag,
        notes: state.notes,
        status: state.status,
        date: state.date,
        deliveryDate: state.deliveryDate,
        deliveryType: state.deliveryType,
        shippingCompanyId: state.shippingCompanyId,
        trackingNumber: state.trackingNumber,
        recipientAddress: state.recipientAddress,
        recipientCity: state.recipientCity,
        recipientState: state.recipientState,
        deliveryInstructions: state.deliveryInstructions,
        receivedByName: state.receivedByName,
        receivedById: state.receivedById,
        receivedByPhone: state.receivedByPhone,
        receiverRelationship: state.receiverRelationship,
        receivedAt: state.receivedAt,
        signatureData: state.signatureData,
        subtotal: state.subtotal,
        taxRate: state.taxRate,
        taxAmount: state.taxAmount,
        total: state.total,
        isDropshipping: state.isDropshipping,
        hasMissingSerials: state.hasMissingSerials,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: state.items,
        observations: state.observations,
      );

      final DeliveryNoteModel savedNote;
      if (state.id == null || state.id!.isEmpty) {
        savedNote = await repo.createDeliveryNote(noteModel);
      } else {
        savedNote = await repo.updateDeliveryNote(noteModel);
      }

      await discardDraft(noteId: state.id);
      state = state.copyWith(isLoading: false, isDirty: false);
      return savedNote;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
