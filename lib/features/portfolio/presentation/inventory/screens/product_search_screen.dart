import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product_model.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../widgets/inventory_item_card.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../widgets/inventory_action_sheet.dart';
import '../../providers/products_provider.dart';

class ProductSearchScreen extends ConsumerStatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  ConsumerState<ProductSearchScreen> createState() =>
      _ProductSearchScreenState();
}

class _ProductSearchScreenState extends ConsumerState<ProductSearchScreen> {
  // Filters
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedBrands = {};
  SortOption _currentSort = SortOption.lowestPrice;
  String _searchQuery = '';

  final List<SortOption> _sortOptions = [
    SortOption.recent,
    SortOption.nameAZ,
    SortOption.nameZA,
    SortOption.highestPrice,
    SortOption.lowestPrice,
    SortOption.quantityDesc,
    SortOption.quantityAsc,
  ];

  // Note: Price filter removed as Product model does not support price yet.

  String _getHistoryKey() {
    return 'product_search_history';
  }

  String _getChipLabel(String defaultLabel, Set<String> selected) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) return selected.first;
    return '${selected.first}+${selected.length - 1}';
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return GenericSearchScreen<Product>(
      hintText: 'Buscar productos...',
      historyKey: _getHistoryKey(),
      data: productsAsync,
      onResetFilters: () {
        setState(() {
          _selectedCategories.clear();
          _selectedBrands.clear();
          _searchQuery = '';
        });
      },
      onQueryChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      filters: [
        FilterChipData(
          label: _getChipLabel('Categoría', _selectedCategories),
          isActive: _selectedCategories.isNotEmpty,
          onTap: () {
            productsAsync.whenData((products) {
              final queryNormalized = _searchQuery.normalized;
              final availableCategories = products
                  .where((p) {
                    // Filter by text search
                    return queryNormalized.isEmpty ||
                        p.name.normalized.contains(queryNormalized) ||
                        (p.brand?.name.normalized ?? '').contains(
                          queryNormalized,
                        ) ||
                        (p.model?.normalized ?? '').contains(queryNormalized);
                  })
                  .map((p) => p.category?.name)
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
            });
          },
        ),
        FilterChipData(
          label: _getChipLabel('Marca', _selectedBrands),
          isActive: _selectedBrands.isNotEmpty,
          onTap: () {
            productsAsync.whenData((products) {
              final queryNormalized = _searchQuery.normalized;
              final availableBrands = products
                  .where((p) {
                    // Filter by text search
                    return queryNormalized.isEmpty ||
                        p.name.normalized.contains(queryNormalized) ||
                        (p.brand?.name.normalized ?? '').contains(
                          queryNormalized,
                        ) ||
                        (p.model?.normalized ?? '').contains(queryNormalized);
                  })
                  .map((p) => p.brand?.name)
                  .whereType<String>()
                  .toSet()
                  .where((s) => s.isNotEmpty)
                  .toList();

              FilterBottomSheet.showMulti(
                context: context,
                title: 'Marca',
                options: availableBrands,
                selectedValues: _selectedBrands,
                onApply: (newSet) {
                  setState(() {
                    _selectedBrands.clear();
                    _selectedBrands.addAll(newSet);
                  });
                },
              );
            });
          },
        ),
      ],
      bottomFilterWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SortSelector(
          currentSort: _currentSort,
          options: _sortOptions,
          onSortChanged: (newSort) {
            setState(() {
              _currentSort = newSort;
            });
          },
        ),
      ),
      comparator: (a, b) {
        switch (_currentSort) {
          case SortOption.recent:
            return b.createdAt.compareTo(a.createdAt);
          case SortOption.nameAZ:
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case SortOption.nameZA:
            return b.name.toLowerCase().compareTo(a.name.toLowerCase());
          case SortOption.highestPrice:
            return b.averageCost.compareTo(a.averageCost);
          case SortOption.lowestPrice:
            return a.averageCost.compareTo(b.averageCost);
          case SortOption.quantityDesc:
            return b.inventoryQuantity.compareTo(a.inventoryQuantity);
          case SortOption.quantityAsc:
            return a.inventoryQuantity.compareTo(b.inventoryQuantity);
          default:
            return 0;
        }
      },
      filter: (p, query) {
        final normalizedQuery = query.normalized;
        final matchesQuery =
            normalizedQuery.isEmpty ||
            p.name.normalized.contains(normalizedQuery) ||
            (p.brand?.name.normalized ?? '').contains(normalizedQuery) ||
            (p.model?.normalized ?? '').contains(normalizedQuery);

        final matchesCategory =
            _selectedCategories.isEmpty ||
            (p.category != null &&
                _selectedCategories.contains(p.category!.name));

        final matchesBrand =
            _selectedBrands.isEmpty ||
            (p.brand != null && _selectedBrands.contains(p.brand!.name));

        return matchesQuery && matchesCategory && matchesBrand;
      },
      itemBuilder: (context, product) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InventoryItemCard(
              name: product.name,
              brand: product.brand?.name ?? '',
              model: product.model ?? '',
              stock: product.inventoryQuantity,
              price: product.averageCost,
              unit: product.uom,
              uomIconName: product.uomModel?.iconName,
              imageUrl: product.imageUrl,
              onTap: () {
                InventoryActionSheet.show(
                  context: context,
                  ref: ref,
                  product: product,
                  currentPrice: product.averageCost,
                  currentStock: product.inventoryQuantity,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
