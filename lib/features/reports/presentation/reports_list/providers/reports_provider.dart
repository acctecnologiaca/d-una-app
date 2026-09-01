import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../shared/models/paginated_state.dart';
import '../../../domain/repositories/service_reports_repository.dart';
import '../../../data/repositories/supabase_service_reports_repository.dart';
import '../../../domain/models/service_report_model.dart' as domain;
import '../../../data/models/service_report.dart' as data;
import '../../view_report/providers/view_report_provider.dart';

final serviceReportsRepositoryProvider = Provider<ServiceReportsRepository>((ref) {
  return SupabaseServiceReportsRepository(Supabase.instance.client);
});

class ReportSelectionState {
  final Set<String> selectedIds;
  final bool isSelectionMode;

  const ReportSelectionState({
    this.selectedIds = const {},
    this.isSelectionMode = false,
  });

  ReportSelectionState copyWith({
    Set<String>? selectedIds,
    bool? isSelectionMode,
  }) {
    return ReportSelectionState(
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  int get count => selectedIds.length;
  bool get isSingle => count == 1;
  bool get isMultiple => count > 1;
  bool isSelected(String id) => selectedIds.contains(id);
}

class ReportSelectionNotifier extends StateNotifier<ReportSelectionState> {
  ReportSelectionNotifier() : super(const ReportSelectionState());

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

  void toggleItem(String id) => toggle(id);

  void toggleSelectionMode() {
    state = state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      selectedIds: {},
    );
  }

  void exitSelectionMode() {
    clear();
  }

  void selectAll(List<String> allIds) {
    state = state.copyWith(
      selectedIds: Set.from(allIds),
      isSelectionMode: allIds.isNotEmpty,
    );
  }

  void clear() {
    state = const ReportSelectionState();
  }

  void clearSelection() => clear();
}

final reportSelectionProvider =
    StateNotifierProvider<ReportSelectionNotifier, ReportSelectionState>((ref) {
  return ReportSelectionNotifier();
});

class ReportFilterState {
  final String? status;
  final String? categoryId;
  final DateTimeRange? dateRange;
  final bool includeArchived;
  final String? productId;
  final String? clientId;

  const ReportFilterState({
    this.status,
    this.categoryId,
    this.dateRange,
    this.includeArchived = false,
    this.productId,
    this.clientId,
  });

  ReportFilterState copyWith({
    String? status,
    String? categoryId,
    DateTimeRange? dateRange,
    bool? includeArchived,
    String? productId,
    String? clientId,
    bool clearStatus = false,
    bool clearCategory = false,
    bool clearDateRange = false,
    bool clearProduct = false,
    bool clearClient = false,
  }) {
    return ReportFilterState(
      status: clearStatus ? null : (status ?? this.status),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      includeArchived: includeArchived ?? this.includeArchived,
      productId: clearProduct ? null : (productId ?? this.productId),
      clientId: clearClient ? null : (clientId ?? this.clientId),
    );
  }

  bool get hasActiveFilters =>
      status != null ||
      categoryId != null ||
      dateRange != null ||
      includeArchived ||
      productId != null ||
      clientId != null;
}

class ReportFilterNotifier extends StateNotifier<ReportFilterState> {
  ReportFilterNotifier() : super(const ReportFilterState());

  void setStatus(String? status) {
    if (status == null) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(status: status);
    }
  }

  void setCategory(String? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(categoryId: categoryId);
    }
  }

  void setDateRange(DateTimeRange? range) {
    if (range == null) {
      state = state.copyWith(clearDateRange: true);
    } else {
      state = state.copyWith(dateRange: range);
    }
  }

  void setIncludeArchived(bool include) {
    state = state.copyWith(includeArchived: include);
  }

  void setProduct(String? productId) {
    if (productId == null) {
      state = state.copyWith(clearProduct: true);
    } else {
      state = state.copyWith(productId: productId);
    }
  }

  void setClient(String? clientId) {
    if (clientId == null) {
      state = state.copyWith(clearClient: true);
    } else {
      state = state.copyWith(clientId: clientId);
    }
  }

  void updateFilters({
    String? status,
    String? categoryId,
    DateTimeRange? dateRange,
    bool? includeArchived,
    String? productId,
    String? clientId,
  }) {
    state = state.copyWith(
      status: status,
      categoryId: categoryId,
      dateRange: dateRange,
      includeArchived: includeArchived,
      productId: productId,
      clientId: clientId,
    );
  }

  void reset() {
    state = const ReportFilterState();
  }
}

final reportsFilterProvider =
    StateNotifierProvider<ReportFilterNotifier, ReportFilterState>((ref) {
  return ReportFilterNotifier();
});

