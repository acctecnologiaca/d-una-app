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
  final String documentType; // 'Factura' or 'Nota de entrega'
  final String? documentNumber;
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
    this.documentType = 'invoice',
    this.documentNumber,
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
        documentType,
        documentNumber,
        date.year, // Ignore time components if not strictly required, but let's keep full date if possible. We only set date ignoring time usually.
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
    String? documentType,
    String? documentNumber,
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
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      date: date ?? this.date,
      taxRate: taxRate ?? this.taxRate,
      products: products ?? this.products,
      serials: serials ?? this.serials,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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
    if (state.products != _baselineState!.products) {
      return true;
    }
    if (state.serials != _baselineState!.serials) {
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
      // Update baseline if taxRate changes so we don't accidentally detect it as a user change (though taxRate isn't checked in hasChanges, this keeps baseline fresh)
      _baselineState = state;
    } catch (_) {
      // Fallback to default 16% if fetch fails
    }
  }

  void setSupplier(String id, String name, {String? taxId}) {
    state = state.copyWith(
      supplierId: id,
      supplierName: name,
      supplierTaxId: taxId,
    );
  }

  void loadFromDetails(
    Purchase purchase,
    List<PurchaseItemProduct> items,
    List<ProductSerial> serials,
    String? supplierTaxId,
  ) {
    state = state.copyWith(
      purchaseId: purchase.id,
      supplierId: purchase.supplierId,
      supplierName: purchase.supplierName,
      supplierTaxId: supplierTaxId,
      documentType: purchase.documentType,
      documentNumber: purchase.documentNumber,
      date: purchase.date,
      products: items,
      serials: serials,
      // Note: taxRate is loaded implicitly if we keep _loadFinancialParameters()
      // or we could calculate it from purchase if needed.
    );
    updateBaseline();
  }

  void setDocumentType(String type) {
    state = state.copyWith(documentType: type);
  }

  void setDocumentNumber(String number) {
    state = state.copyWith(documentNumber: number);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  bool addProduct(PurchaseItemProduct product) {
    if (state.products.any((p) => p.productId == product.productId)) {
      return false;
    }
    state = state.copyWith(products: [...state.products, product]);
    return true;
  }

  void updateProduct(PurchaseItemProduct product) {
    state = state.copyWith(
      products: state.products
          .map((p) => p.id == product.id ? product : p)
          .toList(),
    );
  }

  void removeProduct(String productId) {
    state = state.copyWith(
      products: state.products.where((p) => p.productId != productId).toList(),
      serials: state.serials.where((s) => s.productId != productId).toList(),
    );
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
  }

  void addSerial(ProductSerial serial) {
    state = state.copyWith(serials: [...state.serials, serial]);
  }

  void removeSerial(String id) {
    state = state.copyWith(
      serials: state.serials.where((s) => s.id != id).toList(),
    );
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
        documentType: state.documentType,
        documentNumber: state.documentNumber!,
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

      // Save via repository
      if (state.purchaseId != null) {
        await _repository.updatePurchase(purchase, dbProducts, state.serials);
      } else {
        await _repository.createPurchase(purchase, dbProducts, state.serials);
      }

      _ref.invalidate(purchasesProvider(null));
      if (state.purchaseId != null) {
        // Also invalidate details provider for this specific purchase
        _ref.invalidate(purchaseDetailsProvider(state.purchaseId!));
      }

      state = state.copyWith(isLoading: false);
      updateBaseline(); // After save, baseline matches current state
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = AddPurchaseState();
    updateBaseline();
    _loadFinancialParameters(); // Recargar IVA y otros parámetros
  }
}

final addPurchaseProvider =
    StateNotifierProvider<AddPurchaseNotifier, AddPurchaseState>((ref) {
      final repository = ref.watch(purchasesRepositoryProvider);
      return AddPurchaseNotifier(ref, repository);
    });
