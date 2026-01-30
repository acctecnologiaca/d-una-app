import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/service_model.dart';
import '../../../../shared/widgets/generic_search_screen.dart';
import '../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../core/utils/string_extensions.dart';
import '../providers/services_provider.dart';
import 'widgets/service_item_card.dart';

class ServiceSearchScreen extends ConsumerStatefulWidget {
  const ServiceSearchScreen({super.key});

  @override
  ConsumerState<ServiceSearchScreen> createState() =>
      _ServiceSearchScreenState();
}

class _ServiceSearchScreenState extends ConsumerState<ServiceSearchScreen> {
  // Filters
  final Set<String> _selectedCategories = {};
  // Services might not have brands, but have price units or categories.
  // Assuming Category is the main filter for now based on ServiceModel.
  // ServiceModel has: id, name, description, price, priceUnit, category, userId, ...

  String _getHistoryKey() {
    return 'service_search_history';
  }

  String _getChipLabel(String defaultLabel, Set<String> selected) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) return selected.first;
    return '${selected.first}+${selected.length - 1}';
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
        });
      },
      filters: [
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

        return matchesQuery && matchesCategory;
      },
      itemBuilder: (context, service) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ServiceItemCard(
              name: service.name,
              description: service.description,
              price: service.price,
              priceUnit: service.serviceRate != null
                  ? '${service.serviceRate!.name} (${service.serviceRate!.symbol})'
                  : '',
              onTap: () {
                context.push(
                  '/portfolio/own-services/details/${service.id}',
                  extra: service,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
