import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/repositories/quotes_repository.dart';
import '../../../data/repositories/supabase_quotes_repository.dart';
import '../../../data/repositories/quote_product_selection_repository.dart';
import '../../../domain/models/quote_model.dart' as domain;
// import '../../../data/models/quote.dart' as data;
import '../../../domain/models/quote_validation_result.dart';
import '../../../data/models/quote_item_product.dart';

final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  return SupabaseQuotesRepository(Supabase.instance.client);
});

final quoteProductSelectionRepositoryProvider =
    Provider<QuoteProductSelectionRepository>((ref) {
      return QuoteProductSelectionRepository(Supabase.instance.client);
    });

class QuoteSelectionState {
  final Set<String> selectedIds;
  final bool isSelectionMode;

  const QuoteSelectionState({
    this.selectedIds = const {},
    this.isSelectionMode = false,
  });

  QuoteSelectionState copyWith({
    Set<String>? selectedIds,
    bool? isSelectionMode,
  }) {
    return QuoteSelectionState(
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  int get count => selectedIds.length;
  bool get isSingle => count == 1;
  bool get isMultiple => count > 1;
  bool isSelected(String id) => selectedIds.contains(id);
}

class QuoteSelectionNotifier extends StateNotifier<QuoteSelectionState> {
  QuoteSelectionNotifier() : super(const QuoteSelectionState());

  void toggle(String id) {
    final updated = Set<String>.from(state.selectedIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = state.copyWith(
      selectedIds: updated,
      isSelectionMode: updated.isNotEmpty,
    );
  }

  void selectAll(List<String> ids) {
    state = state.copyWith(selectedIds: ids.toSet(), isSelectionMode: true);
  }

  void clearSelection() {
    state = const QuoteSelectionState();
  }
}

final quoteSelectionProvider =
    StateNotifierProvider<QuoteSelectionNotifier, QuoteSelectionState>(
      (ref) => QuoteSelectionNotifier(),
    );

final quotesListProvider =
    AsyncNotifierProvider<QuotesListNotifier, List<domain.Quote>>(() {
      return QuotesListNotifier();
    });

class QuotesListNotifier extends AsyncNotifier<List<domain.Quote>> {
  @override
  Future<List<domain.Quote>> build() async {
    final repo = ref.watch(quotesRepositoryProvider);
    final validationRepo = ref.watch(quoteProductSelectionRepositoryProvider);

    // 1. Fetch Quotes (DTOs)
    final quotesDtos = await repo.getQuotes(includeArchived: true);

    if (quotesDtos.isEmpty) return [];

    // 2. Perform Batch Validation
    // Collect unique product IDs and supplier stock IDs
    final Set<String> supplierIds = {};
    final Set<String> ownProductIds = {};

    for (final q in quotesDtos) {
      if (q.products != null) {
        for (final p in q.products!) {
          if (p.sourceType == QuoteItemSourceType.affiliated &&
              p.supplierBranchStockId != null) {
            supplierIds.add(p.supplierBranchStockId!);
          } else if (p.sourceType == QuoteItemSourceType.own &&
              p.productId != null) {
            ownProductIds.add(p.productId!);
          }
        }
      }
    }

    Map<String, QuoteValidationResult> validationMap = {};
    if (supplierIds.isNotEmpty || ownProductIds.isNotEmpty) {
      final results = await validationRepo.validateQuoteItems(
        supplierBranchStockIds: supplierIds.toList(),
        productIds: ownProductIds.toList(),
      );
      validationMap = {for (var r in results) r.itemId: r};
    }

    // 3. Map to Domain Entities
    return quotesDtos.map((dto) {
      // Determine Stock Status
      domain.StockStatus stockStatus = domain.StockStatus.available;
      bool hasPriceIncrease = false;

      if (dto.products != null && dto.products!.isNotEmpty) {
        for (final p in dto.products!) {
          // Skip external or temporal products for stock validation
          if (p.sourceType == QuoteItemSourceType.external ||
              p.sourceType == QuoteItemSourceType.temporal) {
            continue;
          }

          final dbId = p.supplierBranchStockId ?? p.productId;
          if (dbId == null) continue;

          final validation = validationMap[dbId];
          
          // Check Stock
          if (validation == null) {
            stockStatus = domain.StockStatus.unavailable;
          } else if (validation.currentStock <= 0) {
            stockStatus = domain.StockStatus.unavailable;
            // No break, we might still want to check price increases on other items
          } else if (validation.currentStock < p.quantity) {
            // Only set to lowStock if not already marked as unavailable by another item
            if (stockStatus != domain.StockStatus.unavailable) {
              stockStatus = domain.StockStatus.lowStock;
            }
          }

          // Check Price Increase (using 0.01 threshold as in detail view)
          if (validation != null && validation.currentCost > (p.costPrice + 0.01)) {
            hasPriceIncrease = true;
          }
        }
      }

      return domain.Quote(
        id: dto.id,
        quoteNumber: dto.quoteNumber ?? 'S/N',
        clientName: dto.clientName ?? 'Cliente Desconocido',
        date: dto.dateIssued,
        amount: dto.total,
        status: _mapStatus(dto.status),
        stockStatus: stockStatus,
        hasPriceIncrease: hasPriceIncrease,
        categoryId: dto.categoryId,
        categoryName: dto.categoryName,
        isArchived: dto.isArchived,
        quoteTag: dto.quoteTag,
        createdAt: dto.createdAt,
      );
    }).toList();
  }

  domain.QuoteStatus _mapStatus(String status) {
    return domain.QuoteStatus.fromDbValue(status);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> archiveQuote(String id, {required bool archive}) async {
    await ref.read(quotesRepositoryProvider).archiveQuote(id, archive);
    await refresh();
  }

  Future<void> updateQuoteStatus(String id, String status) async {
    await ref.read(quotesRepositoryProvider).updateQuoteStatus(id, status);
    await refresh();
  }

  Future<void> batchUpdateStatus(List<String> ids, String status) async {
    await ref.read(quotesRepositoryProvider).batchUpdateStatus(ids, status);
    await refresh();
  }

  Future<void> batchArchive(List<String> ids, {required bool archive}) async {
    await ref.read(quotesRepositoryProvider).batchArchive(ids, archive);
    await refresh();
  }
}
