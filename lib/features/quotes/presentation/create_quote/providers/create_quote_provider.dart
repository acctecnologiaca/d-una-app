import 'package:d_una_app/core/constants/draft_constants.dart';
import 'package:d_una_app/core/models/draft_data.dart';
import 'package:d_una_app/core/services/draft_storage_service.dart';
import 'package:d_una_app/core/providers/draft_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../domain/repositories/quotes_repository.dart';
import '../../../../clients/data/models/client_model.dart';
import '../../quotes_list/providers/quotes_provider.dart';
import '../../../../collaborators/data/repositories/collaborators_repository.dart';
import '../../../../collaborators/presentation/providers/collaborators_providers.dart';
import '../../../../portfolio/data/repositories/lookup_repository.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/core/utils/country_iso_codes.dart';
import '../../../../supplier_orders/domain/models/supplier_order_status.dart';
import '../../../../supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import '../../view_quote/providers/view_quote_provider.dart';

class QuoteState {
  final Quote? quote; // The final object being built
  final List<QuoteItemProduct> products;
  final List<QuoteItemService> services;
  final List<QuoteCondition> conditions;
  final String? clientId;
  final String? clientName; // For UI display
  final String? contactId;
  final String? contactName; // For UI display
  final int validityDays;
  final String? categoryId;
  final String? categoryName; // For UI display
  final String? advisorId;
  final String? advisorName; // For UI display
  final String? notes;
  final String? label;
  final DateTime dateIssued;
  final String? currentQuoteNumber;
  final String? clientType; // 'company' or 'person'
  final String? advisorPhone;
  final String? advisorEmail;
  final bool isLoading;
  final String? error;

  // Financial Context
  final double globalMargin;
  final double globalTaxRate;
  final String pricingMethod; // 'markup' or 'margin'
  final bool isReadOnly;
  final bool hasProcessedOrders;

  QuoteState({
    this.quote,
    this.products = const [],
    this.services = const [],
    this.conditions = const [],
    this.clientId,
    this.clientName,
    this.contactId,
    this.contactName,
    this.validityDays = 15,
    this.categoryId,
    this.categoryName,
    this.advisorId,
    this.advisorName,
    this.notes,
    this.label,
    DateTime? dateIssued,
    this.currentQuoteNumber,
    this.clientType,
    this.advisorPhone,
    this.advisorEmail,
    this.isLoading = false,
    this.error,
    this.globalMargin = 0.0,
    this.globalTaxRate = 0.0,
    this.pricingMethod = 'margin',
    this.isReadOnly = false,
    this.hasProcessedOrders = false,
  }) : dateIssued = dateIssued ?? DateTime.now();

  QuoteState copyWith({
    Quote? quote,
    List<QuoteItemProduct>? products,
    List<QuoteItemService>? services,
    List<QuoteCondition>? conditions,
    String? clientId,
    String? clientName,
    String? contactId,
    String? contactName,
    int? validityDays,
    String? categoryId,
    String? categoryName,
    String? advisorId,
    String? advisorName,
    String? notes,
    String? label,
    DateTime? dateIssued,
    String? currentQuoteNumber,
    String? clientType,
    String? advisorPhone,
    String? advisorEmail,
    bool? isLoading,
    String? error,
    double? globalMargin,
    double? globalTaxRate,
    String? pricingMethod,
    bool? isReadOnly,
    bool? hasProcessedOrders,
  }) {
    return QuoteState(
      quote: quote ?? this.quote,
      products: products ?? this.products,
      services: services ?? this.services,
      conditions: conditions ?? this.conditions,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      validityDays: validityDays ?? this.validityDays,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      advisorId: advisorId ?? this.advisorId,
      advisorName: advisorName ?? this.advisorName,
      notes: notes ?? this.notes,
      label: label ?? this.label,
      dateIssued: dateIssued ?? this.dateIssued,
      currentQuoteNumber: currentQuoteNumber ?? this.currentQuoteNumber,
      clientType: clientType ?? this.clientType,
      advisorPhone: advisorPhone ?? this.advisorPhone,
      advisorEmail: advisorEmail ?? this.advisorEmail,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      globalMargin: globalMargin ?? this.globalMargin,
      globalTaxRate: globalTaxRate ?? this.globalTaxRate,
      pricingMethod: pricingMethod ?? this.pricingMethod,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      hasProcessedOrders: hasProcessedOrders ?? this.hasProcessedOrders,
    );
  }

  Map<String, dynamic> toDraftJson() {
    return {
      'quote': quote?.toJson(),
      'products': products.map((p) => p.toJson()).toList(),
      'services': services.map((s) => s.toJson()).toList(),
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'client_id': clientId,
      'client_name': clientName,
      'contact_id': contactId,
      'contact_name': contactName,
      'validity_days': validityDays,
      'category_id': categoryId,
      'category_name': categoryName,
      'advisor_id': advisorId,
      'advisor_name': advisorName,
      'notes': notes,
      'label': label,
      'date_issued': dateIssued.toIso8601String(),
      'current_quote_number': currentQuoteNumber,
      'client_type': clientType,
      'advisor_phone': advisorPhone,
      'advisor_email': advisorEmail,
      'global_margin': globalMargin,
      'global_tax_rate': globalTaxRate,
      'pricing_method': pricingMethod,
      'is_read_only': isReadOnly,
      'has_processed_orders': hasProcessedOrders,
    };
  }

