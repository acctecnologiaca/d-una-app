import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/horizontal_filter_bar.dart'; // Needed for FilterChipData
import '../../../../../core/utils/string_extensions.dart';
import '../../../domain/models/quote_model.dart'; // New Import
import '../widgets/quote_card.dart'; // New Import

// Mock Provider for Quotes (since real provider not ready or using local list in ListScreen)
// Ideally, we should have a provider. For now, I'll create a simple FutureProvider returning mock data similar to ListScreen.
final quotesSearchProvider = FutureProvider<List<Quote>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300)); // Sim delay
  return [
    Quote(
      id: '1',
      quoteNumber: '#C-00000010',
      clientName: 'Corporación Telemic, C.A.',
      date: DateTime(2025, 10, 6),
      amount: 2750.00,
      status: QuoteStatus.draft,
      stockStatus: StockStatus.available,
    ),
    Quote(
      id: '2',
      quoteNumber: '#C-00000009',
      clientName: 'ACC Tecnología, C.A.',
      date: DateTime(2025, 10, 2),
      amount: 150.00,
      status: QuoteStatus.rejected,
      stockStatus: StockStatus.unavailable,
      isArchived: true,
    ),
    Quote(
      id: '3',
      quoteNumber: '#C-00000008',
      clientName: 'Agrovivar, C.A.',
      date: DateTime(2025, 10, 1),
      amount: 755.00,
      status: QuoteStatus.sent,
      stockStatus: StockStatus.available,
    ),
    Quote(
      id: '4',
      quoteNumber: '#C-00000007',
      clientName: 'Cauchos ND, C.A.',
      date: DateTime(2025, 9, 30),
      amount: 560.00,
      status: QuoteStatus.inReview, // mapped 'viewed' => inReview check
      stockStatus: StockStatus.unavailable,
      isArchived: true,
    ),
  ];
});

class QuotesSearchScreen extends ConsumerStatefulWidget {
  const QuotesSearchScreen({super.key});

  @override
  ConsumerState<QuotesSearchScreen> createState() => _QuotesSearchScreenState();
}

class _QuotesSearchScreenState extends ConsumerState<QuotesSearchScreen> {
  // Filters
  final Set<String> _selectedStatuses = {};

  String _getChipLabel(Set<String> selected, String defaultLabel) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) return selected.first;
    return '$defaultLabel +${selected.length}';
  }

  void _showStatusFilter(List<Quote> quotes) {
    // Collect specific strings (labels) for the filter UI
    final options = quotes.map((e) => e.status.label).toSet().toList()..sort();

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Estado',
      options: options,
      selectedValues: _selectedStatuses, // Fixed parameter name
      onApply: (selected) {
        setState(() {
          _selectedStatuses.clear();
          _selectedStatuses.addAll(selected);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(quotesSearchProvider);

    return GenericSearchScreen<Quote>(
      title: 'Buscar cotización',
      hintText: 'Nombre, número...',
      historyKey: 'quotes_search_history',
      data: dataAsync,
      onResetFilters: () {
        setState(() {
          _selectedStatuses.clear();
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
      ],
      filter: (quote, query) {
        final q = query.normalized;

        final matchesText =
            quote.clientName.normalized.contains(q) ||
            quote.quoteNumber.normalized.contains(q);

        // Filter match by status label
        final matchesStatus =
            _selectedStatuses.isEmpty ||
            _selectedStatuses.contains(quote.status.label);

        return matchesText && matchesStatus;
      },
    );
  }
}
