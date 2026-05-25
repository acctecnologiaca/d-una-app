import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/service_model.dart';
import '../../data/repositories/supabase_services_repository.dart';
import '../../domain/repositories/services_repository.dart';
import '../../../../shared/models/paginated_state.dart';

part 'services_provider.g.dart';

@riverpod
ServicesRepository servicesRepository(Ref ref) {
  return SupabaseServicesRepository(Supabase.instance.client);
}

@Riverpod(keepAlive: true)
class Services extends _$Services {
  @override
  FutureOr<List<ServiceModel>> build() {
    return _fetchServices();
  }

  Future<List<ServiceModel>> _fetchServices() async {
    final repository = ref.read(servicesRepositoryProvider);
    return repository.getServices();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchServices());
  }

  // Search logic can be client-side if dataset is small, or server-side.
  // For MVP, filtering the current state is often enough if lists are short.
  // But let's expose a method to search server side if needed, or just filter locally.
  // Given the image shows "Buscar servicio", filtering local list is instant.

  Future<void> addService({
    required String name,
    required String? description,
    required double price,
    required String serviceRateId,
    required String? categoryId,
    required bool hasWarranty,
    int? warrantyTime,
    String? warrantyUnit,
  }) async {
    final repository = ref.read(servicesRepositoryProvider);
    final service = ServiceModel(
      id: '', // ID handled by DB/Repo
      name: name,
      description: description,
      price: price,
      serviceRateId: serviceRateId,
      categoryId: categoryId,
      hasWarranty: hasWarranty,
      warrantyTime: warrantyTime,
      warrantyUnit: warrantyUnit,
      userId: '', // handled by repo
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.createService(service);
      return _fetchServices();
    });
  }

  Future<void> updateService(ServiceModel service) async {
    final repository = ref.read(servicesRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateService(service);
      return _fetchServices();
    });
  }

  Future<void> deleteService(String id) async {
    final repository = ref.read(servicesRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteService(id);
      return _fetchServices();
    });
  }
}

// --- Paginated Services ---
final paginatedServicesProvider = AsyncNotifierProvider<PaginatedServices, PaginatedState<ServiceModel>>(() {
  return PaginatedServices();
});

class PaginatedServices extends AsyncNotifier<PaginatedState<ServiceModel>> {
  static const int _limit = 25;
  String? _searchQuery;
  String? _categoryFilter;
  String _orderBy = 'created_at';
  bool _ascending = false;

  @override
  FutureOr<PaginatedState<ServiceModel>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<ServiceModel>> _fetchPage(int offset) async {
    final repo = ref.read(servicesRepositoryProvider);

    final items = await repo.getServicesPaginated(
      offset: offset,
      limit: _limit,
      orderBy: _orderBy,
      ascending: _ascending,
      searchQuery: _searchQuery,
      categoryId: _categoryFilter,
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

  void updateFilters({String? categoryId}) {
    _categoryFilter = categoryId;
    refresh();
  }

  void updateSort(String orderBy, bool ascending) {
    _orderBy = orderBy;
    _ascending = ascending;
    refresh();
  }
}
