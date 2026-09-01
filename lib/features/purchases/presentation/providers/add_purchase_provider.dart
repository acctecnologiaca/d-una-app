import 'package:d_una_app/core/constants/draft_constants.dart';
import 'package:d_una_app/core/models/draft_data.dart';
import 'package:d_una_app/core/services/draft_storage_service.dart';
import 'package:d_una_app/core/providers/draft_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/features/purchases/domain/models/models.dart';
import 'package:d_una_app/features/purchases/data/repositories/purchases_repository.dart';
import 'package:d_una_app/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:d_una_app/features/purchases/presentation/providers/purchase_details_provider.dart';
import 'package:d_una_app/features/purchases/data/models/purchase_item_product.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';

import 'package:equatable/equatable.dart';

class AddPurchaseState extends Equatable {
  final String? purchaseId;
  final String? supplierId;
  final String? supplierName;
  final String? supplierTaxId;
  final String? supplierOrderId;
  final String documentType; // 'Factura' or 'Nota de entrega'
  final String? documentNumber;
  final String? invoicePhotoUrl;
  final DateTime date;
  final double taxRate;

  final List<PurchaseItemProduct> products;
  final List<ProductSerial> serials;

  final bool isLoading;
  final String? error;

  AddPurchaseState({
    this.purchaseId,
    this.supplierId,
    this.supplierName,
    this.supplierTaxId,
    this.supplierOrderId,
    this.documentType = 'invoice',
    this.documentNumber,
    this.invoicePhotoUrl,
    DateTime? date,
    this.taxRate = 16.0,
    this.products = const [],
    this.serials = const [],
    this.isLoading = false,
    this.error,
  }) : date = date ?? DateTime.now();

  @override
  List<Object?> get props => [
    purchaseId,
    supplierId,
    supplierName,
    supplierTaxId,
    supplierOrderId,
    documentType,
    documentNumber,
    invoicePhotoUrl,
    date.year,
    date.month,
    date.day,
    taxRate,
    products,
    serials,
    isLoading,
    error,
  ];

  double get subtotal => products.fold(0, (sum, item) => sum + item.subtotal);

  double get tax => subtotal * (taxRate / 100);

  double get total => subtotal + tax;

  bool get hasMissingSerials {
    for (var product in products) {
      if (product.requiresSerials) {
        final count = serials
            .where((s) => s.productId == product.productId)
            .length;
        if (count < product.quantity) return true;
      }
    }
    return false;
  }

