import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/horizontal_filter_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../domain/models/quote_model.dart';
import '../widgets/quote_card.dart';
import '../providers/quotes_provider.dart';
import '../quote_selection_actions.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../../ads/presentation/providers/ads_provider.dart';

class QuotesSearchScreen extends ConsumerStatefulWidget {
  final bool selectionMode;
  final Set<String>? excludeStatuses;
  final String? productId;
  final String? clientId;
  final String? initialQuery;
  final bool isSearchQueryReadOnly;

  const QuotesSearchScreen({
    super.key,
    this.selectionMode = false,
    this.excludeStatuses,
    this.productId,
    this.clientId,
    this.initialQuery,
    this.isSearchQueryReadOnly = false,
  });

  @override
  ConsumerState<QuotesSearchScreen> createState() => _QuotesSearchScreenState();
}

class _QuotesSearchScreenState extends ConsumerState<QuotesSearchScreen> {
  // Filters
  final Set<String> _selectedStatuses = {};
  final Set<String> _selectedCategories = {};
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  SortOption _currentSort = SortOption.quoteNumberDesc;

  QuoteSearchArgs get _searchArgs => QuoteSearchArgs(
        productId: widget.productId,
        clientId: widget.clientId,
      );

  String _getChipLabel(Set<String> selected, String defaultLabel) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) return selected.first;
    return '${selected.first}+${selected.length - 1}';
  }

  static const _archivedLabel = 'Archivada';

  @override
  void dispose() {
    ref.read(quoteSelectionProvider.notifier).clearSelection();
    super.dispose();
  }

  void _showStatusFilter(List<Quote> quotes) {
    // Collect specific strings (labels) for the filter UI
    final queryNormalized = _searchQuery.normalized;
    final availableStatuses =
        quotes
            .where((q) {
              return queryNormalized.isEmpty ||
                  q.clientName.normalized.contains(queryNormalized) ||
                  q.quoteNumber.normalized.contains(queryNormalized) ||
                  (q.quoteTag?.normalized.contains(queryNormalized) ?? false);
            })
            .where((q) => !q.isArchived)
            .map((e) => e.status.label)
            .toSet()
            .toList()
          ..sort();

    // Add 'Archivadas' option to allow filtering archived quotes, guaranteeing it is always at the end
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

  void _showCategoryFilter(List<Quote> quotes) {
    final queryNormalized = _searchQuery.normalized;
    final availableCategories =
        quotes
            .where((q) {
              return queryNormalized.isEmpty ||
                  q.clientName.normalized.contains(queryNormalized) ||
                  q.quoteNumber.normalized.contains(queryNormalized) ||
                  (q.quoteTag?.normalized.contains(queryNormalized) ?? false);
            })
            .where(
              (q) =>
                  q.categoryName != null && q.categoryName!.trim().isNotEmpty,
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
    final status = QuoteStatus.values
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

  String _formatDateRange(DateTimeRange range) {
    final df = DateFormat('dd/MM/yy');
    return '${df.format(range.start)} - ${df.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(
      paginatedQuoteSearchProvider(_searchArgs),
    );
    final selection = ref.watch(quoteSelectionProvider);
    final allQuotes = paginatedAsync.valueOrNull?.items ?? [];

    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final occupationIds = <String>[
      if (userProfile?.occupationId != null) userProfile!.occupationId!,
      ...userProfile?.secondaryOccupationIds ?? [],
    ];

    final isAdsEnabled =
        ref.watch(isAdPlacementEnabledProvider('quotes_search'));
    final adBannersAsync = isAdsEnabled
        ? ref.watch(
            adBannersProvider(
              AdBannerParams(
                occupationIds: occupationIds,
                searchQuery: _searchQuery,
              ),
            ),
          )
        : null;

    return GenericSearchScreen<Quote>(
      title:
          widget.selectionMode ? 'Seleccionar cotización' : 'Buscar cotización',
      hintText: 'Cliente, número o producto...',
      historyKey: 'quotes_search_history',
      initialQuery: widget.initialQuery,
      readOnly: widget.isSearchQueryReadOnly,
      isPaginatedMode: true,
      paginatedDataAsync: paginatedAsync,
      banners: (selection.isSelectionMode || !isAdsEnabled)
          ? null
          : adBannersAsync?.valueOrNull,
      screenContext: 'quotes_search',
      showHistory: !widget.selectionMode &&
          widget.productId == null &&
          widget.clientId == null &&
          widget.initialQuery == null,
      appBarOverride: selection.isSelectionMode
          ? _buildSelectionHeader(context, ref, selection, allQuotes)
          : null,
      onResetFilters: () {
        setState(() {
          _selectedStatuses.clear();
          _selectedCategories.clear();
          _selectedDateRange = null;
          _currentSort = SortOption.quoteNumberDesc;
        });
        ref
            .read(paginatedQuoteSearchProvider(_searchArgs).notifier)
            .updateSearch(null);
        ref
            .read(paginatedQuoteSearchProvider(_searchArgs).notifier)
            .updateFilters(status: null, categoryId: null);
        ref
            .read(paginatedQuoteSearchProvider(_searchArgs).notifier)
            .updateSort('quote_number', false);
      },
      onServerSearch: (query) {
        ref
            .read(paginatedQuoteSearchProvider(_searchArgs).notifier)
            .updateSearch(query);
      },
      onLoadMore: () {
        ref
            .read(paginatedQuoteSearchProvider(_searchArgs).notifier)
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
              SortOption.quoteNumberDesc,
              SortOption.quoteNumberAsc,
              SortOption.recent,
              SortOption.nameAZ,
              SortOption.nameZA,
            ],
            onSortChanged: (val) {
              setState(() => _currentSort = val);
              String orderBy = 'quote_number';
              bool ascending = false;
              if (val == SortOption.quoteNumberDesc) {
                orderBy = 'quote_number';
                ascending = false;
              } else if (val == SortOption.quoteNumberAsc) {
                orderBy = 'quote_number';
                ascending = true;
              } else if (val == SortOption.recent) {
                orderBy = 'created_at';
                ascending = false;
              } else if (val == SortOption.nameAZ) {
                orderBy = 'clients(name)';
                ascending = true;
              } else if (val == SortOption.nameZA) {
                orderBy = 'clients(name)';
                ascending = false;
              }
              ref
                  .read(paginatedQuoteSearchProvider(_searchArgs).notifier)
                  .updateSort(orderBy, ascending);
            },
          ),
        ),
      ),
      comparator: null,
      itemBuilder: (context, quote) {
        return QuoteCard(
          quote: quote,
          isSelectionMode: selection.isSelectionMode,
          isSelected: selection.isSelected(quote.id),
          onLongPress: () =>
              ref.read(quoteSelectionProvider.notifier).toggle(quote.id),
          onTap: selection.isSelectionMode
              ? () => ref.read(quoteSelectionProvider.notifier).toggle(quote.id)
              : () {
                  if (widget.selectionMode) {
                    Navigator.of(context).pop(quote);
                  } else {
                    context.push('/quotes/view/${quote.id}');
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
              : 'Fecha de emisión',
          isActive: _selectedDateRange != null,
          onTap: _showDateFilter,
        ),
      ],
      filter: (quote, query) {
        if (widget.excludeStatuses != null &&
            widget.excludeStatuses!.contains(quote.status.name)) {
          return false;
        }

        // Separate 'Archivadas' from regular status labels
        final wantsArchived = _selectedStatuses.contains(_archivedLabel);
        final regularStatuses = _selectedStatuses
            .where((s) => s != _archivedLabel)
            .toSet();

        // Archive visibility logic:
        // - If no status filters selected: hide archived
        // - If 'Archivadas' selected: show archived (and filter by regular statuses if any)
        // - If only regular statuses selected: hide archived
        bool matchesArchive;
        if (_selectedStatuses.isEmpty) {
          // No filters: hide archived
          matchesArchive = !quote.isArchived;
        } else if (wantsArchived && regularStatuses.isEmpty) {
          // Only 'Archivadas' selected: show only archived
          matchesArchive = quote.isArchived;
        } else if (wantsArchived && regularStatuses.isNotEmpty) {
          // 'Archivadas' + regular statuses: show archived that match those statuses
          matchesArchive =
              quote.isArchived && regularStatuses.contains(quote.status.label);
        } else {
          // Only regular statuses: hide archived, match status
          matchesArchive =
              !quote.isArchived && regularStatuses.contains(quote.status.label);
        }

        // Filter match by category
        final matchesCategory =
            _selectedCategories.isEmpty ||
            (quote.categoryName != null &&
                _selectedCategories.contains(quote.categoryName));

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
              quote.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              quote.date.isBefore(end.add(const Duration(seconds: 1)));
        }

        return matchesArchive && matchesCategory && matchesDate;
      },
    );
  }

  PreferredSizeWidget _buildSelectionHeader(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
    List<Quote> allQuotes,
  ) {
    final colors = Theme.of(context).colorScheme;
    final selectedQuotes = allQuotes
        .where((q) => selection.selectedIds.contains(q.id))
        .toList();
    final isAllArchived =
        selectedQuotes.isNotEmpty && selectedQuotes.every((q) => q.isArchived);

    return AppBar(
      backgroundColor: colors.surface,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.close, color: colors.onSurface),
        onPressed: () =>
            ref.read(quoteSelectionProvider.notifier).clearSelection(),
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
          onPressed: () => QuoteSelectionActions.handleBatchArchive(
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
              QuoteSelectionActions.showStatusDialog(context, ref, selection),
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: colors.onSurface),
          onPressed: () => QuoteSelectionActions.showActionsSheet(
            context,
            ref,
            selection,
            allQuotes,
          ),
        ),
      ],
    );
  }
}
