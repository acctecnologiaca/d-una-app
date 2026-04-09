import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/quote_product_selection_repository.dart';
import 'create_quote_provider.dart';
import 'quote_product_selection_provider.dart';

enum QuoteValidationStatus { ok, lowStock, outOfStock, priceIncreased, missing }

class QuoteValidationItem {
  final QuoteValidationStatus status;
  final double currentStock;
  final double currentCost;

  QuoteValidationItem({
    required this.status,
    required this.currentStock,
    required this.currentCost,
  });
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
  Timer? _debounceTimer;

  QuoteValidationNotifier(this._repository, this._ref)
    : super(QuoteValidationState());

  void startValidation() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      validate();
    });
  }

  Future<void> validate() async {
    debugPrint('⚡ TRABAJANDO: Llamada a validate() ejecutada');
    final quoteState = _ref.read(createQuoteProvider);
    final products = quoteState.products.where((p) => !p.isTemporal).toList();

    debugPrint('   - Productos no temporales encontrados: ${products.length}');

    if (products.isEmpty) {
      debugPrint('   - SALIDA TEMPRANA: No hay productos para validar');
      state = state.copyWith(items: {}, isValidating: false);
      return;
    }

    state = state.copyWith(isValidating: true);
    debugPrint('🚀 Iniciando validación para ${products.length} productos...');

    try {
      final supplierProductIds = products
          .where((p) => p.supplierProductId != null)
          .map((p) => p.supplierProductId!)
          .toList();

      final productIds = products
          .where((p) => p.productId != null)
          .map((p) => p.productId!)
          .toList();

      debugPrint('   - Enviando a RPC: ${supplierProductIds.length} proveedores, ${productIds.length} propios');

      final results = await _repository.validateQuoteItems(
        supplierProductIds: supplierProductIds,
        productIds: productIds,
      );

      debugPrint('   - RPC respondió con ${results.length} resultados');

      final Map<String, QuoteValidationItem> newValidationMap = {};

      for (final product in quoteState.products) {
        if (product.isTemporal) {
          debugPrint('   - Saltando temporal: ${product.name}');
          continue;
        }

        final dbId = product.supplierProductId ?? product.productId;
        final result = results.where((r) => r.itemId == dbId).toList();
        
        debugPrint('🔍 Validando: ${product.name} (DB ID: $dbId)');

        if (result.isEmpty) {
          debugPrint('     ⚠️ No se encontró en los resultados del RPC');
          newValidationMap[product.id] = QuoteValidationItem(
            status: QuoteValidationStatus.missing,
            currentStock: 0,
            currentCost: 0,
          );
          continue;
        }

        final firstResult = result.first;
        QuoteValidationStatus status = QuoteValidationStatus.ok;

        if (firstResult.currentStock <= 0) {
          status = QuoteValidationStatus.outOfStock;
        } else if (firstResult.currentStock < product.quantity) {
          status = QuoteValidationStatus.lowStock;
        } else if (firstResult.currentCost > (product.costPrice + 0.01)) {
          status = QuoteValidationStatus.priceIncreased;
        }

        debugPrint('     ✅ Status final: $status (Stock DB: ${firstResult.currentStock})');

        newValidationMap[product.id] = QuoteValidationItem(
          status: status,
          currentStock: firstResult.currentStock,
          currentCost: firstResult.currentCost,
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

final quoteValidationProvider =
    StateNotifierProvider<QuoteValidationNotifier, QuoteValidationState>((ref) {
      final repository = ref.watch(quoteProductSelectionRepositoryProvider);
      return QuoteValidationNotifier(repository, ref);
    });