class PaginatedReportsNotifier
    extends AsyncNotifier<PaginatedState<domain.ServiceReportSummary>> {
  static const int _limit = 25;
  String _orderBy = 'service_date';
  bool _ascending = false;
  String? _searchQuery;
  String? _statusFilter;
  String? _categoryFilter;
  DateTimeRange? _dateRange;
  bool _includeArchived = false;
  String? _productId;
  String? _clientId;
  RealtimeChannel? _realtimeChannel;

  @override
  FutureOr<PaginatedState<domain.ServiceReportSummary>> build() async {
    _initRealtimeSubscription();
    return _fetchPage(0);
  }

  void _initRealtimeSubscription() {
    if (_realtimeChannel != null) return;

    final channel = Supabase.instance.client
        .channel('public:service_reports_changes_${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'service_reports',
          callback: (payload) {
            final updatedRecord = payload.newRecord;
            final updatedId = updatedRecord['id'] as String?;
            if (updatedId != null) {
              ref.invalidate(viewReportProvider(updatedId));
            }
            refresh();
          },
        )
        .subscribe();

    _realtimeChannel = channel;

    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
    });
  }

  Future<PaginatedState<domain.ServiceReportSummary>> _fetchPage(int offset) async {
    final repo = ref.read(serviceReportsRepositoryProvider);
    final filter = ref.read(reportsFilterProvider);

    final reports = await repo.getReportsPaginated(
      offset: offset,
      limit: _limit,
      orderBy: _orderBy,
      ascending: _ascending,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter ?? filter.status,
      categoryFilter: _categoryFilter ?? filter.categoryId,
      dateRange: _dateRange ?? filter.dateRange,
      includeArchived: _includeArchived || filter.includeArchived,
      productId: _productId ?? filter.productId,
      clientId: _clientId ?? filter.clientId,
    );

    final summaries = reports.map((r) => _mapToSummary(r)).toList();

    return PaginatedState(
      items: summaries,
      hasReachedEnd: reports.length < _limit,
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

  void updateSort(String orderBy, bool ascending) {
    _orderBy = orderBy;
    _ascending = ascending;
    refresh();
  }

  void updateFilters({
    String? status,
    String? categoryId,
    DateTimeRange? dateRange,
    bool? includeArchived,
    String? productId,
    String? clientId,
  }) {
    ref.read(reportsFilterProvider.notifier).updateFilters(
      status: status,
      categoryId: categoryId,
      dateRange: dateRange,
      includeArchived: includeArchived,
      productId: productId,
      clientId: clientId,
    );
    _statusFilter = status;
    _categoryFilter = categoryId;
    _dateRange = dateRange;
    if (includeArchived != null) _includeArchived = includeArchived;
    if (productId != null) _productId = productId;
    if (clientId != null) _clientId = clientId;
    refresh();
  }

  void updateSearch(String? query) {
    _searchQuery = query;
    refresh();
  }

  domain.ServiceReportSummary _mapToSummary(data.ServiceReport r) {
    String? duration;
    if (r.durationMinutes != null && r.durationMinutes! > 0) {
      final hours = r.durationMinutes! ~/ 60;
      final mins = r.durationMinutes! % 60;
      if (hours > 0 && mins > 0) {
        duration = '${hours}h ${mins}m';
      } else if (hours > 0) {
        duration = '${hours}h';
      } else {
        duration = '${mins}m';
      }
    }

    return domain.ServiceReportSummary(
      id: r.id,
      reportNumber: r.reportNumber ?? 'RS-PENDIENTE',
      clientName: r.clientName ?? 'Cliente Desconocido',
      date: r.serviceDate,
      amount: r.total,
      categoryId: r.categoryId,
      categoryName: r.categoryName,
      advisorId: r.advisorId,
      advisorName: r.advisorName,
      status: domain.ServiceReportStatus.fromDbValue(r.status),
      interventionType: domain.InterventionType.fromDbValue(r.interventionType),
      isArchived: r.isArchived,
      reportTag: r.reportTag,
      createdAt: r.createdAt,
      durationText: duration,
    );
  }
}

class ReportsListNotifier extends StateNotifier<AsyncValue<List<domain.ServiceReportSummary>>> {
  final Ref ref;

  ReportsListNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadReports();
  }

  Future<void> loadReports() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(serviceReportsRepositoryProvider);
      final raw = await repo.getReports(includeArchived: true);
      if (!mounted) return;
      final summaries = raw.map((r) => _mapToSummary(r)).toList();
      state = AsyncValue.data(summaries);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  domain.ServiceReportSummary _mapToSummary(data.ServiceReport r) {
    return domain.ServiceReportSummary(
      id: r.id,
      reportNumber: r.reportNumber ?? 'RS-PENDIENTE',
      clientName: r.clientName ?? 'Cliente Desconocido',
      date: r.serviceDate,
      amount: r.total,
      categoryId: r.categoryId,
      categoryName: r.categoryName,
      advisorId: r.advisorId,
      advisorName: r.advisorName,
      status: domain.ServiceReportStatus.fromDbValue(r.status),
      interventionType: domain.InterventionType.fromDbValue(r.interventionType),
      isArchived: r.isArchived,
      reportTag: r.reportTag,
      createdAt: r.createdAt,
    );
  }

  Future<void> refresh() async {
    await loadReports();
    ref.invalidate(paginatedReportsListProvider);
  }

  Future<void> archiveReport(String id, {required bool archive}) async {
    await ref.read(serviceReportsRepositoryProvider).archiveReport(id, archive);
    await refresh();
  }

  Future<void> updateReportStatus(String id, String status) async {
    await ref.read(serviceReportsRepositoryProvider).updateReportStatus(id, status);
    await refresh();
  }

  Future<void> updateReportDate(String id, DateTime newDate) async {
    await ref.read(serviceReportsRepositoryProvider).updateReportDate(id, newDate);
    await refresh();
  }

  Future<List<String>> batchUpdateStatus(List<String> ids, String status) async {
    final result = await ref.read(serviceReportsRepositoryProvider).batchUpdateStatus(ids, status);
    await refresh();
    return result;
  }

  Future<void> batchArchive(List<String> ids, {required bool archive}) async {
    await ref.read(serviceReportsRepositoryProvider).batchArchive(ids, archive);
    await refresh();
  }
}

