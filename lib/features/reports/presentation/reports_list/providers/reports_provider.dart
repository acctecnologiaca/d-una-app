import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../shared/models/paginated_state.dart';
import '../../../domain/repositories/service_reports_repository.dart';
import '../../../data/repositories/supabase_service_reports_repository.dart';
import '../../../domain/models/service_report_model.dart' as domain;
import '../../../data/models/service_report.dart' as data;

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

  void selectAll(List<String> allIds) {
    state = state.copyWith(
      selectedIds: allIds.toSet(),
      isSelectionMode: allIds.isNotEmpty,
    );
  }

  void clear() {
    state = const ReportSelectionState();
  }
}

final reportSelectionProvider =
    StateNotifierProvider<ReportSelectionNotifier, ReportSelectionState>((ref) {
  return ReportSelectionNotifier();
});

class ReportsFilter {
  final String? status;
  final String? categoryId;
  final DateTimeRange? dateRange;
  final bool includeArchived;
  final String? productId;
  final String? clientId;

  const ReportsFilter({
    this.status,
    this.categoryId,
    this.dateRange,
    this.includeArchived = false,
    this.productId,
    this.clientId,
  });

  ReportsFilter copyWith({
    String? status,
    String? categoryId,
    DateTimeRange? dateRange,
    bool? includeArchived,
    String? productId,
    String? clientId,
  }) {
    return ReportsFilter(
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      dateRange: dateRange ?? this.dateRange,
      includeArchived: includeArchived ?? this.includeArchived,
      productId: productId ?? this.productId,
      clientId: clientId ?? this.clientId,
    );
  }

  bool get hasFilters =>
      status != null ||
      categoryId != null ||
      dateRange != null ||
      includeArchived ||
      productId != null ||
      clientId != null;
}

final reportsFilterProvider = StateProvider<ReportsFilter>((ref) {
  return const ReportsFilter();
});

class PaginatedReportsNotifier
    extends StateNotifier<AsyncValue<PaginatedState<domain.ServiceReportSummary>>> {
  final Ref ref;
  String _orderBy = 'service_date';
  bool _ascending = false;
  String? _searchQuery;

  PaginatedReportsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadFirstPage();
  }

  Future<void> loadFirstPage({
    String? orderBy,
    bool? ascending,
    String? searchQuery,
  }) async {
    if (orderBy != null) _orderBy = orderBy;
    if (ascending != null) _ascending = ascending;
    if (searchQuery != null) _searchQuery = searchQuery;

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(serviceReportsRepositoryProvider);
      final filter = ref.read(reportsFilterProvider);

      final reports = await repo.getReportsPaginated(
        offset: 0,
        limit: 25,
        orderBy: _orderBy,
        ascending: _ascending,
        searchQuery: _searchQuery,
        statusFilter: filter.status,
        categoryFilter: filter.categoryId,
        dateRange: filter.dateRange,
        includeArchived: filter.includeArchived,
        productId: filter.productId,
        clientId: filter.clientId,
      );

      final summaries = reports.map((r) => _mapToSummary(r)).toList();

      state = AsyncValue.data(
        PaginatedState(
          items: summaries,
          hasReachedEnd: reports.length < 25,
          currentOffset: summaries.length,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.hasReachedEnd || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));

    try {
      final repo = ref.read(serviceReportsRepositoryProvider);
      final filter = ref.read(reportsFilterProvider);

      final reports = await repo.getReportsPaginated(
        offset: current.currentOffset,
        limit: 25,
        orderBy: _orderBy,
        ascending: _ascending,
        searchQuery: _searchQuery,
        statusFilter: filter.status,
        categoryFilter: filter.categoryId,
        dateRange: filter.dateRange,
        includeArchived: filter.includeArchived,
        productId: filter.productId,
        clientId: filter.clientId,
      );

      final summaries = reports.map((r) => _mapToSummary(r)).toList();

      state = AsyncValue.data(
        current.copyWith(
          items: [...current.items, ...summaries],
          hasReachedEnd: reports.length < 25,
          currentOffset: current.currentOffset + summaries.length,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(current.copyWith(isLoadingMore: false, error: e));
    }
  }

  Future<void> updateSort(String orderBy, bool ascending) async {
    _orderBy = orderBy;
    _ascending = ascending;
    await loadFirstPage();
  }

  Future<void> updateFilters({
    String? status,
    String? categoryId,
    DateTimeRange? dateRange,
    bool? includeArchived,
    String? productId,
    String? clientId,
  }) async {
    final current = ref.read(reportsFilterProvider);
    ref.read(reportsFilterProvider.notifier).state = current.copyWith(
      status: status,
      categoryId: categoryId,
      dateRange: dateRange,
      includeArchived: includeArchived,
      productId: productId,
      clientId: clientId,
    );
    await loadFirstPage();
  }

  Future<void> updateSearch(String? query) async {
    _searchQuery = query;
    await loadFirstPage();
  }

  Future<void> loadMore() async {
    await loadNextPage();
  }

  Future<void> refresh() async {
    await loadFirstPage();
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
      final summaries = raw.map((r) => _mapToSummary(r)).toList();
      state = AsyncValue.data(summaries);
    } catch (e, st) {
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

final paginatedReportsListProvider = StateNotifierProvider<
    PaginatedReportsNotifier,
    AsyncValue<PaginatedState<domain.ServiceReportSummary>>>((ref) {
  return PaginatedReportsNotifier(ref);
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

final paginatedReportSearchProvider = StateNotifierProvider.family<
    PaginatedReportsNotifier,
    AsyncValue<PaginatedState<domain.ServiceReportSummary>>,
    ReportSearchArgs?>((ref, args) {
  final notifier = PaginatedReportsNotifier(ref);
  if (args != null) {
    notifier.updateFilters(
      productId: args.productId,
      clientId: args.clientId,
    );
  }
  return notifier;
});
