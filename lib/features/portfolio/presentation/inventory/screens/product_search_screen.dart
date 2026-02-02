import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product_model.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../providers/products_provider.dart';
import '../widgets/inventory_item_card.dart';
import '../widgets/inventory_action_sheet.dart';

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
        });
      },
      filters: [
        FilterChipData(
          label: _getChipLabel('Categoría', _selectedCategories),
          isActive: _selectedCategories.isNotEmpty,
          onTap: () {
            productsAsync.whenData((products) {
              final categories = products
                  .map((p) => p.category?.name)
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
        FilterChipData(
          label: _getChipLabel('Marca', _selectedBrands),
          isActive: _selectedBrands.isNotEmpty,
          onTap: () {
            productsAsync.whenData((products) {
              final brands = products
                  .map((p) => p.brand?.name)
                  .whereType<String>()
                  .toSet()
                  .where((s) => s.isNotEmpty)
                  .toList();

              FilterBottomSheet.showMulti(
                context: context,
                title: 'Marca',
                options: brands,
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
              stock: 0, // Placeholder
              price: 0.0, // Placeholder
              imageUrl: product.imageUrl,
              onTap: () {
                InventoryActionSheet.show(
                  context: context,
                  product: product,
                  currentPrice: 0.0, // Unavailable in search
                  currentStock: 0, // Unavailable in search
                );
              },
            ),
          ),
        );
      },
    );
  }
}
