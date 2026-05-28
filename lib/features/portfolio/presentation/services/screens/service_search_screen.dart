import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/service_model.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/price_filter_sheet.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../providers/services_provider.dart';
import '../../../../../shared/widgets/service_list_item.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../widgets/service_action_sheet.dart';

class ServiceSearchScreen extends ConsumerStatefulWidget {
  const ServiceSearchScreen({super.key});

  @override
  ConsumerState<ServiceSearchScreen> createState() =>
      _ServiceSearchScreenState();
}

class _ServiceSearchScreenState extends ConsumerState<ServiceSearchScreen> {
  // Filters
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedRates = {};
  double? _minPrice;
  double? _maxPrice;
  String _searchQuery = '';
  SortOption _currentSort = SortOption.nameAZ;

  String _getHistoryKey() {
    return 'service_search_history';
  }

  String _getChipLabel(String defaultLabel, Set<String> selected) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) return selected.first;
    return '${selected.first} +${selected.length - 1}';
  }

  String _getPriceChipLabel() {
    if (_minPrice == null && _maxPrice == null) return 'Precio';
    if (_minPrice != null && _maxPrice != null) {
      return '\$${_minPrice!.toStringAsFixed(0)} - \$${_maxPrice!.toStringAsFixed(0)}';
    }
    if (_minPrice != null) return 'Min \$${_minPrice!.toStringAsFixed(0)}';
    if (_maxPrice != null) return 'Max \$${_maxPrice!.toStringAsFixed(0)}';
    return 'Precio';
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedServicesProvider);

    return GenericSearchScreen<ServiceModel>(
      hintText: 'Buscar servicios...',
      historyKey: _getHistoryKey(),
      isPaginatedMode: true,
      paginatedDataAsync: paginatedAsync,
      onResetFilters: () {
        setState(() {
          _selectedCategories.clear();
          _selectedRates.clear();
          _minPrice = null;
          _maxPrice = null;
          _searchQuery = '';
          _currentSort = SortOption.nameAZ;
        });
        ref.read(paginatedServicesProvider.notifier).updateSearch(null);
        ref.read(paginatedServicesProvider.notifier).updateFilters(categoryId: null);
        ref.read(paginatedServicesProvider.notifier).updateSort('name', true);
      },
      onServerSearch: (query) {
        ref.read(paginatedServicesProvider.notifier).updateSearch(query);
      },
      onLoadMore: () {
        ref.read(paginatedServicesProvider.notifier).loadMore();
      },
      onQueryChanged: (query) {
        // Handled by onServerSearch
      },
      filters: [
        // Category Filter
        FilterChipData(
          label: _getChipLabel('Categoría', _selectedCategories),
          isActive: _selectedCategories.isNotEmpty,
          onTap: () {
            final items = paginatedAsync.valueOrNull?.items ?? [];
            final queryNormalized = _searchQuery.normalized;
            final availableCategories = items
                  .where((s) {
                    return queryNormalized.isEmpty ||
                        s.name.normalized.contains(queryNormalized) ||
                        (s.description?.normalized ?? '').contains(
                          queryNormalized,
                        );
                  })
                  .map((s) => s.category?.name)
                  .whereType<String>()
                  .toSet()
                  .where((s) => s.isNotEmpty)
                  .toList();

            FilterBottomSheet.showMulti(
              context: context,
              title: 'Categoría',
              options: availableCategories,
              selectedValues: _selectedCategories,
              onApply: (newSet) {
                setState(() {
                  _selectedCategories.clear();
                  _selectedCategories.addAll(newSet);
                });
              },
            );
          },
        ),

        // Tariff (Rate) Filter
        FilterChipData(
          label: _getChipLabel('Tarifa', _selectedRates),
          isActive: _selectedRates.isNotEmpty,
          onTap: () {
            final items = paginatedAsync.valueOrNull?.items ?? [];
            final queryNormalized = _searchQuery.normalized;
            final availableRates = items
                  .where((s) {
                    return queryNormalized.isEmpty ||
                        s.name.normalized.contains(queryNormalized) ||
                        (s.description?.normalized ?? '').contains(
                          queryNormalized,
                        );
                  })
                  .map((s) => s.serviceRate?.name)
                  .whereType<String>()
                  .toSet()
                  .where((s) => s.isNotEmpty)
                  .toList();

            FilterBottomSheet.showMulti(
              context: context,
              title: 'Tarifa',
              options: availableRates,
              selectedValues: _selectedRates,
              onApply: (newSet) {
                setState(() {
                  _selectedRates.clear();
                  _selectedRates.addAll(newSet);
                });
              },
            );
          },
        ),

        // Price Filter
        FilterChipData(
          label: _getPriceChipLabel(),
          isActive: _minPrice != null || _maxPrice != null,
          onTap: _showPriceFilter,
        ),
      ],
      bottomFilterWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SortSelector(
          currentSort: _currentSort,
          options: const [
            SortOption.nameAZ,
            SortOption.nameZA,
            SortOption.highestPrice,
            SortOption.lowestPrice,
          ],
          onSortChanged: (val) {
            setState(() {
              _currentSort = val;
            });
            String orderBy = 'name';
            bool ascending = true;
            if (val == SortOption.nameZA) {
              ascending = false;
            } else if (val == SortOption.highestPrice) {
              orderBy = 'price';
              ascending = false;
            } else if (val == SortOption.lowestPrice) {
              orderBy = 'price';
              ascending = true;
            }
            ref.read(paginatedServicesProvider.notifier).updateSort(orderBy, ascending);
          },
        ),
      ),
      comparator: null,
      filter: null,
      itemBuilder: (context, service) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ServiceListItem(
              service: service,
              onTap: () {
                ServiceActionSheet.show(context, ref, service);
              },
            ),
          ),
        );
      },
    );
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return PriceFilterSheet(
          initialMin: _minPrice,
          initialMax: _maxPrice,
          onApply: (min, max) {
            setState(() {
              _minPrice = min;
              _maxPrice = max;
            });
          },
        );
      },
    );
  }
}
