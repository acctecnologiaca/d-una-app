import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/horizontal_filter_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../core/utils/search_utils.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../domain/models/quote_model.dart'; // New Import
import '../widgets/quote_card.dart';
import '../providers/quotes_provider.dart';
import '../quote_selection_actions.dart';
import 'package:material_symbols_icons/symbols.dart';

class QuotesSearchScreen extends ConsumerStatefulWidget {
  final bool selectionMode;
  final Set<String>? excludeStatuses;
  final String? productId;

  const QuotesSearchScreen({
    super.key,
    this.selectionMode = false,
    this.excludeStatuses,
    this.productId,
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
  SortOption _currentSort = SortOption.recent;

  String _getChipLabel(Set<String> selected, String defaultLabel) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) return selected.first;
    return '${selected.first}+${selected.length - 1}';
  }

  static const _archivedLabel = 'Archivadas';

  @override
  void dispose() {
    // Clear selection when leaving this screen
    // Use post-frame callback to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return; // Already disposed
      ref.read(quoteSelectionProvider.notifier).clearSelection();
    });
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

    // Add 'Archivadas' option if any archived quotes exist
    final hasArchived = quotes.any((q) => q.isArchived);
    if (hasArchived) {
      availableStatuses.add(_archivedLabel);
    }

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Estatus',
      options: availableStatuses,
      selectedValues: _selectedStatuses,
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
    final paginatedAsync = ref.watch(paginatedQuoteSearchProvider(widget.productId));
    final selection = ref.watch(quoteSelectionProvider);

    return GenericSearchScreen<Quote>(
      title: widget.selectionMode
          ? 'Seleccionar cotización'
          : 'Buscar cotización',
      hintText: 'Cliente, número o etiqueta...',
      historyKey: 'quotes_search_history',
      isPaginatedMode: true,
      paginatedDataAsync: paginatedAsync,
      showHistory: !widget.selectionMode && widget.productId == null,
      appBarOverride: selection.isSelectionMode
          ? _buildSelectionHeader(context, ref, selection)
          : null,
      onResetFilters: () {
        setState(() {
          _selectedStatuses.clear();
          _selectedCategories.clear();
          _selectedDateRange = null;
          _currentSort = SortOption.recent;
        });
        ref.read(paginatedQuoteSearchProvider(widget.productId).notifier).updateSearch(null);
        ref
            .read(paginatedQuoteSearchProvider(widget.productId).notifier)
            .updateFilters(status: null, categoryId: null);
        ref
            .read(paginatedQuoteSearchProvider(widget.productId).notifier)
            .updateSort('date_issued', false);
      },
      onServerSearch: (query) {
        ref.read(paginatedQuoteSearchProvider(widget.productId).notifier).updateSearch(query);
      },
      onLoadMore: () {
        ref.read(paginatedQuoteSearchProvider(widget.productId).notifier).loadMore();
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
              SortOption.nameAZ,
              SortOption.nameZA,
            ],
            onSortChanged: (val) {
              setState(() => _currentSort = val);
              String orderBy = 'date_issued';
              bool ascending = false;
              if (val == SortOption.nameAZ) {
                orderBy = 'clients(name)';
                ascending = true;
              } else if (val == SortOption.nameZA) {
                orderBy = 'clients(name)';
                ascending = false;
              }
              ref
                  .read(paginatedQuoteSearchProvider(widget.productId).notifier)
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

        final matchesText = SearchUtils.matchesCombo(query, [
          quote.clientName,
          quote.quoteNumber,
          quote.quoteTag,
        ]);

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

        return matchesText && matchesArchive && matchesCategory && matchesDate;
      },
    );
  }

  PreferredSizeWidget _buildSelectionHeader(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
  ) {
    final colors = Theme.of(context).colorScheme;
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
          icon: Icon(Icons.archive_outlined, color: colors.onSurface),
          tooltip: 'Archivar',
          onPressed: () =>
              QuoteSelectionActions.handleBatchArchive(context, ref, selection),
        ),
        IconButton(
          icon: Icon(Symbols.conversion_path, color: colors.onSurface),
          tooltip: 'Cambiar estatus',
          onPressed: () =>
              QuoteSelectionActions.showStatusDialog(context, ref, selection),
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: colors.onSurface),
          onPressed: () =>
              QuoteSelectionActions.showActionsSheet(context, ref, selection),
        ),
      ],
    );
  }
}
