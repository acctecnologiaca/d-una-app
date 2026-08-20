import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../portfolio/data/repositories/supabase_services_repository.dart';
import '../../../../portfolio/domain/repositories/services_repository.dart';
import '../../../../portfolio/data/models/service_model.dart';
import '../../../../../shared/models/paginated_state.dart';

final reportServicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return SupabaseServicesRepository(Supabase.instance.client);
});

final reportServiceSuggestionsProvider =
    FutureProvider.autoDispose<List<ServiceModel>>((ref) {
  final repository = ref.watch(reportServicesRepositoryProvider);
  return repository.getServices();
});

final paginatedReportServiceSearchProvider = AsyncNotifierProvider<
    PaginatedReportServiceSearch, PaginatedState<ServiceModel>>(
  () => PaginatedReportServiceSearch(),
);

class PaginatedReportServiceSearch
    extends AsyncNotifier<PaginatedState<ServiceModel>> {
  static const int _limit = 25;
  String? _searchQuery;
  String? _categoryId;
  String? _rateId;
  String _orderBy = 'created_at';
  bool _ascending = false;

  @override
  FutureOr<PaginatedState<ServiceModel>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<ServiceModel>> _fetchPage(int offset) async {
    final repository = ref.read(reportServicesRepositoryProvider);
    final services = await repository.getServicesPaginated(
      offset: offset,
      limit: _limit,
      searchQuery: _searchQuery,
      categoryId: _categoryId,
      rateId: _rateId,
      orderBy: _orderBy,
      ascending: _ascending,
    );
    return PaginatedState<ServiceModel>(
      items: services,
      hasReachedEnd: services.length < _limit,
      currentOffset: offset,
      isLoadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) {
      return;
    }

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

  void updateFilters({String? categoryId, String? rateId}) {
    _categoryId = categoryId;
    _rateId = rateId;
    refresh();
  }

  void updateSort(String orderBy, bool ascending) {
    _orderBy = orderBy;
    _ascending = ascending;
    refresh();
  }
}
