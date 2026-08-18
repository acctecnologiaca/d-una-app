import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_clients_repository.dart';
import '../../data/models/client_model.dart';
import '../../../../shared/models/paginated_state.dart';

part 'clients_provider.g.dart';

// Repository Provider
@riverpod
SupabaseClientsRepository clientsRepository(Ref ref) {
  return SupabaseClientsRepository(Supabase.instance.client);
}

// Clients List Provider
@riverpod
class Clients extends _$Clients {
  @override
  FutureOr<List<Client>> build() async {
    return ref.read(clientsRepositoryProvider).getClients();
  }

  Future<String> addClient(Map<String, dynamic> clientData) async {
    String? newClientId;
    state = AsyncValue<List<Client>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      newClientId = await ref
          .read(clientsRepositoryProvider)
          .addClient(clientData);
      return ref.read(clientsRepositoryProvider).getClients();
    });
    ref.invalidate(paginatedClientsProvider);
    ref.invalidate(paginatedClientSearchProvider);
    return newClientId!;
  }

  Future<void> updateClient(String id, Map<String, dynamic> updates) async {
    state = AsyncValue<List<Client>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(clientsRepositoryProvider).updateClient(id, updates);
      return ref.read(clientsRepositoryProvider).getClients();
    });
    ref.invalidate(paginatedClientsProvider);
    ref.invalidate(paginatedClientSearchProvider);
  }

  Future<void> deleteClient(String id) async {
    state = AsyncValue<List<Client>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(clientsRepositoryProvider).deleteClient(id);
      return ref.read(clientsRepositoryProvider).getClients();
    });
    ref.invalidate(paginatedClientsProvider);
    ref.invalidate(paginatedClientSearchProvider);
  }

  Future<void> addContact(
    String clientId,
    Map<String, dynamic> contactData,
  ) async {
    state = AsyncValue<List<Client>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref
          .read(clientsRepositoryProvider)
          .addContact(clientId, contactData);
      return ref.read(clientsRepositoryProvider).getClients();
    });
    ref.invalidate(paginatedClientsProvider);
    ref.invalidate(paginatedClientSearchProvider);
  }

  Future<void> updateContact(String id, Map<String, dynamic> updates) async {
    state = AsyncValue<List<Client>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(clientsRepositoryProvider).updateContact(id, updates);
      return ref.read(clientsRepositoryProvider).getClients();
    });
    ref.invalidate(paginatedClientsProvider);
    ref.invalidate(paginatedClientSearchProvider);
  }

  Future<void> deleteContact(String id) async {
    state = AsyncValue<List<Client>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(clientsRepositoryProvider).deleteContact(id);
      return ref.read(clientsRepositoryProvider).getClients();
    });
    ref.invalidate(paginatedClientsProvider);
    ref.invalidate(paginatedClientSearchProvider);
  }

  Future<bool> checkClientExists(String taxId, {String? excludeId}) async {
    return ref
        .read(clientsRepositoryProvider)
        .checkClientExists(taxId, excludeId: excludeId);
  }
}

// Paginated Clients List Provider
@riverpod
class PaginatedClients extends _$PaginatedClients {
  String _orderBy = 'created_at';
  bool _ascending = false;
  String? _searchQuery;
  String? _typeFilter;

  @override
  FutureOr<PaginatedState<Client>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<Client>> _fetchPage(int offset) async {
    final items = await ref.read(clientsRepositoryProvider).getClientsPaginated(
          offset: offset,
          orderBy: _orderBy,
          ascending: _ascending,
          searchQuery: _searchQuery,
          typeFilter: _typeFilter,
        );
    return PaginatedState(
      items: items,
      currentOffset: offset,
      hasReachedEnd: items.length < PaginatedState.pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final newPage = await _fetchPage(current.nextOffset);
      state = AsyncData(current.copyWith(
        items: [...current.items, ...newPage.items],
        currentOffset: newPage.currentOffset,
        hasReachedEnd: newPage.hasReachedEnd,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: e));
      // Re-throw or log depending on needs
    }
  }

  Future<void> updateSort(String orderBy, bool ascending) async {
    if (_orderBy == orderBy && _ascending == ascending) return;
    _orderBy = orderBy;
    _ascending = ascending;
    
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isLoadingMore: false, items: [], error: null, hasReachedEnd: false, currentOffset: 0));
    }
    state = const AsyncLoading<PaginatedState<Client>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  Future<void> updateSearch(String? query) async {
    if (_searchQuery == query) return;
    _searchQuery = query;

    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isLoadingMore: false, items: [], error: null, hasReachedEnd: false, currentOffset: 0));
    }
    state = const AsyncLoading<PaginatedState<Client>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(0));
  }
  
  Future<void> updateFilters({String? typeFilter}) async {
    if (_typeFilter == typeFilter) return;
    _typeFilter = typeFilter;
    
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isLoadingMore: false, items: [], error: null, hasReachedEnd: false, currentOffset: 0));
    }
    state = const AsyncLoading<PaginatedState<Client>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isLoadingMore: false, items: [], error: null, hasReachedEnd: false, currentOffset: 0));
    }
    state = const AsyncLoading<PaginatedState<Client>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(0));
  }
}

// Paginated Client Search Provider
@riverpod
class PaginatedClientSearch extends _$PaginatedClientSearch {
  String _orderBy = 'created_at';
  bool _ascending = false;
  String? _searchQuery;
  String? _typeFilter;

  @override
  FutureOr<PaginatedState<Client>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<Client>> _fetchPage(int offset) async {
    final items = await ref.read(clientsRepositoryProvider).getClientsPaginated(
          offset: offset,
          orderBy: _orderBy,
          ascending: _ascending,
          searchQuery: _searchQuery,
          typeFilter: _typeFilter,
        );
    return PaginatedState(
      items: items,
      currentOffset: offset,
      hasReachedEnd: items.length < PaginatedState.pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final newPage = await _fetchPage(current.nextOffset);
      state = AsyncData(current.copyWith(
        items: [...current.items, ...newPage.items],
        currentOffset: newPage.currentOffset,
        hasReachedEnd: newPage.hasReachedEnd,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: e));
    }
  }

  Future<void> updateSort(String orderBy, bool ascending) async {
    if (_orderBy == orderBy && _ascending == ascending) return;
    _orderBy = orderBy;
    _ascending = ascending;
    
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isLoadingMore: false, items: [], error: null, hasReachedEnd: false, currentOffset: 0));
    }
    state = const AsyncLoading<PaginatedState<Client>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  Future<void> updateSearch(String? query) async {
    if (_searchQuery == query) return;
    _searchQuery = query;

    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isLoadingMore: false, items: [], error: null, hasReachedEnd: false, currentOffset: 0));
    }
    state = const AsyncLoading<PaginatedState<Client>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(0));
  }
  
  Future<void> updateFilters({String? typeFilter}) async {
    if (_typeFilter == typeFilter) return;
    _typeFilter = typeFilter;
    
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isLoadingMore: false, items: [], error: null, hasReachedEnd: false, currentOffset: 0));
    }
    state = const AsyncLoading<PaginatedState<Client>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _fetchPage(0));
  }
}

final clientHasLinkedDocumentsProvider =
    FutureProvider.family<bool, String>((ref, clientId) async {
  return ref.read(clientsRepositoryProvider).hasLinkedDocuments(clientId);
});