  factory QuoteState.fromDraftJson(Map<String, dynamic> json) {
    return QuoteState(
      quote: json['quote'] != null
          ? Quote.fromJson(json['quote'] as Map<String, dynamic>)
          : null,
      products: (json['products'] as List? ?? [])
          .map((p) => QuoteItemProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
      services: (json['services'] as List? ?? [])
          .map((s) => QuoteItemService.fromJson(s as Map<String, dynamic>))
          .toList(),
      conditions: (json['conditions'] as List? ?? [])
          .map((c) => QuoteCondition.fromJson(c as Map<String, dynamic>))
          .toList(),
      clientId: json['client_id'] as String?,
      clientName: json['client_name'] as String?,
      contactId: json['contact_id'] as String?,
      contactName: json['contact_name'] as String?,
      validityDays: (json['validity_days'] as num?)?.toInt() ?? 15,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      advisorId: json['advisor_id'] as String?,
      advisorName: json['advisor_name'] as String?,
      notes: json['notes'] as String?,
      label: json['label'] as String?,
      dateIssued:
          DateTime.tryParse(json['date_issued'] as String? ?? '') ??
          DateTime.now(),
      currentQuoteNumber: json['current_quote_number'] as String?,
      clientType: json['client_type'] as String?,
      advisorPhone: json['advisor_phone'] as String?,
      advisorEmail: json['advisor_email'] as String?,
      globalMargin: (json['global_margin'] as num?)?.toDouble() ?? 0.0,
      globalTaxRate: (json['global_tax_rate'] as num?)?.toDouble() ?? 0.0,
      pricingMethod: json['pricing_method'] as String? ?? 'margin',
      isReadOnly: json['is_read_only'] as bool? ?? false,
      hasProcessedOrders: json['has_processed_orders'] as bool? ?? false,
    );
  }

  // --- Getters for validation ---
  bool get isReadyToSaveDraft {
    final hasItems = products.isNotEmpty || services.isNotEmpty;
    return clientId != null && hasItems;
  }

  bool get isReadyToFinalize {
    final hasItems = products.isNotEmpty || services.isNotEmpty;
    final hasConditions = conditions.isNotEmpty;
    final baseFields =
        clientId != null && categoryId != null && advisorId != null;

    // For 'company', contact is mandatory
    bool contactValid = true;
    if (clientType == 'company') {
      contactValid = contactId != null;
    }

    return hasItems && hasConditions && baseFields && contactValid;
  }

  double get productsSubtotal =>
      products.fold(0.0, (sum, p) => sum + (p.unitPrice * p.quantity));

  double get productsCost =>
      products.fold(0.0, (sum, p) => sum + (p.costPrice * p.quantity));

  double get servicesSubtotal =>
      services.fold(0.0, (sum, s) => sum + (s.unitPrice * s.quantity));

  double get servicesCost =>
      services.fold(0.0, (sum, s) => sum + (s.costPrice * s.quantity));

  double get totalSales => productsSubtotal + servicesSubtotal;
  double get totalCosts => productsCost + servicesCost;
  double get estimatedProfit => totalSales - totalCosts;

  Map<String, ({double currentTotal, double minimumRequired, bool met})> get supplierCostBreakdown {
    final breakdown = <String, ({double currentTotal, double minimumRequired, bool met})>{};
    for (var p in products) {
      if (p.sourceType == QuoteItemSourceType.affiliated && p.supplierName != null) {
        final name = p.supplierName!;
        final cost = p.costPrice * p.quantity;
        final min = p.supplierMinPurchase;
        final existing = breakdown[name];
        if (existing == null) {
          breakdown[name] = (
            currentTotal: cost,
            minimumRequired: min,
            met: false, // Calculated after loop
          );
        } else {
          breakdown[name] = (
            currentTotal: existing.currentTotal + cost,
            minimumRequired: existing.minimumRequired > 0 ? existing.minimumRequired : min,
            met: false,
          );
        }
      }
    }

    // Finalize the record with met check
    final finalizedBreakdown = <String, ({double currentTotal, double minimumRequired, bool met})>{};
    breakdown.forEach((key, val) {
      finalizedBreakdown[key] = (
        currentTotal: val.currentTotal,
        minimumRequired: val.minimumRequired,
        met: val.minimumRequired <= 0 || val.currentTotal >= val.minimumRequired,
      );
    });

    return finalizedBreakdown;
  }

  int get nextGroupIndex {
    if (products.isEmpty) return 1;
    final maxIndex = products.fold<int>(
      0,
      (max, p) => p.groupIndex > max ? p.groupIndex : max,
    );
    return maxIndex + 1;
  }

  int get nextServiceIndex {
    if (services.isEmpty) return 1;
    final maxIndex = services.fold<int>(
      0,
      (max, s) => s.orderIndex > max ? s.orderIndex : max,
    );
    return maxIndex + 1;
  }

  double get taxAmount {
    final taxRateDecimal = globalTaxRate > 1
        ? globalTaxRate / 100
        : globalTaxRate;
    return totalSales * taxRateDecimal;
  }

  double get finalTotal => totalSales + taxAmount;

  bool get hasChanges {
    if (isReadOnly) return false;

    // Si es una cotización nueva
    if (quote == null || quote!.id.isEmpty) {
      return products.isNotEmpty || services.isNotEmpty || clientId != null;
    }

    // Si es una cotización existente, comparar con los datos originales
    if (clientId != quote!.clientId) return true;
    if (contactId != quote!.contactId) return true;
    if (advisorId != quote!.advisorId) return true;
    if (categoryId != quote!.categoryId) return true;
    if (validityDays != quote!.validityDays) return true;
    if (notes != quote!.notes) return true;
    if (label != quote!.quoteTag) return true;
    if (dateIssued.isAtSameMomentAs(quote!.dateIssued) == false &&
        dateIssued.toString() != quote!.dateIssued.toString()) {
      return true;
    }

    // Comparar productos
    if (products.length != (quote!.products?.length ?? 0)) return true;
    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      final op = quote!.products![i];
      if (p.productId != op.productId ||
          p.supplierBranchStockId != op.supplierBranchStockId ||
          p.quantity != op.quantity ||
          p.unitPrice != op.unitPrice ||
          p.costPrice != op.costPrice ||
          p.profitMargin != op.profitMargin ||
          p.sourceType != op.sourceType ||
          p.name != op.name ||
          p.deliveryTimeId != op.deliveryTimeId ||
          p.groupIndex != op.groupIndex ||
          p.warrantyTime != op.warrantyTime ||
          p.warrantyUnit != op.warrantyUnit) {
        return true;
      }
    }

    // Comparar servicios
    if (services.length != (quote!.services?.length ?? 0)) return true;
    for (int i = 0; i < services.length; i++) {
      final s = services[i];
      final os = quote!.services![i];
      if (s.serviceId != os.serviceId ||
          s.quantity != os.quantity ||
          s.unitPrice != os.unitPrice ||
          s.costPrice != os.costPrice ||
          s.profitMargin != os.profitMargin ||
          s.name != os.name ||
          s.orderIndex != os.orderIndex) {
        return true;
      }
    }

    // Comparar condiciones
    if (conditions.length != (quote!.conditions?.length ?? 0)) return true;
    for (int i = 0; i < conditions.length; i++) {
      final c = conditions[i];
      final oc = quote!.conditions![i];
      if (c.conditionId != oc.conditionId ||
          c.description != oc.description ||
          c.orderIndex != oc.orderIndex) {
        return true;
      }
    }

    return false;
  }
}

