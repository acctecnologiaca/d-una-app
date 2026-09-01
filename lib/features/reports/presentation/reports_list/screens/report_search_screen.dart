import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/horizontal_filter_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../domain/models/service_report_model.dart';
import '../widgets/service_report_card.dart';
import '../providers/reports_provider.dart';
import '../report_selection_actions.dart';
import 'package:material_symbols_icons/symbols.dart';

class ReportSearchScreen extends ConsumerStatefulWidget {
  final bool selectionMode;
  final Set<String>? excludeStatuses;
  final String? productId;
  final String? clientId;
  final String? initialQuery;
  final bool isSearchQueryReadOnly;

  const ReportSearchScreen({
    super.key,
    this.selectionMode = false,
    this.excludeStatuses,
    this.productId,
    this.clientId,
    this.initialQuery,
    this.isSearchQueryReadOnly = false,
  });

  @override
  ConsumerState<ReportSearchScreen> createState() => _ReportSearchScreenState();
}

class _ReportSearchScreenState extends ConsumerState<ReportSearchScreen> {
  // Filters
  final Set<String> _selectedStatuses = {};
  final Set<String> _selectedInterventions = {};
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedClients = {};
  final Set<String> _selectedAdvisors = {};
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  SortOption _currentSort = SortOption.recent;

  ReportSearchArgs get _searchArgs =>
      ReportSearchArgs(productId: widget.productId, clientId: widget.clientId);

