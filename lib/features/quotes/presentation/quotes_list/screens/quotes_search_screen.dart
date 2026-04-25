import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/horizontal_filter_bar.dart';
import '../../../../../core/utils/search_utils.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../domain/models/quote_model.dart'; // New Import
import '../widgets/quote_card.dart';
import '../providers/quotes_provider.dart';

class QuotesSearchScreen extends ConsumerStatefulWidget {
  const QuotesSearchScreen({super.key});

  @override
  ConsumerState<QuotesSearchScreen> createState() => _QuotesSearchScreenState();
}

class _QuotesSearchScreenState extends ConsumerState<QuotesSearchScreen> {
  // Filters
  final Set<String> _selectedStatuses = {};
  final Set<String> _selectedCategories = {};
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  String _getChipLabel(Set<String> selected, String defaultLabel) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) return selected.first;
    return '${selected.first}+${selected.length - 1}';
  }

  void _showStatusFilter(List<Quote> quotes) {
    // Collect specific strings (labels) for the filter UI
    final queryNormalized = _searchQuery.normalized;
    final availableStatuses =
        quotes
            .where((q) {
              return queryNormalized.isEmpty ||
                  q.clientName.normalized.contains(queryNormalized) ||
                  q.quoteNumber.normalized.contains(queryNormalized);
            })
            .map((e) => e.status.label)
            .toSet()
            .toList()
          ..sort();

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Estado',
      options: availableStatuses,
      selectedValues: _selectedStatuses,
      onApply: (selected) {
        setState(() {
          _selectedStatuses.clear();
          _selectedStatuses.addAll(selected);
        });
      },
    );
  }

  void _showCategoryFilter(List<Quote> quotes) {
    final availableCategories =
        quotes
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

  String _formatDateRange(DateTimeRange range) {
    final df = DateFormat('dd/MM/yy');
    return '${df.format(range.start)} - ${df.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(quotesListProvider);

    return GenericSearchScreen<Quote>(
      title: 'Buscar cotización',
      hintText: 'Cliente, número o etiqueta...',
      historyKey: 'quotes_search_history',
      data: dataAsync,
      onResetFilters: () {
        setState(() {
          _selectedStatuses.clear();
          _selectedCategories.clear();
          _selectedDateRange = null;
          _searchQuery = '';
        });
      },
      onQueryChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      itemBuilder: (context, quote) {
        return QuoteCard(
          quote: quote,
          onTap: () {
            // Navigate to details
          },
        );
      },
      filters: [
        FilterChipData(
          label: _getChipLabel(_selectedStatuses, 'Estado'),
          isActive: _selectedStatuses.isNotEmpty,
          onTap: () {
            dataAsync.whenData((quotes) => _showStatusFilter(quotes));
          },
        ),
        FilterChipData(
          label: _getChipLabel(_selectedCategories, 'Categoría'),
          isActive: _selectedCategories.isNotEmpty,
          onTap: () {
            dataAsync.whenData((quotes) => _showCategoryFilter(quotes));
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
        final matchesText = SearchUtils.matchesCombo(query, [
          quote.clientName,
          quote.quoteNumber,
          quote.quoteTag,
        ]);

        // Filter match by status label
        final matchesStatus =
            _selectedStatuses.isEmpty ||
            _selectedStatuses.contains(quote.status.label);

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

        return matchesText && matchesStatus && matchesCategory && matchesDate;
      },
    );
  }
}
