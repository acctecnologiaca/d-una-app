import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/quote_product_selection_repository.dart';
import '../../../domain/models/quote_aggregated_product.dart';
import '../../../domain/models/quote_product_source.dart';

// Repository Provider
final quoteProductSelectionRepositoryProvider =
    Provider<QuoteProductSelectionRepository>((ref) {
      return QuoteProductSelectionRepository(Supabase.instance.client);
    });

// FutureProvider for Suggestions
final quoteProductSuggestionsProvider =
    FutureProvider.autoDispose<List<QuoteAggregatedProduct>>((ref) {
      final repository = ref.watch(quoteProductSelectionRepositoryProvider);
      return repository.getQuoteProductSuggestions();
    });

// Family FutureProvider for Sources
final quoteProductSourcesProvider = FutureProvider.autoDispose
    .family<List<QuoteProductSource>, QuoteAggregatedProduct>((ref, product) {
      final repository = ref.watch(quoteProductSelectionRepositoryProvider);
      return repository.getProductSources(
        name: product.name,
        brand: product.brand,
        model: product.model,
        uom: product.uom,
      );
    });

// Controller for managing the selection state in the sources screen
// Maps specific source_id (UUID) to a selected quantity (double)
class QuoteSourceSelectionController
    extends StateNotifier<Map<String, double>> {
  QuoteSourceSelectionController() : super({});

  void setSelection(String sourceId, double quantity) {
    if (quantity <= 0) {
      final newState = Map<String, double>.from(state);
      newState.remove(sourceId);
      state = newState;
    } else {
      state = {...state, sourceId: quantity};
    }
  }

  void toggleSelection(String sourceId, double maxStock) {
    if ((state[sourceId] ?? 0.0) > 0.0) {
      // Deselect
      final newState = Map<String, double>.from(state);
      newState.remove(sourceId);
      state = newState;
    } else {
      // Select maxStock. If maxStock is 0 (like unlimited own inventory for now), select 1
      state = {...state, sourceId: maxStock > 0 ? maxStock : 1.0};
    }
  }

  void clearSelection() {
    state = {};
  }
}

final quoteSourceSelectionProvider =
    StateNotifierProvider.autoDispose<
      QuoteSourceSelectionController,
      Map<String, double>
    >((ref) {
      return QuoteSourceSelectionController();
    });
