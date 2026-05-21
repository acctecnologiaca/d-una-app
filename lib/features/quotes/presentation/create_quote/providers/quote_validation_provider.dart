import 'dart:async';
import 'package:d_una_app/features/quotes/presentation/view_quote/providers/view_quote_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/quote_product_selection_repository.dart';
import 'create_quote_provider.dart';
import 'quote_product_selection_provider.dart';
import '../../../data/models/quote_item_product.dart';

enum QuoteValidationStatus { ok, lowStock, outOfStock, priceIncreased, missing }

class QuoteValidationItem {
  final Set<QuoteValidationStatus> statuses;
  final double currentStock;
  final double currentCost;
  final double reservedStock;

  QuoteValidationItem({
    required this.statuses,
    required this.currentStock,
    required this.currentCost,
    this.reservedStock = 0.0,
  });

  /// Convenience: true if the item has no issues.
  bool get isOk => statuses.isEmpty;
}

class QuoteValidationState {
  final Map<String, QuoteValidationItem> items;
  final bool isValidating;

  QuoteValidationState({this.items = const {}, this.isValidating = false});

  QuoteValidationState copyWith({
    Map<String, QuoteValidationItem>? items,
    bool? isValidating,
  }) {
    return QuoteValidationState(
      items: items ?? this.items,
      isValidating: isValidating ?? this.isValidating,
    );
  }
}

class QuoteValidationNotifier extends StateNotifier<QuoteValidationState> {
  final QuoteProductSelectionRepository _repository;
  final Ref _ref;
  final ProviderListenable<QuoteState> _quoteProvider;
  Timer? _debounceTimer;

  QuoteValidationNotifier(this._repository, this._ref, this._quoteProvider)
    : super(QuoteValidationState());

  void startValidation() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      validate();
    });
  }

  Future<void> validate() async {
    debugPrint('⚡ TRABAJANDO: Llamada a validate() ejecutada');
    final quoteState = _ref.read(_quoteProvider);
    final productsToValidate = quoteState.products.where((p) => p.sourceType != QuoteItemSourceType.temporal && p.sourceType != QuoteItemSourceType.external).toList();

    debugPrint('   - Productos a consultar en DB: ${productsToValidate.length}');

    if (quoteState.products.isEmpty) {
      debugPrint('   - SALIDA TEMPRANA: Cotización totalmente vacía');
      state = state.copyWith(items: {}, isValidating: false);
      return;
    }

    state = state.copyWith(isValidating: true);
    debugPrint('🚀 Iniciando validación para ${quoteState.products.length} productos totales...');

    try {
      List<dynamic> results = [];

      // Solo llamar a Supabase si hay productos reales del catálogo
      if (productsToValidate.isNotEmpty) {
        final supplierBranchStockIds = productsToValidate
            .where((p) => p.supplierBranchStockId != null)
            .map((p) => p.supplierBranchStockId!)
            .toList();

        final productIds = productsToValidate
            .where((p) => p.productId != null)
            .map((p) => p.productId!)
            .toList();

        debugPrint(
          '   - Enviando a RPC: ${supplierBranchStockIds.length} proveedores, ${productIds.length} propios',
        );

        results = await _repository.validateQuoteItems(
          supplierBranchStockIds: supplierBranchStockIds,
          productIds: productIds,
        );

        debugPrint('   - RPC respondió con ${results.length} resultados');
      }

      final Map<String, QuoteValidationItem> newValidationMap = {};

      for (final product in quoteState.products) {
        // Para productos temporales/externos, generamos un estado 'ok' automático
        if (product.sourceType == QuoteItemSourceType.temporal ||
            product.sourceType == QuoteItemSourceType.external) {
          debugPrint(
            '   - Validado automáticamente (Temporal/Externo): ${product.name}',
          );
          newValidationMap[product.id] = QuoteValidationItem(
            statuses: {}, // Empty = OK
            currentStock: 999999, // El stock de un temporal/externo se asume ilimitado
            currentCost: product.costPrice,
            reservedStock: 0.0,
          );
          continue;
        }

        final dbId = product.supplierBranchStockId ?? product.productId;
        final result = results.where((r) => r.itemId == dbId).toList();

        debugPrint('🔍 Validando: ${product.name} (DB ID: $dbId)');

        if (result.isEmpty) {
          debugPrint('     ⚠️ No se encontró en los resultados del RPC');
          newValidationMap[product.id] = QuoteValidationItem(
            statuses: {QuoteValidationStatus.missing},
            currentStock: 0,
            currentCost: 0,
          );
          continue;
        }

        final firstResult = result.first;
        final Set<QuoteValidationStatus> statuses = {};

        // Evaluate stock independently
        if (firstResult.currentStock <= 0) {
          statuses.add(QuoteValidationStatus.outOfStock);
        } else if (firstResult.currentStock < product.quantity) {
          statuses.add(QuoteValidationStatus.lowStock);
        }

        // Evaluate price independently
        if (firstResult.currentCost > (product.costPrice + 0.01)) {
          statuses.add(QuoteValidationStatus.priceIncreased);
        }

        debugPrint(
          '     ✅ Statuses: $statuses (Stock DB: ${firstResult.currentStock})',
        );

        newValidationMap[product.id] = QuoteValidationItem(
          statuses: statuses,
          currentStock: firstResult.currentStock,
          currentCost: firstResult.currentCost,
          reservedStock: firstResult.reservedStock,
        );
      }

      state = state.copyWith(items: newValidationMap, isValidating: false);
      debugPrint('🏁 Validación finalizada exitosamente');
    } catch (e, stack) {
      debugPrint('❌ ERROR EN VALIDACIÓN: $e');
      debugPrint(stack.toString());
      state = state.copyWith(isValidating: false);
    }
  }
}

// Fixed family provider
final quoteValidationProvider = StateNotifierProvider.autoDispose
    .family<QuoteValidationNotifier, QuoteValidationState, String?>((
      ref,
      quoteId,
    ) {
      final repository = ref.watch(quoteProductSelectionRepositoryProvider);

      // If quoteId is provided, we watch the family member of viewQuoteProvider
      // otherwise we watch the standard createQuoteProvider
      final ProviderListenable<QuoteState> targetQuoteProvider = quoteId != null
          ? viewQuoteProvider(quoteId)
          : createQuoteProvider;

      return QuoteValidationNotifier(repository, ref, targetQuoteProvider);
    });