final reportsListProvider = StateNotifierProvider<ReportsListNotifier, AsyncValue<List<domain.ServiceReportSummary>>>((ref) {
  return ReportsListNotifier(ref);
});

void refreshAllReportProviders(dynamic ref) {
  ref.invalidate(reportsListProvider);
  ref.invalidate(paginatedReportsListProvider);
  ref.invalidate(paginatedReportSearchProvider);
}

final paginatedReportsListProvider = AsyncNotifierProvider<
    PaginatedReportsNotifier,
    PaginatedState<domain.ServiceReportSummary>>(() {
  return PaginatedReportsNotifier();
});

class ReportSearchArgs {
  final String? productId;
  final String? clientId;

  const ReportSearchArgs({this.productId, this.clientId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportSearchArgs &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          clientId == other.clientId;

  @override
  int get hashCode => Object.hash(productId, clientId);
}

final paginatedReportSearchProvider = AutoDisposeAsyncNotifierProviderFamily<
    PaginatedReportSearch,
    PaginatedState<domain.ServiceReportSummary>,
    ReportSearchArgs?>(() {
  return PaginatedReportSearch();
});

class PaginatedReportSearch extends AutoDisposeFamilyAsyncNotifier<
    PaginatedState<domain.ServiceReportSummary>,
    ReportSearchArgs?> {
  static const int _limit = 25;
  String _orderBy = 'service_date';
  bool _ascending = false;
  String? _searchQuery;
  String? _statusFilter;
  String? _categoryFilter;
  DateTimeRange? _dateRange;
  bool _includeArchived = true;

  @override
  FutureOr<PaginatedState<domain.ServiceReportSummary>> build(ReportSearchArgs? arg) async {
    return _fetchPage(0, arg);
  }

  Future<PaginatedState<domain.ServiceReportSummary>> _fetchPage(int offset, ReportSearchArgs? arg) async {
    final repo = ref.read(serviceReportsRepositoryProvider);

    final reports = await repo.getReportsPaginated(
      offset: offset,
      limit: _limit,
      orderBy: _orderBy,
      ascending: _ascending,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      categoryFilter: _categoryFilter,
      dateRange: _dateRange,
      includeArchived: _includeArchived,
      productId: arg?.productId,
      clientId: arg?.clientId,
    );

    final summaries = reports.map((r) => _mapToSummary(r)).toList();

    return PaginatedState(
      items: summaries,
      hasReachedEnd: reports.length < _limit,
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
      final newPage = await _fetchPage(nextOffset, arg);
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
    state = await AsyncValue.guard(() => _fetchPage(0, arg));
  }

  void updateSort(String orderBy, bool ascending) {
    _orderBy = orderBy;
    _ascending = ascending;
    refresh();
  }

  void updateFilters({
    String? status,
    String? categoryId,
    DateTimeRange? dateRange,
    bool? includeArchived,
  }) {
    _statusFilter = status;
    _categoryFilter = categoryId;
    if (dateRange != null) _dateRange = dateRange;
    if (includeArchived != null) _includeArchived = includeArchived;
    refresh();
  }

  void updateSearch(String? query) {
    _searchQuery = query;
    refresh();
  }

  domain.ServiceReportSummary _mapToSummary(data.ServiceReport r) {
    String? duration;
    if (r.durationMinutes != null && r.durationMinutes! > 0) {
      final hours = r.durationMinutes! ~/ 60;
      final mins = r.durationMinutes! % 60;
      if (hours > 0 && mins > 0) {
        duration = '${hours}h ${mins}m';
      } else if (hours > 0) {
        duration = '${hours}h';
      } else {
        duration = '${mins}m';
      }
    }

    return domain.ServiceReportSummary(
      id: r.id,
      reportNumber: r.reportNumber ?? 'RS-PENDIENTE',
      clientName: r.clientName ?? 'Cliente Desconocido',
      date: r.serviceDate,
      amount: r.total,
      categoryId: r.categoryId,
      categoryName: r.categoryName,
      advisorId: r.advisorId,
      advisorName: r.advisorName,
      status: domain.ServiceReportStatus.fromDbValue(r.status),
      interventionType: domain.InterventionType.fromDbValue(r.interventionType),
      isArchived: r.isArchived,
      reportTag: r.reportTag,
      createdAt: r.createdAt,
      durationText: duration,
    );
  }
}