class CreateQuoteNotifier extends StateNotifier<QuoteState> {
  final QuotesRepository _repository;
  final CollaboratorsRepository? _collaboratorsRepository;
  final LookupRepository? _lookupRepository;
  final Ref _ref;

  CreateQuoteNotifier(
    this._repository,
    this._ref, {
    CollaboratorsRepository? collaboratorsRepository,
    LookupRepository? lookupRepository,
  }) : _collaboratorsRepository = collaboratorsRepository,
       _lookupRepository = lookupRepository,
       super(QuoteState());

  DraftStorageService get _draftStorage =>
      _ref.read(draftStorageServiceProvider);

  String _getDraftKey({String? quoteId}) {
    if (quoteId != null && quoteId.isNotEmpty) {
      return '${DraftConstants.quotesModule}_$quoteId';
    }
    if (state.quote != null && state.quote!.id.isNotEmpty) {
      return '${DraftConstants.quotesModule}_${state.quote!.id}';
    }
    return DraftConstants.quotesModule;
  }

  void autoSaveDraft({int tabIndex = 0, String? quoteId}) {
    final isEditing =
        (state.quote != null && state.quote!.id.isNotEmpty) ||
        (quoteId != null && quoteId.isNotEmpty);

    if (isEditing) {
      if (!state.hasChanges) return;
    } else {
      final hasData =
          state.products.isNotEmpty ||
          state.services.isNotEmpty ||
          state.clientId != null ||
          (state.notes != null && state.notes!.trim().isNotEmpty);

      if (!hasData) return;
    }

    final key = _getDraftKey(quoteId: quoteId);
    final draft = DraftData(
      moduleKey: key,
      savedAt: DateTime.now(),
      tabIndex: tabIndex,
      summaryTitle:
          state.clientName != null
              ? '${isEditing ? "Modificación" : "Cotización"} - ${state.clientName}'
              : 'Cotización sin cliente',
      data: state.toDraftJson(),
    );
    _draftStorage.saveDraftDebounced(draft);
  }

  Future<void> saveDraftNow({int tabIndex = 0, String? quoteId}) async {
    final isEditing =
        (state.quote != null && state.quote!.id.isNotEmpty) ||
        (quoteId != null && quoteId.isNotEmpty);

    if (isEditing) {
      if (!state.hasChanges) return;
    } else {
      final hasData =
          state.products.isNotEmpty ||
          state.services.isNotEmpty ||
          state.clientId != null ||
          (state.notes != null && state.notes!.trim().isNotEmpty);

      if (!hasData) return;
    }

    final key = _getDraftKey(quoteId: quoteId);
    final draft = DraftData(
      moduleKey: key,
      savedAt: DateTime.now(),
      tabIndex: tabIndex,
      summaryTitle:
          state.clientName != null
              ? '${isEditing ? "Modificación" : "Cotización"} - ${state.clientName}'
              : 'Cotización sin cliente',
      data: state.toDraftJson(),
    );
    await _draftStorage.saveDraftNow(draft);
  }

