import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/aggregated_product_card.dart';
import '../../../../../shared/widgets/horizontal_filter_bar.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/price_filter_sheet.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../domain/models/quote_aggregated_product.dart';
import '../providers/quote_product_selection_provider.dart';
import '../../../../portfolio/domain/models/product_sort_option.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';

class QuoteProductSearchScreen extends ConsumerStatefulWidget {
  const QuoteProductSearchScreen({super.key});

  @override
  ConsumerState<QuoteProductSearchScreen> createState() =>
      _QuoteProductSearchScreenState();
}

class _QuoteProductSearchScreenState
    extends ConsumerState<QuoteProductSearchScreen> {
  String _currentQuery = '';
  ProductSortOption _currentSort = ProductSortOption.priceAsc;

  // Filters State
  Set<String> _selectedBrands = {};
  Set<String> _selectedCategories = {};
  Set<String> _selectedSuppliers = {};
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
      _selectedBrands.clear();
      _selectedCategories.clear();
      _selectedSuppliers.clear();
      _minPrice = null;
      _maxPrice = null;
      _currentSort = ProductSortOption.priceAsc;
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

  // --- Filter Logic ---

  void _showSupplierFilter(List<QuoteAggregatedProduct> allProducts) {
    // Collect all available supplier names dynamically
    final availableSuppliers =
        allProducts
            .expand((p) => p.supplierNames)
            .where((name) => name.trim().isNotEmpty)
            .map((name) => name.trim().toTitleCase)
            .toSet()
            .toList()
          ..sort();

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Proveedor',
      options: availableSuppliers,
      selectedValues: _selectedSuppliers,
      onApply: (selected) {
        setState(() {
          _selectedSuppliers = selected
              .map((s) => s.trim().toTitleCase)
              .toSet();
        });
      },
    );
  }

  void _showBrandFilter(List<QuoteAggregatedProduct> allProducts) {
    // Collect all available brands dynamically
    final availableBrands =
        allProducts
            .where(
              (p) => p.brand.isNotEmpty && p.brand.toLowerCase() != 'genérico',
            )
            .map((p) => p.brand.toTitleCase) // Normalize to Title Case
            .toSet()
            .toList()
          ..sort();

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Marca',
      options: availableBrands,
      selectedValues: _selectedBrands,
      onApply: (selected) {
        setState(() {
          _selectedBrands = selected.toSet();
        });
      },
    );
  }

  void _showCategoryFilter(List<QuoteAggregatedProduct> allProducts) {
    // Collect all available categories dynamically
    final availableCategories =
        allProducts
            .where((p) => p.category.isNotEmpty)
            .map((p) => p.category)
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
    final suggestionsAsync = ref.watch(quoteProductSuggestionsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.valueOrNull;
    final isVerified = userProfile?.verificationStatus == 'verified';
    final colors = Theme.of(context).colorScheme;

    // Process List client-side
    final originalItems = suggestionsAsync.valueOrNull ?? [];

    // Filter Logic
    var filteredProducts = <QuoteAggregatedProduct>[];

    for (final p in originalItems) {
      // 1. Unverified Users Access Rule:
      if (!isVerified) {
        // If purely wholesale (or single wholesale supplier) and not own inventory, hide it entirely.
        if (!p.hasOwnInventory &&
            p.supplierCount == 1 &&
            p.firstSupplierTradeType == 'WHOLESALE') {
          continue;
        }
      }

      // 2. Query Match
      if (_currentQuery.isNotEmpty) {
        final q = _currentQuery.normalized;
        final matches =
            p.name.normalized.contains(q) ||
            p.brand.normalized.contains(q) ||
            p.model.normalized.contains(q);
        if (!matches) continue;
      }

      // 3. User Filters
      if (_selectedBrands.isNotEmpty) {
        if (!_selectedBrands.any(
          (selected) => selected.toLowerCase() == p.brand.toLowerCase(),
        )) {
          continue;
        }
      }

      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(p.category)) {
        continue;
      }

      // 4. Apply Dynamic Supplier Filter & Calculate New Aggregates
      final filteredProduct = p.filterBySuppliers(_selectedSuppliers);

      // If the product has no sources left after filtering by supplier, drop it.
      if (_selectedSuppliers.isNotEmpty && filteredProduct.sources.isEmpty) {
        continue;
      }

      // 5. Apply Price Filters (using the newly computed minPrice)
      if (_minPrice != null && filteredProduct.minPrice < _minPrice!) continue;
      if (_maxPrice != null && filteredProduct.minPrice > _maxPrice!) continue;

      filteredProducts.add(filteredProduct);
    }

    // Sort Logic
    filteredProducts.sort((a, b) {
      switch (_currentSort) {
        case ProductSortOption.priceAsc:
          return a.minPrice.compareTo(b.minPrice);
        case ProductSortOption.priceDesc:
          return b.minPrice.compareTo(a.minPrice);
        case ProductSortOption.quantityAsc:
          return a.totalQuantity.compareTo(b.totalQuantity);
        case ProductSortOption.quantityDesc:
          return b.totalQuantity.compareTo(a.totalQuantity);
        case ProductSortOption.nameAZ:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ProductSortOption.nameZA:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      }
    });

    final AsyncValue<List<QuoteAggregatedProduct>> processedAsyncValue =
        suggestionsAsync.when(
          data: (_) => AsyncValue.data(filteredProducts),
          loading: () => const AsyncValue.loading(),
          error: (e, s) => AsyncValue.error(e, s),
        );

    return GenericSearchScreen<QuoteAggregatedProduct>(
      title: 'Buscar Producto',
      hintText: 'Buscar productos, modelos, marcas...',
      historyKey: 'quote_product_search_history',
      data: processedAsyncValue,
      onQueryChanged: _onQueryChanged,
      onResetFilters: _resetFilters,

      // Filter Chips Configuration
      filters: [
        FilterChipData(
          label: _getChipLabel('Proveedor', _selectedSuppliers),
          isActive: _selectedSuppliers.isNotEmpty,
          onTap: () => _showSupplierFilter(originalItems),
        ),
        FilterChipData(
          label: _getChipLabel('Categoría', _selectedCategories),
          isActive: _selectedCategories.isNotEmpty,
          onTap: () => _showCategoryFilter(originalItems),
        ),
        FilterChipData(
          label: _getChipLabel('Marca', _selectedBrands),
          isActive: _selectedBrands.isNotEmpty,
          onTap: () => _showBrandFilter(originalItems),
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
              'Precios no incluyen impuesto y pueden variar sin previo aviso',
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
              child: GenericSortSelector<ProductSortOption>(
                currentSort: _currentSort,
                options: ProductSortOption.values,
                onSortChanged: (val) => setState(() => _currentSort = val),
                labelBuilder: (option) => option.label,
                iconBuilder: (option) {
                  if (option == ProductSortOption.priceAsc)
                    return Icons.arrow_upward;
                  if (option == ProductSortOption.priceDesc)
                    return Icons.arrow_downward;
                  if (option == ProductSortOption.quantityAsc)
                    return Icons.arrow_upward;
                  if (option == ProductSortOption.quantityDesc)
                    return Icons.arrow_downward;
                  if (option == ProductSortOption.nameAZ)
                    return Icons.arrow_upward;
                  if (option == ProductSortOption.nameZA)
                    return Icons.arrow_downward;
                  return null;
                },
              ),
            ),
          ],
        ),
      ),

      filter: (product, query) => true, // Filtering is done manually above

      itemBuilder: (context, product) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: AggregatedProductCard(
            name: product.name,
            brand: product.brand,
            model: product.model,
            minPrice: product.minPrice,
            totalQuantity: product.totalQuantity,
            supplierCount: product.supplierCount,
            uom: product.uom,
            showPriceAndStock: true,
            isLocked: product.isLocked,
            onTap: () {
              context
                  .push(
                    '/quotes/create/select-product/product-sources',
                    extra: product,
                  )
                  .then((result) {
                    if (result == true) {
                      if (context.mounted) {
                        context.pop();
                        context.pop(true);
                      }
                    }
                  });
            },
          ),
        );
      },
    );
  }
}
