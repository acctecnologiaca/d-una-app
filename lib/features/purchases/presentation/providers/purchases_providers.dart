import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/purchases_repository.dart';
import 'dart:async';
import '../../domain/models/purchase_model.dart';
import '../../../../shared/models/paginated_state.dart';

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  return PurchasesRepository(Supabase.instance.client);
});

final purchasesProvider = FutureProvider.family<List<Purchase>, String?>((
  ref,
  productId,
) async {
  final repository = ref.read(purchasesRepositoryProvider);
  return await repository.getPurchases(productId: productId);
});

// --- Paginated Purchases ---
final paginatedPurchasesListProvider =
    AsyncNotifierProvider<PaginatedPurchasesList, PaginatedState<Purchase>>(
  () => PaginatedPurchasesList(),
);

class PaginatedPurchasesList
    extends AsyncNotifier<PaginatedState<Purchase>> {
  static const int _limit = 25;

  String? _searchQuery;
  String? _statusFilter;
  String _orderBy = 'date';
  bool _ascending = false;

  @override
  FutureOr<PaginatedState<Purchase>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<Purchase>> _fetchPage(int offset) async {
    final repo = ref.read(purchasesRepositoryProvider);

    final items = await repo.getPurchasesPaginated(
      offset: offset,
      limit: _limit,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      orderBy: _orderBy,
      ascending: _ascending,
    );

    return PaginatedState(
      items: items,
      hasReachedEnd: items.length < _limit,
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

  void updateFilters({String? status}) {
    _statusFilter = status;
    refresh();
  }

  void updateSort(String orderBy, bool ascending) {
    _orderBy = orderBy;
    _ascending = ascending;
    refresh();
  }
}

// --- Paginated Purchase Search (AutoDispose) ---
final paginatedPurchaseSearchProvider =
    AutoDisposeAsyncNotifierProvider<PaginatedPurchaseSearch, PaginatedState<Purchase>>(
  () => PaginatedPurchaseSearch(),
);

class PaginatedPurchaseSearch extends AutoDisposeAsyncNotifier<PaginatedState<Purchase>> {
  static const int _limit = 25;

  String? _searchQuery;
  String? _statusFilter;
  String _orderBy = 'date';
  bool _ascending = false;

  @override
  FutureOr<PaginatedState<Purchase>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<Purchase>> _fetchPage(int offset) async {
    final repo = ref.read(purchasesRepositoryProvider);

    final items = await repo.getPurchasesPaginated(
      offset: offset,
      limit: _limit,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      orderBy: _orderBy,
      ascending: _ascending,
    );

    return PaginatedState(
      items: items,
      hasReachedEnd: items.length < _limit,
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

  void updateFilters({String? status}) {
    _statusFilter = status;
    refresh();
  }

  void updateSort(String orderBy, bool ascending) {
    _orderBy = orderBy;
    _ascending = ascending;
    refresh();
  }
}
