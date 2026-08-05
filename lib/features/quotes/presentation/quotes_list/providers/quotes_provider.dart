import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../shared/models/paginated_state.dart';
import '../../../domain/repositories/quotes_repository.dart';
import '../../../data/repositories/supabase_quotes_repository.dart';
import '../../../data/repositories/quote_product_selection_repository.dart';
import '../../../domain/models/quote_model.dart' as domain;
// import '../../../data/models/quote.dart' as data;
import '../../../domain/models/quote_validation_result.dart';
import '../../../data/models/quote_item_product.dart';
import '../../../domain/models/batch_update_result.dart';

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

  Future<void> _refreshAll() async {
    await refresh();
    ref.invalidate(paginatedQuotesListProvider);
    ref.invalidate(paginatedQuoteSearchProvider);
    await ref.read(paginatedQuotesListProvider.notifier).refresh();
  }

  Future<void> archiveQuote(String id, {required bool archive}) async {
    await ref.read(quotesRepositoryProvider).archiveQuote(id, archive);
    await _refreshAll();
  }

  Future<void> updateQuoteStatus(String id, String status) async {
    await ref.read(quotesRepositoryProvider).updateQuoteStatus(id, status);
    await _refreshAll();
  }

  Future<void> updateQuoteDate(String id, DateTime newDate) async {
    await ref.read(quotesRepositoryProvider).updateQuoteDate(id, newDate);
    await _refreshAll();
  }

  Future<BatchUpdateResult> batchUpdateStatus(List<String> ids, String status) async {
    final result = await ref.read(quotesRepositoryProvider).batchUpdateStatus(ids, status);
    await _refreshAll();
    return result;
  }

  Future<void> batchArchive(List<String> ids, {required bool archive}) async {
    await ref.read(quotesRepositoryProvider).batchArchive(ids, archive);
    await _refreshAll();
  }
}

// --- Paginated Quotes ---
final paginatedQuotesListProvider = AsyncNotifierProvider<PaginatedQuotesList, PaginatedState<domain.Quote>>(() {
  return PaginatedQuotesList();
});

class PaginatedQuotesList extends AsyncNotifier<PaginatedState<domain.Quote>> {
  static const int _limit = 25;
  String? _searchQuery;
  String? _statusFilter;
  String? _categoryFilter;
  String _orderBy = 'date_issued';
  bool _ascending = false;
  bool _includeArchived = false;

