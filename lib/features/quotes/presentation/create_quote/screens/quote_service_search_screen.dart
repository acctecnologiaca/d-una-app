import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/standard_list_item.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/horizontal_filter_bar.dart';
import '../../../../../shared/widgets/price_filter_sheet.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../portfolio/data/models/service_model.dart';
import '../providers/quote_service_selection_provider.dart';
import '../providers/create_quote_provider.dart';
import '../widgets/quote_service_sale_details_sheet.dart';

class QuoteServiceSearchScreen extends ConsumerStatefulWidget {
  const QuoteServiceSearchScreen({super.key});

  @override
  ConsumerState<QuoteServiceSearchScreen> createState() =>
      _QuoteServiceSearchScreenState();
}

class _QuoteServiceSearchScreenState
    extends ConsumerState<QuoteServiceSearchScreen> {
  String _currentQuery = '';
  SortOption _currentSort = SortOption.recent;

  // Filters State
  Set<String> _selectedCategories = {};
  Set<String> _selectedRates = {};
  double? _minPrice;
  double? _maxPrice;

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _currentQuery = query;
        });
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedRates.clear();
      _minPrice = null;
      _maxPrice = null;
      _currentSort = SortOption.recent;
    });
  }

  // --- Dynamic Label Helpers ---
  String _getChipLabel(String defaultLabel, Set<String> selected) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) return selected.first;
    return '${selected.first} +${selected.length - 1}';
  }

  String _getPriceLabel() {
    if (_minPrice == null && _maxPrice == null) return 'Precio';
    if (_minPrice != null && _maxPrice != null) {
      return '\$${_minPrice!.toInt()} - \$${_maxPrice!.toInt()}';
    } else if (_minPrice != null) {
      return '> \$${_minPrice!.toInt()}';
    } else {
      return '< \$${_maxPrice!.toInt()}';
    }
  }

  String _getRateSuffix(String? rateName) {
    if (rateName == null) return '/ud.';
    final lower = rateName.toLowerCase();
    if (lower.contains('hora') || lower.contains('h')) return '/h';
    if (lower.contains('día') || lower.contains('dia')) return '/dia';
    if (lower.contains('mes')) return '/mes';
    if (lower.contains('serv')) return '/serv.';
    return '/ud.';
  }

  // --- Filter Logic ---
  void _showCategoryFilter(List<ServiceModel> allServices) {
    final availableCategories =
        allServices
            .where(
              (s) => s.category?.name != null && s.category!.name.isNotEmpty,
            )
            .map((s) => s.category!.name)
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
          _selectedCategories = selected.toSet();
        });
      },
    );
  }

  void _showRateFilter(List<ServiceModel> allServices) {
    final availableRates =
        allServices
            .where(
              (s) =>
                  s.serviceRate?.name != null && s.serviceRate!.name.isNotEmpty,
            )
            .map((s) => s.serviceRate!.name)
            .toSet()
            .toList()
          ..sort();

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Tarifa',
      options: availableRates,
      selectedValues: _selectedRates,
      onApply: (selected) {
        setState(() {
          _selectedRates = selected.toSet();
        });
      },
    );
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PriceFilterSheet(
        initialMin: _minPrice,
        initialMax: _maxPrice,
        onApply: (min, max) {
          setState(() {
            _minPrice = min;
            _maxPrice = max;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(quoteServiceSuggestionsProvider);
    final colors = Theme.of(context).colorScheme;

    final originalItems = suggestionsAsync.valueOrNull ?? [];
    var filteredServices = <ServiceModel>[];

    for (final s in originalItems) {
      // 1. Query Match
      if (_currentQuery.isNotEmpty) {
        final q = _currentQuery.normalized;
        final matches =
            s.name.normalized.contains(q) ||
            (s.category?.name.normalized.contains(q) ?? false) ||
            (s.description?.normalized.contains(q) ?? false);
        if (!matches) continue;
      }

      // 2. User Filters
      if (_selectedCategories.isNotEmpty) {
        final catName = s.category?.name ?? '';
        if (!_selectedCategories.contains(catName)) {
          continue;
        }
      }

      if (_selectedRates.isNotEmpty) {
        final rateName = s.serviceRate?.name ?? '';
        if (!_selectedRates.contains(rateName)) {
          continue;
        }
      }

      // 3. Price Filters
      if (_minPrice != null && s.price < _minPrice!) continue;
      if (_maxPrice != null && s.price > _maxPrice!) continue;

      filteredServices.add(s);
    }

    // Sort Logic
    filteredServices.sort((a, b) {
      switch (_currentSort) {
        case SortOption.recent:
        case SortOption.frequency:
          return b.createdAt.compareTo(a.createdAt); // Default to recent
        case SortOption.nameAZ:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortOption.nameZA:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        default:
          return 0;
      }
    });

    final AsyncValue<List<ServiceModel>> processedAsyncValue = suggestionsAsync
        .when(
          data: (_) => AsyncValue.data(filteredServices),
          loading: () => const AsyncValue.loading(),
          error: (e, s) => AsyncValue.error(e, s),
        );

    return GenericSearchScreen<ServiceModel>(
      title: 'Buscar Servicio',
      hintText: 'Buscar servicios...',
      historyKey: 'quote_service_search_history',
      data: processedAsyncValue,
      onQueryChanged: _onQueryChanged,
      onResetFilters: _resetFilters,

      // Filter Chips Configuration
      filters: [
        FilterChipData(
          label: _getChipLabel('Categoría', _selectedCategories),
          isActive: _selectedCategories.isNotEmpty,
          onTap: () => _showCategoryFilter(originalItems),
        ),
        FilterChipData(
          label: _getChipLabel('Tarifa', _selectedRates),
          isActive: _selectedRates.isNotEmpty,
          onTap: () => _showRateFilter(originalItems),
        ),
        FilterChipData(
          label: _getPriceLabel(),
          isActive: _minPrice != null || _maxPrice != null,
          onTap: _showPriceFilter,
        ),
      ],

      bottomFilterWidget: Padding(
        padding: const EdgeInsets.only(
          top: 8.0,
          left: 16,
          right: 16,
          bottom: 8.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Precios no incluyen impuesto',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SortSelector(
                currentSort: _currentSort,
                onSortChanged: (val) => setState(() => _currentSort = val),
              ),
            ),
          ],
        ),
      ),

      filter: (service, query) => true, // Filtering is done manually above

      itemBuilder: (context, service) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              StandardListItem(
                onTap: () async {
                  final addedService = await QuoteServiceSaleDetailsSheet.show(
                    context,
                    service: service,
                  );

                  if (addedService != null) {
                    ref
                        .read(createQuoteProvider.notifier)
                        .addService(addedService);
                    if (context.mounted) {
                      context.pop(); // Pop the search screen
                      context.pop(); // Pop the selection screen
                    }
                  }
                },
                title: service.name,
                subtitle: Text(service.category?.name ?? 'Sin categoría'),
                trailing: Text(
                  '${CurrencyFormatter.format(service.price)}${_getRateSuffix(service.serviceRate?.name)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.transparent),
            ],
          ),
        );
      },
    );
  }
}
