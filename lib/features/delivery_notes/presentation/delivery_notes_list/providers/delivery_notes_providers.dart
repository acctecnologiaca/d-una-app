import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/models/paginated_state.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import '../../../domain/repositories/delivery_notes_repository.dart';
import '../../../data/repositories/supabase_delivery_notes_repository.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../../../domain/models/delivery_note_status.dart';

final deliveryNotesRepositoryProvider = Provider<DeliveryNotesRepository>((ref) {
  return SupabaseDeliveryNotesRepository(Supabase.instance.client);
});

// Multi-selection state
class DeliveryNotesSelectionState {
  final Set<String> selectedIds;
  final bool isSelectionMode;

  const DeliveryNotesSelectionState({
    this.selectedIds = const {},
    this.isSelectionMode = false,
  });

  DeliveryNotesSelectionState copyWith({
    Set<String>? selectedIds,
    bool? isSelectionMode,
  }) {
    return DeliveryNotesSelectionState(
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  int get count => selectedIds.length;
  bool get isSingle => count == 1;
  bool get isMultiple => count > 1;
  bool isSelected(String id) => selectedIds.contains(id);
}

class DeliveryNotesSelectionNotifier extends StateNotifier<DeliveryNotesSelectionState> {
  DeliveryNotesSelectionNotifier() : super(const DeliveryNotesSelectionState());

  void toggle(String id) {
    final newSelected = Set<String>.from(state.selectedIds);
    if (newSelected.contains(id)) {
      newSelected.remove(id);
    } else {
      newSelected.add(id);
    }

    state = state.copyWith(
      selectedIds: newSelected,
      isSelectionMode: newSelected.isNotEmpty,
    );
  }

  void selectAll(List<String> allIds) {
    state = state.copyWith(
      selectedIds: allIds.toSet(),
      isSelectionMode: allIds.isNotEmpty,
    );
  }

  void clearSelection() {
    state = const DeliveryNotesSelectionState();
  }

  void enterSelectionMode(String initialId) {
    state = DeliveryNotesSelectionState(
      selectedIds: {initialId},
      isSelectionMode: true,
    );
  }
}

final deliveryNotesSelectionProvider =
    StateNotifierProvider<DeliveryNotesSelectionNotifier, DeliveryNotesSelectionState>((ref) {
  return DeliveryNotesSelectionNotifier();
});

// Single delivery note detail provider
final deliveryNoteDetailProvider =
    FutureProvider.autoDispose.family<DeliveryNoteModel?, String>((ref, noteId) async {
  final repo = ref.watch(deliveryNotesRepositoryProvider);
  return repo.getDeliveryNoteWithDetails(noteId);
});

// Paginated Delivery Notes Notifier
class PaginatedDeliveryNotesNotifier
    extends StateNotifier<AsyncValue<PaginatedState<DeliveryNoteModel>>> {
  final Ref _ref;
  String? _searchQuery;
  String? _statusFilter;
  bool _includeArchived = false;
  SortOption _sortOption = SortOption.recent;
  RealtimeChannel? _realtimeChannel;

  PaginatedDeliveryNotesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initRealtimeSubscription();
    loadInitial();
  }

  void _initRealtimeSubscription() {
    if (_realtimeChannel != null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final channel = Supabase.instance.client
        .channel('public:delivery_notes_changes_${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'delivery_notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final updatedRecord = payload.newRecord;
            final updatedId = (updatedRecord['id'] ?? payload.oldRecord['id']) as String?;
            if (updatedId != null) {
              _ref.invalidate(deliveryNoteDetailProvider(updatedId));
            }
            refresh();
          },
        )
        .subscribe();

    _realtimeChannel = channel;
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    super.dispose();
  }

  String get _orderByColumn {
    switch (_sortOption) {
      case SortOption.recent:
      case SortOption.oldest:
        return 'date';
      case SortOption.nameAZ:
      case SortOption.nameZA:
        return 'client_name';
      case SortOption.orderNumberAsc:
      case SortOption.orderNumberDesc:
        return 'delivery_note_number';
      default:
        return 'created_at';
    }
  }

  bool get _isAscending {
    return _sortOption == SortOption.oldest ||
        _sortOption == SortOption.nameAZ ||
        _sortOption == SortOption.orderNumberAsc;
  }

  Future<PaginatedState<DeliveryNoteModel>> _fetchPage(int offset) async {
    final repo = _ref.read(deliveryNotesRepositoryProvider);
    final notes = await repo.getDeliveryNotesPaginated(
      offset: offset,
      limit: PaginatedState.pageSize,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      includeArchived: _includeArchived,
      orderBy: _orderByColumn,
      ascending: _isAscending,
    );

    return PaginatedState(
      items: notes,
      currentOffset: offset,
      hasReachedEnd: notes.length < PaginatedState.pageSize,
    );
  }

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    try {
      final page = await _fetchPage(0);
      state = AsyncValue.data(page);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final page = await _fetchPage(0);
      state = AsyncValue.data(page);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = await _fetchPage(current.nextOffset);
      state = AsyncValue.data(
        current.copyWith(
          items: [...current.items, ...nextPage.items],
          currentOffset: nextPage.currentOffset,
          hasReachedEnd: nextPage.hasReachedEnd,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }

  void setStatusFilter(String? status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    refresh();
  }

  void setSearchQuery(String? query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    refresh();
  }

  void setSortOption(SortOption sort) {
    if (_sortOption == sort) return;
    _sortOption = sort;
    refresh();
  }

  void setIncludeArchived(bool include) {
    if (_includeArchived == include) return;
    _includeArchived = include;
    refresh();
  }

  Future<void> updateDeliveryNoteStatus(String id, DeliveryNoteStatus status) async {
    final repo = _ref.read(deliveryNotesRepositoryProvider);
    await repo.updateDeliveryNoteStatus(id, status);
    _ref.invalidate(deliveryNoteDetailProvider(id));
    await refresh();
  }

  Future<void> archiveDeliveryNote(String id, bool archive) async {
    final repo = _ref.read(deliveryNotesRepositoryProvider);
    await repo.archiveDeliveryNote(id, archive);
    _ref.invalidate(deliveryNoteDetailProvider(id));
    await refresh();
  }

  Future<void> deleteDeliveryNote(String id) async {
    final repo = _ref.read(deliveryNotesRepositoryProvider);
    await repo.deleteDeliveryNote(id);
    _ref.invalidate(deliveryNoteDetailProvider(id));
    await refresh();
  }

  Future<void> batchUpdateStatus(List<String> ids, DeliveryNoteStatus status) async {
    final repo = _ref.read(deliveryNotesRepositoryProvider);
    await repo.batchUpdateStatus(ids, status);
    for (final id in ids) {
      _ref.invalidate(deliveryNoteDetailProvider(id));
    }
    await refresh();
  }

  Future<void> batchArchive(List<String> ids, bool archive) async {
    final repo = _ref.read(deliveryNotesRepositoryProvider);
    await repo.batchArchive(ids, archive);
    for (final id in ids) {
      _ref.invalidate(deliveryNoteDetailProvider(id));
    }
    await refresh();
  }

  Future<void> batchDelete(List<String> ids) async {
    final repo = _ref.read(deliveryNotesRepositoryProvider);
    await repo.batchDelete(ids);
    for (final id in ids) {
      _ref.invalidate(deliveryNoteDetailProvider(id));
    }
    await refresh();
  }
}

final paginatedDeliveryNotesProvider = StateNotifierProvider<
    PaginatedDeliveryNotesNotifier, AsyncValue<PaginatedState<DeliveryNoteModel>>>((ref) {
  return PaginatedDeliveryNotesNotifier(ref);
});