  Future<DraftData?> checkAndRestoreDraft({String? quoteId}) async {
    final key = _getDraftKey(quoteId: quoteId);
    final draft = await _draftStorage.getDraft(key);
    if (draft != null && draft.data.isNotEmpty) {
      state = QuoteState.fromDraftJson(draft.data);
      return draft;
    }
    return null;
  }

  Future<void> clearDraft({String? quoteId}) async {
    final key = _getDraftKey(quoteId: quoteId);
    await _draftStorage.clearDraft(key);
  }

  void reset({bool clearPersistedDraft = false, String? quoteId}) {
    final isEditing =
        (state.quote != null && state.quote!.id.isNotEmpty) ||
        (quoteId != null && quoteId.isNotEmpty);
    final currentId = quoteId ?? state.quote?.id;
    state = QuoteState();
    if (clearPersistedDraft) {
      clearDraft(quoteId: isEditing ? currentId : null);
    }
  }

  Future<void> loadQuote(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = await _repository.getFinancialParameters();
      final quote = await _repository.getQuoteWithDetails(id);

      state = state.copyWith(
        quote: quote,
        products: quote.products ?? [],
        services: quote.services ?? [],
        conditions: quote.conditions ?? [],
        clientId: quote.clientId,
        clientName: quote.clientName,
        contactId: quote.contactId,
        contactName: quote.contactName,
        validityDays: quote.validityDays,
        categoryId: quote.categoryId,
        categoryName: quote.categoryName,
        advisorId: quote.advisorId,
        advisorName: quote.advisorName,
        notes: quote.notes,
        label: quote.quoteTag,
        dateIssued: quote.dateIssued,
        currentQuoteNumber: quote.quoteNumber,
        clientType: quote.clientType,
        globalMargin: params.profitMargin,
        globalTaxRate: params.taxRate,
        pricingMethod: params.pricingMethod,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadQuoteAsCopy(String sourceQuoteId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final params = await _repository.getFinancialParameters();
      final source = await _repository.getQuoteWithDetails(sourceQuoteId);

      // Generate a new quote number for the copy
      final lastNumber = await _repository.getLastQuoteNumber();
      final newNumber = _generateNextQuoteNumber(lastNumber);

      state = QuoteState(
        // quote is intentionally null — this is a NEW quote
        products: source.products ?? [],
        services: source.services ?? [],
        conditions: source.conditions ?? [],
        clientId: source.clientId,
        clientName: source.clientName,
        contactId: source.contactId,
        contactName: source.contactName,
        clientType: source.clientType,
        validityDays: source.validityDays,
        categoryId: source.categoryId,
        categoryName: source.categoryName,
        advisorId: source.advisorId,
        advisorName: source.advisorName,
        notes: source.notes,
        label: source.quoteTag,
        dateIssued: DateTime.now(),
        currentQuoteNumber: newNumber,
        globalMargin: params.profitMargin,
        globalTaxRate: params.taxRate,
        pricingMethod: params.pricingMethod,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> initQuote() async {
    await loadFinancialParameters();
    await fetchNextQuoteNumber();
    await loadDefaultAdvisor();
    await loadDefaultConditions();
  }

  Future<void> loadDefaultAdvisor() async {
    final repo = _collaboratorsRepository;
    if (repo == null) return;
    try {
      final advisor = await repo.getSelfCollaborator();
      if (advisor != null) {
        state = state.copyWith(
          advisorId: advisor.id,
          advisorName: advisor.fullName,
          advisorPhone: advisor.phone,
          advisorEmail: advisor.email,
        );
      }
    } catch (e) {
      state = state.copyWith(error: "Error al cargar asesor: $e");
    }
  }

  Future<void> loadFinancialParameters() async {
    try {
      state = state.copyWith(isLoading: true);
      final params = await _repository.getFinancialParameters();
      state = state.copyWith(
        globalMargin: params.profitMargin,
        globalTaxRate: params.taxRate,
        pricingMethod: params.pricingMethod,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchNextQuoteNumber() async {
    try {
      final lastNumber = await _repository.getLastQuoteNumber();
      final nextNumber = _generateNextQuoteNumber(lastNumber);
      state = state.copyWith(currentQuoteNumber: nextNumber);
    } catch (e) {
      state = state.copyWith(error: "Error al generar número: $e");
    }
  }

  String _getUserCode() {
    final profile = _ref.read(userProfileProvider).value;
    if (profile == null) return 'XX0000';

    final countryCode = CountryIsoCodes.getCode(profile.mainCountry);
    final userNum = profile.userNumber ?? 0;
    final hexPart = userNum.toRadixString(16).toUpperCase().padLeft(4, '0');
    return '$countryCode$hexPart';
  }

  String _generateNextQuoteNumber(String? lastNumber) {
    final userCode = _getUserCode();
    final currentYear = DateTime.now().year % 100; // e.g. 26 for 2026
    final yearPrefix = currentYear.toString().padLeft(2, '0');

    int nextSeq = 1;

    if (lastNumber != null) {
      // Format: CT-XXXXXX-YYSEQ
      final parts = lastNumber.split('-');
      if (parts.length >= 3) {
        final cotPart = parts.last; // e.g. "26001"
        if (cotPart.length == 5) {
          final yearInLast = cotPart.substring(0, 2); // e.g. "26"
          final seqInLast = cotPart.substring(2);     // e.g. "001"
          if (yearInLast == yearPrefix) {
            final parsed = int.tryParse(seqInLast);
            if (parsed != null) {
              nextSeq = parsed + 1;
            }
          }
        }
      }
    }

    final seqFormatted = nextSeq.toString().padLeft(3, '0');
    return 'CT-$userCode-$yearPrefix$seqFormatted';
  }

  Future<void> loadDefaultConditions() async {
    final repo = _lookupRepository;
    if (repo == null) return;
    try {
      final allConditions = await repo.getCommercialConditions();
      final defaultConditions = allConditions
          .where((c) => c.isDefaultQuote)
          .toList();
      if (defaultConditions.isNotEmpty) {
        addConditions(defaultConditions);
      }
    } catch (e) {
      state = state.copyWith(
        error: "Error al cargar condiciones por defecto: $e",
      );
    }
  }

  Future<void> loadExistingQuote(String quoteId) async {
    try {
      state = state.copyWith(isLoading: true, error: null, isReadOnly: true);

      final fullQuote = await _repository.getQuoteWithDetails(quoteId);

      bool hasProcessed = false;
      try {
        final supplierOrdersRepo = _ref.read(supplierOrdersRepositoryProvider);
        final linkedOrders = await supplierOrdersRepo.getSupplierOrdersByQuoteId(quoteId);
        hasProcessed = linkedOrders.any(
          (o) =>
              o.status == SupplierOrderStatus.sent ||
              o.status == SupplierOrderStatus.resent ||
              o.status == SupplierOrderStatus.finalized,
        );
      } catch (_) {}

      state = state.copyWith(
        quote: fullQuote,
        products: fullQuote.products ?? [],
        services: fullQuote.services ?? [],
        conditions: fullQuote.conditions ?? [],
        clientId: fullQuote.clientId,
        clientName: fullQuote.clientName,
        contactId: fullQuote.contactId,
        contactName: fullQuote.contactName,
        validityDays: fullQuote.validityDays,
        categoryId: fullQuote.categoryId,
        categoryName: fullQuote.categoryName,
        advisorId: fullQuote.advisorId,
        advisorName: fullQuote.advisorName,
        notes: fullQuote.notes,
        label: fullQuote.quoteTag,
        dateIssued: fullQuote.dateIssued,
        currentQuoteNumber: fullQuote.quoteNumber,
        hasProcessedOrders: hasProcessed,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // --- Client Management ---
  void setClient(Client client) {
    // Determine primary contact if company
    String? contactId;
    String? contactName;

    if (client.type == 'company' && client.contacts.isNotEmpty) {
      final primaryContact = client.contacts.firstWhere(
        (c) => c.isPrimary,
        orElse: () => client.contacts.first,
      );
      contactId = primaryContact.id;
      contactName = primaryContact.name;
    }

    state = QuoteState(
      quote: state.quote,
      products: state.products,
      services: state.services,
      conditions: state.conditions,
      globalMargin: state.globalMargin,
      globalTaxRate: state.globalTaxRate,
      pricingMethod: state.pricingMethod,
      clientId: client.id,
      clientName: client.name,
      clientType: client.type,
      contactId: contactId,
      contactName: contactName,
      validityDays: state.validityDays,
      categoryId: state.categoryId,
      categoryName: state.categoryName,
      advisorId: state.advisorId,
      advisorName: state.advisorName,
      advisorPhone: state.advisorPhone,
      advisorEmail: state.advisorEmail,
      notes: state.notes,
      label: state.label,
      dateIssued: state.dateIssued,
      currentQuoteNumber: state.currentQuoteNumber,
    );
  }

  void clearClient() {
    state = QuoteState(
      quote: state.quote,
      products: state.products,
      services: state.services,
      conditions: state.conditions,
      globalMargin: state.globalMargin,
      globalTaxRate: state.globalTaxRate,
      pricingMethod: state.pricingMethod,
      clientId: null,
      clientName: null,
      clientType: null,
      contactId: null,
      contactName: null,
      validityDays: state.validityDays,
      categoryId: state.categoryId,
      categoryName: state.categoryName,
      advisorId: state.advisorId,
      advisorName: state.advisorName,
      advisorPhone: state.advisorPhone,
      advisorEmail: state.advisorEmail,
      notes: state.notes,
      label: state.label,
      dateIssued: state.dateIssued,
      currentQuoteNumber: state.currentQuoteNumber,
    );
  }

  void setContact(String id, String name) {
    state = state.copyWith(contactId: id, contactName: name);
  }

  void clearContact() {
    state = QuoteState(
      quote: state.quote,
      products: state.products,
      services: state.services,
      conditions: state.conditions,
      globalMargin: state.globalMargin,
      globalTaxRate: state.globalTaxRate,
      pricingMethod: state.pricingMethod,
      clientId: state.clientId,
      clientName: state.clientName,
      clientType: state.clientType,
      contactId: null,
      contactName: null,
      validityDays: state.validityDays,
      categoryId: state.categoryId,
      categoryName: state.categoryName,
      advisorId: state.advisorId,
      advisorName: state.advisorName,
      advisorPhone: state.advisorPhone,
      advisorEmail: state.advisorEmail,
      notes: state.notes,
      label: state.label,
      dateIssued: state.dateIssued,
      currentQuoteNumber: state.currentQuoteNumber,
    );
  }

  // --- Details Management ---
  void setDetails({
    int? validity,
    String? categoryId,
    String? categoryName,
    String? advisorId,
    String? advisorName,
    String? notes,
    String? label,
    DateTime? dateIssued,
  }) {
    state = state.copyWith(
      validityDays: validity,
      categoryId: categoryId,
      categoryName: categoryName,
      advisorId: advisorId,
      advisorName: advisorName,
      notes: notes,
      label: label,
      dateIssued: dateIssued,
    );
  }

  // --- Conditions Management ---
  void addCondition(String description, {String? conditionId}) {
    final condition = QuoteCondition(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
      quoteId: '', // To be filled on save
      conditionId: conditionId,
      description: description,
      orderIndex: state.conditions.length,
    );
    state = state.copyWith(conditions: [...state.conditions, condition]);
  }

  void addConditions(List<CommercialCondition> newConditions) {
    if (newConditions.isEmpty) return;

    final conditionsToAdd = newConditions
        .map(
          (c) => QuoteCondition(
            id:
                DateTime.now().millisecondsSinceEpoch.toString() +
                c.id, // Temp ID
            quoteId: '', // To be filled on save
            conditionId: c.id,
            description: c.description,
            orderIndex: 0, // Will be updated below
          ),
        )
        .toList();

    var currentList = List<QuoteCondition>.from(state.conditions);
    currentList.addAll(conditionsToAdd);

    // Update order indices
    for (int i = 0; i < currentList.length; i++) {
      currentList[i] = QuoteCondition(
        id: currentList[i].id,
        quoteId: currentList[i].quoteId,
        conditionId: currentList[i].conditionId,
        description: currentList[i].description,
        orderIndex: i,
      );
    }

    state = state.copyWith(conditions: currentList);
  }

  void removeCondition(String id) {
    state = state.copyWith(
      conditions: state.conditions.where((c) => c.id != id).toList(),
    );
  }

  void reorderConditions(int oldIndex, int newIndex) {
    var list = List<QuoteCondition>.from(state.conditions);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // Update order indices
    list = list
        .asMap()
        .entries
        .map(
          (e) => QuoteCondition(
            id: e.value.id,
            quoteId: e.value.quoteId,
            conditionId: e.value.conditionId,
            description: e.value.description,
            orderIndex: e.key,
          ),
        )
        .toList();

    state = state.copyWith(conditions: list);
  }

  // --- Product Management ---
  void addProduct(QuoteItemProduct product) {
    state = state.copyWith(products: [...state.products, product]);
  }

  void updateProduct(QuoteItemProduct product) {
    state = state.copyWith(
      products: state.products
          .map((p) => p.id == product.id ? product : p)
          .toList(),
    );
  }

  void removeProduct(String id) {
    state = state.copyWith(
      products: state.products.where((p) => p.id != id).toList(),
    );
  }

  void removeProductGroup(int groupIndex) {
    state = state.copyWith(
      products: state.products.where((p) => p.groupIndex != groupIndex).toList(),
    );
  }

  void updateGroupPrice(
    int groupIndex,
    double newUnitPrice,
    double newMargin, [
    String? newDeliveryTimeId,
    int? newWarrantyTime,
    String? newWarrantyUnit,
  ]) {
    final updatedProducts = state.products.map((item) {
      if (item.groupIndex == groupIndex) {
        final taxAmount = newUnitPrice * (item.taxRate / 100);
        final totalPrice = (newUnitPrice + taxAmount) * item.quantity;
        return item.copyWith(
          deliveryTimeId: newDeliveryTimeId,
          availableStock: item.sourceType == QuoteItemSourceType.temporal
              ? item.quantity
              : item.availableStock,
          profitMargin: newMargin,
          unitPrice: newUnitPrice,
          taxAmount: taxAmount,
          totalPrice: totalPrice,
          warrantyTime: newWarrantyTime,
          warrantyUnit: newWarrantyUnit,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(products: updatedProducts);
  }

  void updateGroupQuantity(int groupIndex, double newTotalQty) {
    final items = state.products.where((p) => p.groupIndex == groupIndex).toList();
    if (items.isEmpty) return;

    double currentTotal = items.fold(0.0, (sum, item) => sum + item.quantity);
    if (newTotalQty == currentTotal) return;

    List<QuoteItemProduct> updatedProducts = List.from(state.products);

    if (newTotalQty > currentTotal) {
      // Increase qty - Take from CHEAPEST provider first
      double needed = newTotalQty - currentTotal;
      final sortedItems = List<QuoteItemProduct>.from(items)
        ..sort((a, b) {
          // 1. Prioridad de origen (menor índice = mayor prioridad)
          int getPriority(QuoteItemSourceType type) {
            switch (type) {
              case QuoteItemSourceType.own:
                return 0;
              case QuoteItemSourceType.affiliated:
                return 1;
              case QuoteItemSourceType.external:
                return 2;
              case QuoteItemSourceType.temporal:
                return 3;
            }
          }

          final priorityA = getPriority(a.sourceType);
          final priorityB = getPriority(b.sourceType);

          if (priorityA != priorityB) {
            return priorityA.compareTo(priorityB);
          }

          // 2. Si son del mismo origen, el más barato primero
          return a.costPrice.compareTo(b.costPrice);
        });

      for (var item in sortedItems) {
        final isManual =
            item.sourceType == QuoteItemSourceType.temporal ||
            item.sourceType == QuoteItemSourceType.external;
        final available = isManual
            ? double.infinity
            : (item.availableStock ?? double.infinity);
        if (item.quantity < available) {
          double canAdd = available - item.quantity;
          double toAdd = needed > canAdd ? canAdd : needed;

          final index = updatedProducts.indexWhere((p) => p.id == item.id);
          updatedProducts[index] = _copyWithQty(item, item.quantity + toAdd);
          needed -= toAdd;
          if (needed <= 0) break;
        }
      }
    } else {
      // Decrease qty - Take from MOST EXPENSIVE provider first
      double toRemove = currentTotal - newTotalQty;
      final sortedItems = List<QuoteItemProduct>.from(items)
        ..sort((a, b) => b.costPrice.compareTo(a.costPrice));

      for (var item in sortedItems) {
        if (item.quantity > 0) {
          double canRemove = item.quantity;
          double removed = toRemove > canRemove ? canRemove : toRemove;

          final index = updatedProducts.indexWhere((p) => p.id == item.id);
          updatedProducts[index] = _copyWithQty(item, item.quantity - removed);
          toRemove -= removed;
          if (toRemove <= 0) break;
        }
      }
    }

    // Clean up items with 0 qty
    updatedProducts.removeWhere((p) => p.groupIndex == groupIndex && p.quantity <= 0);

    // Recalculate the unit price to maintain the current overall profit margin
    final remainingGroupItems = updatedProducts
        .where((p) => p.groupIndex == groupIndex)
        .toList();
    if (remainingGroupItems.isNotEmpty) {
      double groupTotalCost = 0;
      double groupTotalQty = 0;
      for (var item in remainingGroupItems) {
        groupTotalQty += item.quantity;
        groupTotalCost += item.costPrice * item.quantity;
      }
      double newAvgCost = groupTotalQty > 0
          ? groupTotalCost / groupTotalQty
          : 0;

      double currentGroupMargin = remainingGroupItems.first.profitMargin;

      double newUnitPrice;
      if (state.pricingMethod == 'margin') {
        final factor = 1 - currentGroupMargin;
        newUnitPrice = factor > 0 ? newAvgCost / factor : newAvgCost;
      } else {
        newUnitPrice = newAvgCost * (1 + currentGroupMargin);
      }

      for (int i = 0; i < updatedProducts.length; i++) {
        if (updatedProducts[i].groupIndex == groupIndex) {
          final item = updatedProducts[i];
          final taxAmount = newUnitPrice * (item.taxRate / 100);
          updatedProducts[i] = _copyWithPricing(
            item,
            newUnitPrice,
            taxAmount,
            (newUnitPrice + taxAmount) * item.quantity,
          );
        }
      }
    }

    state = state.copyWith(products: updatedProducts);
  }

  QuoteItemProduct _copyWithQty(QuoteItemProduct item, double newQty) {
    final totalPrice = (item.unitPrice + item.taxAmount) * newQty;
    return item.copyWith(quantity: newQty, totalPrice: totalPrice);
  }

  QuoteItemProduct _copyWithPricing(
    QuoteItemProduct item,
    double newUnitPrice,
    double newTaxAmount,
    double newTotalPrice,
  ) {
    return item.copyWith(
      unitPrice: newUnitPrice,
      taxAmount: newTaxAmount,
      totalPrice: newTotalPrice,
    );
  }

  // --- Service Management ---
  void addService(QuoteItemService service) {
    state = state.copyWith(
      services: [
        ...state.services,
        service.orderIndex == 0
            ? service.copyWith(orderIndex: state.nextServiceIndex)
            : service,
      ],
    );
  }

  void updateService(QuoteItemService service) {
    state = state.copyWith(
      services: state.services
          .map((s) => s.id == service.id ? service : s)
          .toList(),
    );
  }

  void removeService(String id) {
    state = state.copyWith(
      services: state.services.where((s) => s.id != id).toList(),
    );
  }

  void updateServiceQuantity(String id, double newQty) {
    final updatedServices = state.services.map((item) {
      if (item.id == id || (item.serviceId != null && item.serviceId == id)) {
        // Fallback if id is not fully generated yet
        final taxAmount = item.unitPrice * (item.taxRate / 100);
        final newTotalPrice = (item.unitPrice + taxAmount) * newQty;
        return item.copyWith(
          quantity: newQty,
          taxAmount: taxAmount,
          totalPrice: newTotalPrice,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(services: updatedServices);
  }

  void updateServiceDetails(QuoteItemService updatedService) {
    final updatedServices = state.services.map((item) {
      if (item.id == updatedService.id ||
          (item.serviceId != null &&
              item.serviceId == updatedService.serviceId)) {
        return updatedService;
      }
      return item;
    }).toList();
    state = state.copyWith(services: updatedServices);
  }

  // Removed selectClient (redundant with setClient)

  // --- Save / Finalize ---
  Future<bool> saveAsDraft() async {
    return createQuote(status: 'draft');
  }

  Future<bool> createQuote({String? status}) async {
    if (status == 'finalized' && !state.isReadyToFinalize) {
      state = state.copyWith(error: "Faltan datos obligatorios para finalizar");
      return false;
    }

    if (state.clientId == null) {
      state = state.copyWith(error: "Debes seleccionar un cliente");
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final isEditing = state.quote != null && state.quote!.id.isNotEmpty;

      // Determine the final status (preserve existing status when editing unless status is explicitly passed)
      String effectiveStatus;
      if (isEditing) {
        effectiveStatus = status ?? state.quote!.status;
      } else {
        effectiveStatus = status ?? 'draft';
      }

      // Reactivation logic for expired quotes
      if (isEditing && effectiveStatus == 'expired') {
        final expirationDate = state.dateIssued.add(
          Duration(days: state.validityDays),
        );
        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);

        // If it's no longer expired based on new date/validity, reset to draft
        if (!expirationDate.isBefore(startOfToday)) {
          effectiveStatus = 'draft';
        }
      }

      // 1. Calculate Totals
      double subtotal = 0;
      double taxAmount = 0;

      for (var p in state.products) {
        subtotal += p.unitPrice * p.quantity;
        taxAmount += (p.unitPrice * (p.taxRate / 100)) * p.quantity;
      }
      for (var s in state.services) {
        subtotal += s.unitPrice * s.quantity;
        taxAmount += (s.unitPrice * (s.taxRate / 100)) * s.quantity;
      }

      final total = subtotal + taxAmount;

      Quote savedQuote;

      if (isEditing) {
        // 2. Assemble Quote Object for Update
        final updateQuote = Quote(
          id: state.quote!.id,
          userId: state.quote!.userId,
          quoteNumber: state.currentQuoteNumber ?? state.quote!.quoteNumber,
          clientId: state.clientId!,
          contactId: state.contactId,
          advisorId: state.advisorId,
          categoryId: state.categoryId,
          status: effectiveStatus,
          dateIssued: state.dateIssued,
          validityDays: state.validityDays,
          subtotal: subtotal,
          taxAmount: taxAmount,
          total: total,
          notes: state.notes,
          quoteTag: state.label,
          isArchived: state.quote!.isArchived,
          createdAt: state.quote!.createdAt,
          updatedAt: DateTime.now(),
        );

        // 3. Save to Repository
        savedQuote = await _repository.updateQuote(
          updateQuote,
          products: state.products,
          services: state.services,
          conditions: state.conditions,
        );
      } else {
        // 2. Recalculate quote number right before saving to avoid duplicates (user request)
        final lastNumber = await _repository.getLastQuoteNumber();
        final finalQuoteNumber = _generateNextQuoteNumber(lastNumber);
        state = state.copyWith(currentQuoteNumber: finalQuoteNumber);

        // 3. Assemble Quote Object for Create
        final newQuote = Quote(
          id: '', // Will be generated by DB
          userId: '', // Will be filled by repository from auth.uid()
          quoteNumber: finalQuoteNumber,
          clientId: state.clientId!,
          contactId: state.contactId,
          advisorId: state.advisorId,
          categoryId: state.categoryId,
          status: status ?? 'draft',
          dateIssued: state.dateIssued,
          validityDays: state.validityDays,
          subtotal: subtotal,
          taxAmount: taxAmount,
          total: total,
          notes: state.notes,
          quoteTag: state.label,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 4. Save to Repository
        savedQuote = await _repository.createQuote(
          newQuote,
          products: state.products,
          services: state.services,
          conditions: state.conditions,
        );
      }

      final wasEditing = isEditing;
      final previousQuoteId = state.quote?.id;

      state = state.copyWith(quote: savedQuote, isLoading: false);

      if (wasEditing) {
        await clearDraft(quoteId: previousQuoteId);
      } else {
        await clearDraft(quoteId: null);
      }

      // Auto-refresh the list & view provider
      _ref.invalidate(viewQuoteProvider(savedQuote.id));
      _ref.invalidate(quotesListProvider);
      _ref.invalidate(paginatedQuotesListProvider);
      _ref.invalidate(paginatedQuoteSearchProvider);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final createQuoteProvider =
    StateNotifierProvider<CreateQuoteNotifier, QuoteState>((ref) {
      final repository = ref.watch(quotesRepositoryProvider);
      final collaboratorsRepository = ref.watch(
        collaboratorsRepositoryProvider,
      );
      final lookupRepository = ref.watch(lookupRepositoryProvider);

      final notifier = CreateQuoteNotifier(
        repository,
        ref,
        collaboratorsRepository: collaboratorsRepository,
        lookupRepository: lookupRepository,
      );
      return notifier;
    });