  AddPurchaseState copyWith({
    String? purchaseId,
    String? supplierId,
    String? supplierName,
    String? supplierTaxId,
    String? supplierOrderId,
    String? documentType,
    String? documentNumber,
    String? invoicePhotoUrl,
    DateTime? date,
    double? taxRate,
    List<PurchaseItemProduct>? products,
    List<ProductSerial>? serials,
    bool? isLoading,
    String? error,
  }) {
    return AddPurchaseState(
      purchaseId: purchaseId ?? this.purchaseId,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierTaxId: supplierTaxId ?? this.supplierTaxId,
      supplierOrderId: supplierOrderId ?? this.supplierOrderId,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      invoicePhotoUrl: invoicePhotoUrl ?? this.invoicePhotoUrl,
      date: date ?? this.date,
      taxRate: taxRate ?? this.taxRate,
      products: products ?? this.products,
      serials: serials ?? this.serials,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  Map<String, dynamic> toDraftJson() {
    return {
      'purchase_id': purchaseId,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'supplier_tax_id': supplierTaxId,
      'supplier_order_id': supplierOrderId,
      'document_type': documentType,
      'document_number': documentNumber,
      'invoice_photo_url': invoicePhotoUrl,
      'date': date.toIso8601String(),
      'tax_rate': taxRate,
      'products': products.map((p) => p.toJson()).toList(),
      'serials': serials.map((s) => s.toDraftJson()).toList(),
    };
  }

  factory AddPurchaseState.fromDraftJson(Map<String, dynamic> json) {
    return AddPurchaseState(
      purchaseId: json['purchase_id'] as String?,
      supplierId: json['supplier_id'] as String?,
      supplierName: json['supplier_name'] as String?,
      supplierTaxId: json['supplier_tax_id'] as String?,
      supplierOrderId: json['supplier_order_id'] as String?,
      documentType: json['document_type'] as String? ?? 'invoice',
      documentNumber: json['document_number'] as String?,
      invoicePhotoUrl: json['invoice_photo_url'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 16.0,
      products: (json['products'] as List? ?? [])
          .map((p) => PurchaseItemProduct.fromJson(p as Map<String, dynamic>))
          .toList(),
      serials: (json['serials'] as List? ?? [])
          .map((s) => ProductSerial.fromDraftJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AddPurchaseNotifier extends StateNotifier<AddPurchaseState> {
  final Ref _ref;
  final PurchasesRepository _repository;
  AddPurchaseState? _baselineState;

  AddPurchaseNotifier(this._ref, this._repository) : super(AddPurchaseState()) {
    _baselineState = state;
    _loadFinancialParameters();
  }

  DraftStorageService get _draftStorage =>
      _ref.read(draftStorageServiceProvider);

  String _getDraftKey({String? purchaseId}) {
    if (purchaseId != null && purchaseId.isNotEmpty) {
      return '${DraftConstants.purchasesModule}_$purchaseId';
    }
    if (state.purchaseId != null && state.purchaseId!.isNotEmpty) {
      return '${DraftConstants.purchasesModule}_${state.purchaseId}';
    }
    return DraftConstants.purchasesModule;
  }

  void autoSaveDraft({int tabIndex = 0, String? purchaseId}) {
    final isEditing =
        (state.purchaseId != null && state.purchaseId!.isNotEmpty) ||
        (purchaseId != null && purchaseId.isNotEmpty);

    if (isEditing) {
      if (!hasChanges) return;
    } else {
      final hasData =
          state.products.isNotEmpty ||
          state.supplierId != null ||
          (state.documentNumber != null &&
              state.documentNumber!.trim().isNotEmpty);

      if (!hasData) return;
    }

    final key = _getDraftKey(purchaseId: purchaseId);
    final draft = DraftData(
      moduleKey: key,
      savedAt: DateTime.now(),
      tabIndex: tabIndex,
      summaryTitle:
          state.supplierName != null
              ? '${isEditing ? "Modificación Compra" : "Registro de Compra"} - ${state.supplierName}'
              : 'Registro de Compra',
      data: state.toDraftJson(),
    );
    _draftStorage.saveDraftDebounced(draft);
  }

  Future<void> saveDraftNow({int tabIndex = 0, String? purchaseId}) async {
    final isEditing =
        (state.purchaseId != null && state.purchaseId!.isNotEmpty) ||
        (purchaseId != null && purchaseId.isNotEmpty);

    if (isEditing) {
      if (!hasChanges) return;
    } else {
      final hasData =
          state.products.isNotEmpty ||
          state.supplierId != null ||
          (state.documentNumber != null &&
              state.documentNumber!.trim().isNotEmpty);

      if (!hasData) return;
    }

    final key = _getDraftKey(purchaseId: purchaseId);
    final draft = DraftData(
      moduleKey: key,
      savedAt: DateTime.now(),
      tabIndex: tabIndex,
      summaryTitle:
          state.supplierName != null
              ? '${isEditing ? "Modificación Compra" : "Registro de Compra"} - ${state.supplierName}'
              : 'Registro de Compra',
      data: state.toDraftJson(),
    );
    await _draftStorage.saveDraftNow(draft);
  }

  Future<DraftData?> checkAndRestoreDraft({String? purchaseId}) async {
    final key = _getDraftKey(purchaseId: purchaseId);
    final draft = await _draftStorage.getDraft(key);
    if (draft != null && draft.data.isNotEmpty) {
      state = AddPurchaseState.fromDraftJson(draft.data);
      return draft;
    }
    return null;
  }

  Future<void> clearDraft({String? purchaseId}) async {
    final key = _getDraftKey(purchaseId: purchaseId);
    await _draftStorage.clearDraft(key);
  }

  bool get hasChanges {
    if (_baselineState == null) return false;
    if (state.supplierId != _baselineState!.supplierId) {
      return true;
    }
    if (state.documentType != _baselineState!.documentType) {
      return true;
    }
    if (state.documentNumber != _baselineState!.documentNumber) {
      return true;
    }
    if (state.invoicePhotoUrl != _baselineState!.invoicePhotoUrl) {
      return true;
    }
    if (!listEquals(state.products, _baselineState!.products)) {
      return true;
    }
    if (!listEquals(state.serials, _baselineState!.serials)) {
      return true;
    }
    if (state.date.year != _baselineState!.date.year ||
        state.date.month != _baselineState!.date.month ||
        state.date.day != _baselineState!.date.day) {
      return true;
    }
    return false;
  }

  void updateBaseline() {
    _baselineState = state;
  }

  Future<void> _loadFinancialParameters() async {
    try {
      final quotesRepo = _ref.read(quotesRepositoryProvider);
      final params = await quotesRepo.getFinancialParameters();
      state = state.copyWith(taxRate: params.taxRate);
      _baselineState = _baselineState?.copyWith(taxRate: params.taxRate) ?? state.copyWith(taxRate: params.taxRate);
    } catch (_) {
      // Fallback
    }
  }

  void setSupplier(String id, String name, {String? taxId}) {
    state = state.copyWith(
      supplierId: id,
      supplierName: name,
      supplierTaxId: taxId,
    );
    autoSaveDraft();
  }

  void loadFromDetails(
    Purchase purchase,
    List<PurchaseItemProduct> items,
    List<ProductSerial> serials,
    String? supplierTaxId,
  ) {
    state = AddPurchaseState(
      purchaseId: purchase.id,
      supplierId: purchase.supplierId,
      supplierName: purchase.supplierName,
      supplierTaxId: supplierTaxId,
      supplierOrderId: purchase.supplierOrderId,
      documentType: purchase.documentType,
      documentNumber: purchase.documentNumber,
      invoicePhotoUrl: purchase.invoicePhotoUrl,
      date: purchase.date,
      products: items,
      serials: serials,
    );
    updateBaseline();
  }

  void setDocumentType(String type) {
    state = state.copyWith(documentType: type);
    autoSaveDraft();
  }

  void setDocumentNumber(String number) {
    state = state.copyWith(documentNumber: number);
    autoSaveDraft();
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
    autoSaveDraft();
  }

  bool addProduct(PurchaseItemProduct product) {
    if (state.products.any((p) => p.productId == product.productId)) {
      return false;
    }
    state = state.copyWith(products: [...state.products, product]);
    autoSaveDraft();
    return true;
  }

  void updateProduct(PurchaseItemProduct product) {
    state = state.copyWith(
      products: state.products
          .map((p) => p.id == product.id ? product : p)
          .toList(),
    );
    autoSaveDraft();
  }

  void removeProduct(String productId) {
    state = state.copyWith(
      products: state.products.where((p) => p.productId != productId).toList(),
      serials: state.serials.where((s) => s.productId != productId).toList(),
    );
    autoSaveDraft();
  }

  void updateProductQuantity(String productId, double quantity) {
    state = state.copyWith(
      products: state.products
          .map(
            (p) =>
                p.productId == productId ? p.copyWith(quantity: quantity) : p,
          )
          .toList(),
    );
    autoSaveDraft();
  }

  void setProductRequiresSerials(String productId, bool requiresSerials) {
    state = state.copyWith(
      products: state.products
          .map(
            (p) => p.productId == productId
                ? p.copyWith(requiresSerials: requiresSerials)
                : p,
          )
          .toList(),
    );
    autoSaveDraft();
  }

  void addSerial(ProductSerial serial) {
    state = state.copyWith(serials: [...state.serials, serial]);
    autoSaveDraft();
  }

  void removeSerial(String id) {
    state = state.copyWith(
      serials: state.serials.where((s) => s.id != id).toList(),
    );
    autoSaveDraft();
  }

  void updateSerialsForProduct(
    String productId,
    List<ProductSerial> productSerials,
  ) {
    state = state.copyWith(
      serials: [
        ...state.serials.where((s) => s.productId != productId),
        ...productSerials,
      ],
    );
    autoSaveDraft();
  }

  Future<bool> createPurchase() async {
    if (state.supplierId == null) {
      state = state.copyWith(error: "Selecciona un proveedor");
      return false;
    }
    if (state.documentNumber == null || state.documentNumber!.isEmpty) {
      state = state.copyWith(error: "Ingresa el número de documento");
      return false;
    }
    if (state.products.isEmpty) {
      state = state.copyWith(error: "Agrega al menos un producto");
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final purchase = Purchase(
        id: state.purchaseId ?? '', // Generated by Supabase DDL if empty
        userId: '', // Ignored/Handled by Supabase Auth
        supplierId: state.supplierId,
        supplierOrderId: state.supplierOrderId,
        documentType: state.documentType,
        documentNumber: state.documentNumber!,
        invoicePhotoUrl: state.invoicePhotoUrl,
        date: state.date,
        subtotal: state.subtotal,
        tax: state.tax,
        total: state.total,
        hasMissingSerials: state.hasMissingSerials,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Convert products to PurchaseItem models for DB
      final dbProducts = state.products
          .map(
            (PurchaseItemProduct p) => PurchaseItem(
              id: p.id,
              purchaseId:
                  state.purchaseId ?? '', // To be filled by repo/DB if empty
              productId: p.productId,
              quantity: p.quantity,
              unitPrice: p.unitPrice,
              warrantyTime: p.warrantyTime,
              warrantyUnit: p.warrantyUnit,
              requiresSerials: p.requiresSerials,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .toList();

      final wasEditing = state.purchaseId != null && state.purchaseId!.isNotEmpty;
      final previousPurchaseId = state.purchaseId;

      // Save via repository
      if (wasEditing) {
        await _repository.updatePurchase(purchase, dbProducts, state.serials);
        await clearDraft(purchaseId: previousPurchaseId);
      } else {
        await _repository.createPurchase(purchase, dbProducts, state.serials);
        await clearDraft(purchaseId: null);
      }

      _ref.invalidate(paginatedPurchasesListProvider);
      _ref.invalidate(paginatedPurchaseSearchProvider);
      _ref.invalidate(purchasesProvider);
      if (wasEditing) {
        // Also invalidate details provider for this specific purchase
        _ref.invalidate(purchaseDetailsProvider(previousPurchaseId!));
      }

      state = state.copyWith(isLoading: false);
      updateBaseline(); // After save, baseline matches current state
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset({bool clearPersistedDraft = false, String? purchaseId}) {
    final isEditing =
        (state.purchaseId != null && state.purchaseId!.isNotEmpty) ||
        (purchaseId != null && purchaseId.isNotEmpty);
    final currentId = purchaseId ?? state.purchaseId;
    state = AddPurchaseState();
    updateBaseline();
    if (clearPersistedDraft) {
      clearDraft(purchaseId: isEditing ? currentId : null);
    }
    _loadFinancialParameters(); // Recargar IVA y otros parámetros
  }
}

final addPurchaseProvider =
    StateNotifierProvider<AddPurchaseNotifier, AddPurchaseState>((ref) {
      final repository = ref.watch(purchasesRepositoryProvider);
      return AddPurchaseNotifier(ref, repository);
    });
