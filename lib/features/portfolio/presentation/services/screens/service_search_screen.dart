import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/service_model.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/price_filter_sheet.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../providers/services_provider.dart';
import '../widgets/service_item_card.dart';
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
    final servicesAsync = ref.watch(servicesProvider);

    return GenericSearchScreen<ServiceModel>(
      hintText: 'Buscar servicios...',
      historyKey: _getHistoryKey(),
      data: servicesAsync,
      onResetFilters: () {
        setState(() {
          _selectedCategories.clear();
          _selectedRates.clear();
          _minPrice = null;
          _maxPrice = null;
        });
      },
      filters: [
        // Category Filter
        FilterChipData(
          label: _getChipLabel('Categoría', _selectedCategories),
          isActive: _selectedCategories.isNotEmpty,
          onTap: () {
            servicesAsync.whenData((services) {
              final categories = services
                  .map((s) => s.category?.name)
                  .whereType<String>()
                  .toSet()
                  .where((s) => s.isNotEmpty)
                  .toList();

              FilterBottomSheet.showMulti(
                context: context,
                title: 'Categoría',
                options: categories,
                selectedValues: _selectedCategories,
                onApply: (newSet) {
                  setState(() {
                    _selectedCategories.clear();
                    _selectedCategories.addAll(newSet);
                  });
                },
              );
            });
          },
        ),

        // Tariff (Rate) Filter
        FilterChipData(
          label: _getChipLabel('Tarifa', _selectedRates),
          isActive: _selectedRates.isNotEmpty,
          onTap: () {
            servicesAsync.whenData((services) {
              final rates = services
                  .map(
                    (s) => s.serviceRate?.name,
                  ) // Use rate name (e.g. Unidad, Hora)
                  .whereType<String>()
                  .toSet()
                  .where((s) => s.isNotEmpty)
                  .toList();

              FilterBottomSheet.showMulti(
                context: context,
                title: 'Tarifa',
                options: rates,
                selectedValues: _selectedRates,
                onApply: (newSet) {
                  setState(() {
                    _selectedRates.clear();
                    _selectedRates.addAll(newSet);
                  });
                },
              );
            });
          },
        ),

        // Price Filter
        FilterChipData(
          label: _getPriceChipLabel(),
          isActive: _minPrice != null || _maxPrice != null,
          onTap: _showPriceFilter,
        ),
      ],
      filter: (s, query) {
        final normalizedQuery = query.normalized;
        final matchesQuery =
            normalizedQuery.isEmpty ||
            s.name.normalized.contains(normalizedQuery) ||
            (s.description?.normalized ?? '').contains(normalizedQuery);

        final matchesCategory =
            _selectedCategories.isEmpty ||
            (s.category != null &&
                _selectedCategories.contains(s.category!.name));

        final matchesRate =
            _selectedRates.isEmpty ||
            (s.serviceRate != null &&
                _selectedRates.contains(s.serviceRate!.name));

        final price = s.price;
        final matchesPrice =
            (_minPrice == null || price >= _minPrice!) &&
            (_maxPrice == null || price <= _maxPrice!);

        return matchesQuery && matchesCategory && matchesRate && matchesPrice;
      },
      itemBuilder: (context, service) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ServiceItemCard(
              name: service.name,
              category: service.category?.name,
              price: service.price,
              priceUnit: service.serviceRate != null
                  ? '${service.serviceRate!.name} (${service.serviceRate!.symbol})'
                  : '',
              onTap: () {
                ServiceActionSheet.show(context, service);
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