  String _getChipLabel(Set<String> selected, String defaultLabel) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) return selected.first;
    return '${selected.first}+${selected.length - 1}';
  }

  static const _archivedLabel = 'Archivado';

  @override
  void dispose() {
    ref.read(reportSelectionProvider.notifier).clear();
    super.dispose();
  }

  void _showStatusFilter(List<ServiceReportSummary> reports) {
    final queryNormalized = _searchQuery.normalized;
    final availableStatuses =
        reports
            .where((r) {
              return queryNormalized.isEmpty ||
                  r.clientName.normalized.contains(queryNormalized) ||
                  r.reportNumber.normalized.contains(queryNormalized) ||
                  (r.reportTag?.normalized.contains(queryNormalized) ?? false);
            })
            .where((r) => !r.isArchived)
            .map((e) => e.status.label)
            .toSet()
            .toList()
          ..sort();

    availableStatuses.remove(_archivedLabel);
    availableStatuses.add(_archivedLabel);

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Estatus',
      options: availableStatuses,
      selectedValues: _selectedStatuses,
      sortOptions: false,
      leadingBuilder: (value) =>
          _buildStatusLeading(value, Theme.of(context).colorScheme),
      onApply: (selected) {
        setState(() {
          _selectedStatuses.clear();
          _selectedStatuses.addAll(selected);
        });
      },
    );
  }

  void _showInterventionFilter(List<ServiceReportSummary> reports) {
    final queryNormalized = _searchQuery.normalized;
    final availableInterventions =
        reports
            .where((r) {
              return queryNormalized.isEmpty ||
                  r.clientName.normalized.contains(queryNormalized) ||
                  r.reportNumber.normalized.contains(queryNormalized) ||
                  (r.reportTag?.normalized.contains(queryNormalized) ?? false);
            })
            .map((e) => e.interventionType.label)
            .toSet()
            .toList()
          ..sort();

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Tipo de servicio',
      options: availableInterventions,
      selectedValues: _selectedInterventions,
      leadingBuilder: (value) => _buildInterventionLeading(value),
      onApply: (selected) {
        setState(() {
          _selectedInterventions.clear();
          _selectedInterventions.addAll(selected);
        });
      },
    );
  }

  void _showCategoryFilter(List<ServiceReportSummary> reports) {
    final queryNormalized = _searchQuery.normalized;
    final availableCategories =
        reports
            .where((r) {
              return queryNormalized.isEmpty ||
                  r.clientName.normalized.contains(queryNormalized) ||
                  r.reportNumber.normalized.contains(queryNormalized) ||
                  (r.reportTag?.normalized.contains(queryNormalized) ?? false);
            })
            .where(
              (r) =>
                  r.categoryName != null && r.categoryName!.trim().isNotEmpty,
            )
            .map((e) => e.categoryName!.trim())
            .toSet()
            .toList()
          ..sort();

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Categoría',
      options: availableCategories,
      selectedValues: _selectedCategories,
      onApply: (selected) {
        setState(() {
          _selectedCategories.clear();
          _selectedCategories.addAll(selected);
        });
      },
    );
  }

  void _showAdvisorFilter(List<ServiceReportSummary> reports) {
    final queryNormalized = _searchQuery.normalized;
    final availableAdvisors =
        reports
            .where((r) {
              return queryNormalized.isEmpty ||
                  r.clientName.normalized.contains(queryNormalized) ||
                  r.reportNumber.normalized.contains(queryNormalized) ||
                  (r.reportTag?.normalized.contains(queryNormalized) ?? false);
            })
            .where(
              (r) => r.advisorName != null && r.advisorName!.trim().isNotEmpty,
            )
            .expand((r) => r.advisorName!.split(',').map((e) => e.trim()))
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Técnico',
      options: availableAdvisors,
      selectedValues: _selectedAdvisors,
      onApply: (selected) {
        setState(() {
          _selectedAdvisors.clear();
          _selectedAdvisors.addAll(selected);
        });
      },
    );
  }

  Future<void> _showDateFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Widget _buildStatusLeading(String statusLabel, ColorScheme colors) {
    final status = ServiceReportStatus.values
        .where((s) => s.label == statusLabel)
        .firstOrNull;

    if (status != null) {
      return Image.asset(status.iconPath, width: 24, height: 24);
    }

    if (statusLabel == _archivedLabel) {
      return Icon(
        Icons.archive_outlined,
        size: 24,
        color: colors.onSurfaceVariant,
      );
    }

    return CircleAvatar(
      radius: 12,
      backgroundColor: colors.secondaryContainer,
      child: Text(
        statusLabel.isNotEmpty ? statusLabel[0].toUpperCase() : '?',
        style: TextStyle(color: colors.onSecondaryContainer, fontSize: 12),
      ),
    );
  }

  Widget _buildInterventionLeading(String interventionLabel) {
    final intervention = InterventionType.values
        .where((i) => i.label == interventionLabel)
        .firstOrNull;

    if (intervention != null) {
      return Icon(intervention.icon, size: 22);
    }

    return const Icon(Icons.build_outlined, size: 22);
  }

  String _formatDateRange(DateTimeRange range) {
    final df = DateFormat('dd/MM/yy');
    return '${df.format(range.start)} - ${df.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(
      paginatedReportSearchProvider(_searchArgs),
    );
    final selection = ref.watch(reportSelectionProvider);
    final allReports = paginatedAsync.valueOrNull?.items ?? [];

    return GenericSearchScreen<ServiceReportSummary>(
      title: widget.selectionMode ? 'Seleccionar reporte' : 'Buscar reporte',
      hintText: 'Cliente, número o tag...',
      historyKey: 'reports_search_history',
      initialQuery: widget.initialQuery,
      readOnly: widget.isSearchQueryReadOnly,
      isPaginatedMode: true,
      paginatedDataAsync: paginatedAsync,
      showHistory:
          !widget.selectionMode &&
          widget.productId == null &&
          widget.clientId == null &&
          widget.initialQuery == null,
      appBarOverride: selection.isSelectionMode
          ? _buildSelectionHeader(context, ref, selection, allReports)
          : null,
      onResetFilters: () {
        setState(() {
          _selectedStatuses.clear();
          _selectedInterventions.clear();
          _selectedCategories.clear();
          _selectedClients.clear();
          _selectedAdvisors.clear();
          _selectedDateRange = null;
          _currentSort = SortOption.recent;
        });
        ref
            .read(paginatedReportSearchProvider(_searchArgs).notifier)
            .updateSearch(null);
        ref
            .read(paginatedReportSearchProvider(_searchArgs).notifier)
            .updateFilters(status: null, categoryId: null);
        ref
            .read(paginatedReportSearchProvider(_searchArgs).notifier)
            .updateSort('service_date', false);
      },
      onServerSearch: (query) {
        ref
            .read(paginatedReportSearchProvider(_searchArgs).notifier)
            .updateSearch(query);
      },
      onLoadMore: () {
        ref
            .read(paginatedReportSearchProvider(_searchArgs).notifier)
            .loadMore();
      },
      onQueryChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      bottomFilterWidget: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SortSelector(
            currentSort: _currentSort,
            options: const [
              SortOption.recent,
              SortOption.oldest,
              SortOption.highestPrice,
              SortOption.lowestPrice,
            ],
            onSortChanged: (val) {
              setState(() => _currentSort = val);
              String orderBy = 'service_date';
              bool ascending = false;
              if (val == SortOption.recent) {
                orderBy = 'service_date';
                ascending = false;
              } else if (val == SortOption.oldest) {
                orderBy = 'service_date';
                ascending = true;
              } else if (val == SortOption.highestPrice) {
                orderBy = 'total';
                ascending = false;
              } else if (val == SortOption.lowestPrice) {
                orderBy = 'total';
                ascending = true;
              }
              ref
                  .read(paginatedReportSearchProvider(_searchArgs).notifier)
                  .updateSort(orderBy, ascending);
            },
          ),
        ),
      ),
      comparator: null,
      itemBuilder: (context, report) {
        return ServiceReportCard(
          report: report,
          isSelectionMode: selection.isSelectionMode,
          isSelected: selection.isSelected(report.id),
          onLongPress: () =>
              ref.read(reportSelectionProvider.notifier).toggle(report.id),
          onTap: selection.isSelectionMode
              ? () =>
                    ref.read(reportSelectionProvider.notifier).toggle(report.id)
              : () {
                  if (widget.selectionMode) {
                    Navigator.of(context).pop(report);
                  } else {
                    context.push('/reports/${report.id}');
                  }
                },
        );
      },
      filters: [
        FilterChipData(
          label: _getChipLabel(_selectedStatuses, 'Estatus'),
          isActive: _selectedStatuses.isNotEmpty,
          onTap: () {
            final items = paginatedAsync.valueOrNull?.items ?? [];
            _showStatusFilter(items);
          },
        ),
        FilterChipData(
          label: _getChipLabel(_selectedInterventions, 'Tipo'),
          isActive: _selectedInterventions.isNotEmpty,
          onTap: () {
            final items = paginatedAsync.valueOrNull?.items ?? [];
            _showInterventionFilter(items);
          },
        ),
        FilterChipData(
          label: _getChipLabel(_selectedCategories, 'Categoría'),
          isActive: _selectedCategories.isNotEmpty,
          onTap: () {
            final items = paginatedAsync.valueOrNull?.items ?? [];
            _showCategoryFilter(items);
          },
        ),

        FilterChipData(
          label: _selectedDateRange != null
              ? _formatDateRange(_selectedDateRange!)
              : 'Fecha',
          isActive: _selectedDateRange != null,
          onTap: _showDateFilter,
        ),
        FilterChipData(
          label: _getChipLabel(_selectedAdvisors, 'Técnico'),
          isActive: _selectedAdvisors.isNotEmpty,
          onTap: () {
            final items = paginatedAsync.valueOrNull?.items ?? [];
            _showAdvisorFilter(items);
          },
        ),
      ],
      filter: (report, query) {
        if (widget.excludeStatuses != null &&
            widget.excludeStatuses!.contains(report.status.name)) {
          return false;
        }

        // Archive visibility logic
        final wantsArchived = _selectedStatuses.contains(_archivedLabel);
        final regularStatuses = _selectedStatuses
            .where((s) => s != _archivedLabel)
            .toSet();

        bool matchesArchive;
        if (_selectedStatuses.isEmpty) {
          matchesArchive = !report.isArchived;
        } else if (wantsArchived && regularStatuses.isEmpty) {
          matchesArchive = report.isArchived;
        } else if (wantsArchived && regularStatuses.isNotEmpty) {
          matchesArchive =
              report.isArchived &&
              regularStatuses.contains(report.status.label);
        } else {
          matchesArchive =
              !report.isArchived &&
              regularStatuses.contains(report.status.label);
        }

        // Filter match by intervention
        final matchesIntervention =
            _selectedInterventions.isEmpty ||
            _selectedInterventions.contains(report.interventionType.label);

        // Filter match by category
        final matchesCategory =
            _selectedCategories.isEmpty ||
            (report.categoryName != null &&
                _selectedCategories.contains(report.categoryName));

        // Filter match by client
        final matchesClient =
            _selectedClients.isEmpty ||
            _selectedClients.contains(report.clientName);

        // Filter match by advisor
        final matchesAdvisor =
            _selectedAdvisors.isEmpty ||
            (report.advisorName != null &&
                _selectedAdvisors.any((selected) =>
                    report.advisorName!.toLowerCase().contains(selected.toLowerCase())));

        // Filter match by date range
        bool matchesDate = true;
        if (_selectedDateRange != null) {
          final start = DateTime(
            _selectedDateRange!.start.year,
            _selectedDateRange!.start.month,
            _selectedDateRange!.start.day,
          );
          final end = DateTime(
            _selectedDateRange!.end.year,
            _selectedDateRange!.end.month,
            _selectedDateRange!.end.day,
            23,
            59,
            59,
          );
          matchesDate =
              report.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              report.date.isBefore(end.add(const Duration(seconds: 1)));
        }

        return matchesArchive &&
            matchesIntervention &&
            matchesCategory &&
            matchesClient &&
            matchesAdvisor &&
            matchesDate;
      },
    );
  }

  PreferredSizeWidget _buildSelectionHeader(
    BuildContext context,
    WidgetRef ref,
    ReportSelectionState selection,
    List<ServiceReportSummary> allReports,
  ) {
    final colors = Theme.of(context).colorScheme;
    final selectedReports = allReports
        .where((r) => selection.selectedIds.contains(r.id))
        .toList();
    final isAllArchived =
        selectedReports.isNotEmpty &&
        selectedReports.every((r) => r.isArchived);

    return AppBar(
      backgroundColor: colors.surface,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.close, color: colors.onSurface),
        onPressed: () => ref.read(reportSelectionProvider.notifier).clear(),
      ),
      title: Text(
        '${selection.count} Ítem${selection.count > 1 ? 's' : ''}',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: colors.onSurface,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            isAllArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
            color: colors.onSurface,
          ),
          tooltip: isAllArchived ? 'Desarchivar' : 'Archivar',
          onPressed: () => ReportSelectionActions.handleBatchArchive(
            context,
            ref,
            selection,
            archive: !isAllArchived,
          ),
        ),
        IconButton(
          icon: Icon(Symbols.conversion_path, color: colors.onSurface),
          tooltip: 'Cambiar estatus',
          onPressed: () =>
              ReportSelectionActions.showStatusDialog(context, ref, selection),
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: colors.onSurface),
          onPressed: () => ReportSelectionActions.showActionsSheet(
            context,
            ref,
            selection,
            allReports,
          ),
        ),
      ],
    );
  }
}
