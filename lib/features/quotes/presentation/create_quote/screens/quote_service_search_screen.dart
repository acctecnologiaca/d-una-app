import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/horizontal_filter_bar.dart';
import '../../../../../shared/widgets/price_filter_sheet.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../portfolio/data/models/service_model.dart';
import '../providers/quote_service_selection_provider.dart';
import '../providers/create_quote_provider.dart';
import '../widgets/quote_service_sale_details_sheet.dart';
import '../../../../../shared/widgets/service_list_item.dart';

class QuoteServiceSearchScreen extends ConsumerStatefulWidget {
  const QuoteServiceSearchScreen({super.key});

  @override
  ConsumerState<QuoteServiceSearchScreen> createState() =>
      _QuoteServiceSearchScreenState();
}

class _QuoteServiceSearchScreenState
    extends ConsumerState<QuoteServiceSearchScreen> {
  SortOption _currentSort = SortOption.lowestPrice;

  // Filters State
  Set<String> _selectedCategories = {};
  Set<String> _selectedRates = {};
  double? _minPrice;
  double? _maxPrice;

  @override
  void dispose() {
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedRates.clear();
      _minPrice = null;
      _maxPrice = null;
      _currentSort = SortOption.lowestPrice;
    });
    ref.read(paginatedQuoteServiceSearchProvider.notifier).updateSearch(null);
    ref.read(paginatedQuoteServiceSearchProvider.notifier).updateFilters(categoryId: null, rateId: null);
    ref.read(paginatedQuoteServiceSearchProvider.notifier).updateSort('created_at', false);
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
        _applyFiltersToServer();
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
        _applyFiltersToServer();
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
          // Min/Max price filtering not yet fully supported on server for services (only products).
          // But kept in state for future.
        },
      ),
    );
  }

  void _applyFiltersToServer() {
    ref.read(paginatedQuoteServiceSearchProvider.notifier).updateFilters(
      categoryId: _selectedCategories.isNotEmpty ? _selectedCategories.first : null, // Assuming singles or you can map names to IDs
      rateId: _selectedRates.isNotEmpty ? _selectedRates.first : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Unpaginated data for facets
    final suggestionsAsync = ref.watch(quoteServiceSuggestionsProvider);
    
    // 2. Paginated data for list
    final paginatedAsync = ref.watch(paginatedQuoteServiceSearchProvider);
    
    final quoteServices = ref.watch(createQuoteProvider).services;
    final colors = Theme.of(context).colorScheme;

    final originalItems = suggestionsAsync.valueOrNull ?? [];

    return GenericSearchScreen<ServiceModel>(
      title: 'Buscar Servicio',
      hintText: 'Buscar servicio, categoría...',
      historyKey: 'quote_service_search_history',
      isPaginatedMode: true,
      paginatedDataAsync: paginatedAsync,
      onServerSearch: (query) {
        ref.read(paginatedQuoteServiceSearchProvider.notifier).updateSearch(query);
      },
      onLoadMore: () {
        ref.read(paginatedQuoteServiceSearchProvider.notifier).loadMore();
      },
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
                options: const [
                  SortOption.nameAZ,
                  SortOption.nameZA,
                  SortOption.highestPrice,
                  SortOption.lowestPrice,
                ],
                onSortChanged: (val) {
                  setState(() => _currentSort = val);
                  String orderBy = 'created_at';
                  bool ascending = false;
                  if (val == SortOption.nameAZ) {
                    orderBy = 'name';
                    ascending = true;
                  } else if (val == SortOption.nameZA) {
                    orderBy = 'name';
                    ascending = false;
                  } else if (val == SortOption.highestPrice) {
                    orderBy = 'price';
                    ascending = false;
                  } else if (val == SortOption.lowestPrice) {
                    orderBy = 'price';
                    ascending = true;
                  }
                  ref.read(paginatedQuoteServiceSearchProvider.notifier).updateSort(orderBy, ascending);
                },
              ),
            ),
          ],
        ),
      ),

      filter: (service, query) => true, // Filtering is done manually above

      itemBuilder: (context, service) {
        final isAlreadyInQuote = quoteServices.any(
          (s) => s.serviceId == service.id,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              ServiceListItem(
                service: service,
                isAlreadyAdded: isAlreadyInQuote,
                onTap: () async {
                  if (isAlreadyInQuote) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Este servicio ya se encuentra en la cotización',
                        ),
                      ),
                    );
                    return;
                  }

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
              ),
              const Divider(height: 1, color: Colors.transparent),
            ],
          ),
        );
      },
    );
  }
}