  @override
  FutureOr<PaginatedState<domain.Quote>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<domain.Quote>> _fetchPage(int offset) async {
    final repo = ref.read(quotesRepositoryProvider);
    final validationRepo = ref.read(quoteProductSelectionRepositoryProvider);

    final quotesDtos = await repo.getQuotesPaginated(
      offset: offset,
      limit: _limit,
      orderBy: _orderBy,
      ascending: _ascending,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      categoryFilter: _categoryFilter,
      includeArchived: _includeArchived,
    );

    if (quotesDtos.isEmpty) {
      return PaginatedState(
        items: [],
        hasReachedEnd: true,
        currentOffset: offset,
        isLoadingMore: false,
      );
    }

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

    final domainQuotes = quotesDtos.map((dto) {
      domain.StockStatus stockStatus = domain.StockStatus.available;
      bool hasPriceIncrease = false;

      if (dto.products != null && dto.products!.isNotEmpty) {
        for (final p in dto.products!) {
          if (p.sourceType == QuoteItemSourceType.external ||
              p.sourceType == QuoteItemSourceType.temporal) {
            continue;
          }
          final dbId = p.supplierBranchStockId ?? p.productId;
          if (dbId == null) continue;
          final validation = validationMap[dbId];
          
          if (validation == null) {
            stockStatus = domain.StockStatus.unavailable;
          } else if (validation.currentStock <= 0) {
            stockStatus = domain.StockStatus.unavailable;
          } else if (validation.currentStock < p.quantity) {
            if (stockStatus != domain.StockStatus.unavailable) {
              stockStatus = domain.StockStatus.lowStock;
            }
          }
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
        status: domain.QuoteStatus.fromDbValue(dto.status),
        stockStatus: stockStatus,
        hasPriceIncrease: hasPriceIncrease,
        categoryId: dto.categoryId,
        categoryName: dto.categoryName,
        isArchived: dto.isArchived,
        quoteTag: dto.quoteTag,
        createdAt: dto.createdAt,
      );
    }).toList();

    return PaginatedState<domain.Quote>(
      items: domainQuotes,
      hasReachedEnd: quotesDtos.length < _limit,
      currentOffset: offset,
      isLoadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextOffset = current.currentOffset + _limit;
      final newPage = await _fetchPage(nextOffset);
      state = AsyncData(current.copyWith(
        items: [...current.items, ...newPage.items],
        currentOffset: nextOffset,
        hasReachedEnd: newPage.hasReachedEnd,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  void updateSearch(String? query) {
    _searchQuery = query;
    refresh();
  }

  void updateFilters({String? status, String? categoryId}) {
    _statusFilter = status;
    _categoryFilter = categoryId;
    refresh();
  }
  
  void updateIncludeArchived(bool include) {
    _includeArchived = include;
    refresh();
  }

  void updateSort(String orderBy, bool ascending) {
    _orderBy = orderBy;
    _ascending = ascending;
    refresh();
  }
}

// --- Paginated Quote Search (AutoDispose) ---
final paginatedQuoteSearchProvider = AutoDisposeAsyncNotifierProviderFamily<PaginatedQuoteSearch, PaginatedState<domain.Quote>, String?>(() {
  return PaginatedQuoteSearch();
});

class PaginatedQuoteSearch extends AutoDisposeFamilyAsyncNotifier<PaginatedState<domain.Quote>, String?> {
  static const int _limit = 25;
  String? _searchQuery;
  String? _statusFilter;
  String? _categoryFilter;
  String _orderBy = 'date_issued';
  bool _ascending = false;
  bool _includeArchived = true;

  @override
  FutureOr<PaginatedState<domain.Quote>> build(String? arg) async {
    return _fetchPage(0);
  }

  Future<PaginatedState<domain.Quote>> _fetchPage(int offset) async {
    final repo = ref.read(quotesRepositoryProvider);
    final validationRepo = ref.read(quoteProductSelectionRepositoryProvider);

    final quotesDtos = await repo.getQuotesPaginated(
      offset: offset,
      limit: _limit,
      orderBy: _orderBy,
      ascending: _ascending,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      categoryFilter: _categoryFilter,
      includeArchived: _includeArchived,
      productId: arg,
    );

    if (quotesDtos.isEmpty) {
      return PaginatedState(
        items: [],
        hasReachedEnd: true,
        currentOffset: offset,
        isLoadingMore: false,
      );
    }

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

    final domainQuotes = quotesDtos.map((dto) {
      domain.StockStatus stockStatus = domain.StockStatus.available;
      bool hasPriceIncrease = false;

      if (dto.products != null && dto.products!.isNotEmpty) {
        for (final p in dto.products!) {
          if (p.sourceType == QuoteItemSourceType.external ||
              p.sourceType == QuoteItemSourceType.temporal) {
            continue;
          }
          final dbId = p.supplierBranchStockId ?? p.productId;
          if (dbId == null) continue;
          final validation = validationMap[dbId];
          
          if (validation == null) {
            stockStatus = domain.StockStatus.unavailable;
          } else if (validation.currentStock <= 0) {
            stockStatus = domain.StockStatus.unavailable;
          } else if (validation.currentStock < p.quantity) {
            if (stockStatus != domain.StockStatus.unavailable) {
              stockStatus = domain.StockStatus.lowStock;
            }
          }
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
        status: domain.QuoteStatus.fromDbValue(dto.status),
        stockStatus: stockStatus,
        hasPriceIncrease: hasPriceIncrease,
        categoryId: dto.categoryId,
        categoryName: dto.categoryName,
        isArchived: dto.isArchived,
        quoteTag: dto.quoteTag,
        createdAt: dto.createdAt,
      );
    }).toList();

    return PaginatedState<domain.Quote>(
      items: domainQuotes,
      hasReachedEnd: quotesDtos.length < _limit,
      currentOffset: offset,
      isLoadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextOffset = current.currentOffset + _limit;
      final newPage = await _fetchPage(nextOffset);
      state = AsyncData(current.copyWith(
        items: [...current.items, ...newPage.items],
        currentOffset: nextOffset,
        hasReachedEnd: newPage.hasReachedEnd,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  void updateSearch(String? query) {
    _searchQuery = query;
    refresh();
  }

  void updateFilters({String? status, String? categoryId}) {
    _statusFilter = status;
    _categoryFilter = categoryId;
    refresh();
  }
  
  void updateIncludeArchived(bool include) {
    _includeArchived = include;
    refresh();
  }

  void updateSort(String orderBy, bool ascending) {
    _orderBy = orderBy;
    _ascending = ascending;
    refresh();
  }
}

void refreshAllQuoteProviders(WidgetRef ref) {
  ref.invalidate(quotesListProvider);
  ref.invalidate(paginatedQuotesListProvider);
  ref.invalidate(paginatedQuoteSearchProvider);
  ref.read(paginatedQuotesListProvider.notifier).refresh();
}
