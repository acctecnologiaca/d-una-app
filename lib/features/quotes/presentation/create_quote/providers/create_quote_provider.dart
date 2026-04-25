import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../domain/repositories/quotes_repository.dart';
import '../../../../clients/data/models/client_model.dart';
import '../../quotes_list/providers/quotes_provider.dart';
import '../../../../collaborators/data/repositories/collaborators_repository.dart';
import '../../../../collaborators/presentation/providers/collaborators_providers.dart';
import '../../../../portfolio/data/repositories/lookup_repository.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';

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

  bool get hasChanges {
    return !isReadOnly &&
        (products.isNotEmpty || services.isNotEmpty || clientId != null);
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
       super(QuoteState()) {
    initQuote();
  }

  void reset() {
    state = QuoteState();
    initQuote();
  }

  Future<void> loadQuote(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
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

  String _generateNextQuoteNumber(String? lastNumber) {
    if (lastNumber == null) return 'COT-000001';

    final digitsMatch = RegExp(r'\d+').firstMatch(lastNumber);
    if (digitsMatch == null) return 'COT-000001';

    final numericPart = digitsMatch.group(0)!;
    final nextInt = int.parse(numericPart) + 1;

    return 'COT-${nextInt.toString().padLeft(6, '0')}';
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

  void removeProductGroup(String name) {
    state = state.copyWith(
      products: state.products.where((p) => p.name != name).toList(),
    );
  }

  void updateGroupPrice(
    String name,
    double newUnitPrice,
    double newMargin, [
    String? newDeliveryTimeId,
  ]) {
    final updatedProducts = state.products.map((item) {
      if (item.name == name) {
        final taxAmount = newUnitPrice * (item.taxRate / 100);
        final totalPrice = (newUnitPrice + taxAmount) * item.quantity;
        return QuoteItemProduct(
          id: item.id,
          quoteId: item.quoteId,
          productId: item.productId,
          supplierBranchStockId: item.supplierBranchStockId,
          deliveryTimeId: newDeliveryTimeId ?? item.deliveryTimeId,
          name: item.name,
          brand: item.brand,
          model: item.model,
          uom: item.uom,
          description: item.description,
          availableStock: item.isTemporal ? item.quantity : item.availableStock,
          quantity: item.quantity,
          costPrice: item.costPrice,
          profitMargin: newMargin,
          unitPrice: newUnitPrice,
          taxRate: item.taxRate,
          taxAmount: taxAmount,
          totalPrice: totalPrice,
          warrantyTime: item.warrantyTime,
          externalProviderName: item.externalProviderName,
          isTemporal: item.isTemporal,

          // Sincronizar stock si es temporal
        );
      }
      return item;
    }).toList();
    state = state.copyWith(products: updatedProducts);
  }

  void updateGroupQuantity(String name, double newTotalQty) {
    final items = state.products.where((p) => p.name == name).toList();
    if (items.isEmpty) return;

    double currentTotal = items.fold(0.0, (sum, item) => sum + item.quantity);
    if (newTotalQty == currentTotal) return;

    List<QuoteItemProduct> updatedProducts = List.from(state.products);

    if (newTotalQty > currentTotal) {
      // Increase qty - Take from CHEAPEST provider first
      double needed = newTotalQty - currentTotal;
      final sortedItems = List<QuoteItemProduct>.from(items)
        ..sort((a, b) => a.costPrice.compareTo(b.costPrice));

      for (var item in sortedItems) {
        final available = item.availableStock ?? double.infinity;
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
    updatedProducts.removeWhere((p) => p.name == name && p.quantity <= 0);

    // Recalculate the unit price to maintain the current overall profit margin
    final remainingGroupItems = updatedProducts
        .where((p) => p.name == name)
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
        if (updatedProducts[i].name == name) {
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
    return QuoteItemProduct(
      id: item.id,
      quoteId: item.quoteId,
      productId: item.productId,
      supplierBranchStockId: item.supplierBranchStockId,
      deliveryTimeId: item.deliveryTimeId,
      name: item.name,
      brand: item.brand,
      model: item.model,
      uom: item.uom,
      description: item.description,
      availableStock: item.isTemporal ? newQty : item.availableStock,
      quantity: newQty,
      costPrice: item.costPrice,
      profitMargin: item.profitMargin,
      unitPrice: item.unitPrice,
      taxRate: item.taxRate,
      taxAmount: item.taxAmount,
      totalPrice: totalPrice,
      warrantyTime: item.warrantyTime,
      externalProviderName: item.externalProviderName,
      isTemporal: item.isTemporal,
    );
  }

  QuoteItemProduct _copyWithPricing(
    QuoteItemProduct item,
    double newUnitPrice,
    double newTaxAmount,
    double newTotalPrice,
  ) {
    return QuoteItemProduct(
      id: item.id,
      quoteId: item.quoteId,
      productId: item.productId,
      supplierBranchStockId: item.supplierBranchStockId,
      deliveryTimeId: item.deliveryTimeId,
      name: item.name,
      brand: item.brand,
      model: item.model,
      uom: item.uom,
      description: item.description,
      availableStock: item.isTemporal ? item.quantity : item.availableStock,
      quantity: item.quantity,
      costPrice: item.costPrice,
      profitMargin: item.profitMargin,
      unitPrice: newUnitPrice,
      taxRate: item.taxRate,
      taxAmount: newTaxAmount,
      totalPrice: newTotalPrice,
      warrantyTime: item.warrantyTime,
      externalProviderName: item.externalProviderName,
      isTemporal: item.isTemporal,
    );
  }

  // --- Service Management ---
  void addService(QuoteItemService service) {
    state = state.copyWith(services: [...state.services, service]);
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
        return QuoteItemService(
          id: item.id,
          quoteId: item.quoteId,
          serviceId: item.serviceId,
          serviceRateId: item.serviceRateId,
          executionTimeId: item.executionTimeId,
          name: item.name,
          description: item.description,
          quantity: newQty,
          costPrice: item.costPrice,
          profitMargin: item.profitMargin,
          unitPrice: item.unitPrice,
          taxRate: item.taxRate,
          taxAmount: taxAmount,
          totalPrice: newTotalPrice,
          warrantyTime: item.warrantyTime,
          rateSymbol: item.rateSymbol,
          rateIconName: item.rateIconName,
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

  Future<bool> createQuote({String status = 'draft'}) async {
    if (status == 'pending' && !state.isReadyToFinalize) {
      state = state.copyWith(error: "Faltan datos obligatorios para finalizar");
      return false;
    }

    if (state.clientId == null) {
      state = state.copyWith(error: "Debes seleccionar un cliente");
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // 1. Recalculate quote number right before saving to avoid duplicates (user request)
      final lastNumber = await _repository.getLastQuoteNumber();
      final finalQuoteNumber = _generateNextQuoteNumber(lastNumber);
      state = state.copyWith(currentQuoteNumber: finalQuoteNumber);

      // 2. Calculate Totals
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

      // 3. Assemble Quote Object
      final newQuote = Quote(
        id: '', // Will be generated by DB
        userId: '', // Will be filled by repository from auth.uid()
        quoteNumber: finalQuoteNumber,
        clientId: state.clientId!,
        contactId: state.contactId,
        advisorId: state.advisorId,
        categoryId: state.categoryId,
        status: status,
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
      final savedQuote = await _repository.createQuote(
        newQuote,
        products: state.products,
        services: state.services,
        conditions: state.conditions,
      );

      state = state.copyWith(quote: savedQuote, isLoading: false);

      // Auto-refresh the list
      _ref.invalidate(quotesListProvider);

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

      return CreateQuoteNotifier(
        repository,
        ref,
        collaboratorsRepository: collaboratorsRepository,
        lookupRepository: lookupRepository,
      );
    });
