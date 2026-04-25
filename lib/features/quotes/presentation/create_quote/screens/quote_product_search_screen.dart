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
import '../../../../../core/utils/search_utils.dart';
import '../../../domain/models/quote_aggregated_product.dart';
import '../providers/quote_product_selection_provider.dart';
import '../../../../portfolio/domain/models/product_search_filters.dart';
import '../../../../portfolio/presentation/providers/product_search_provider.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../providers/create_quote_provider.dart';

class QuoteProductSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const QuoteProductSearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<QuoteProductSearchScreen> createState() =>
      _QuoteProductSearchScreenState();
}

class _QuoteProductSearchScreenState
    extends ConsumerState<QuoteProductSearchScreen> {
  late String _currentQuery = widget.initialQuery ?? '';
  SortOption _currentSort = SortOption.lowestPrice;

  // Filters State
  Set<String> _selectedBrands = {};
  Set<String> _selectedCategories = {};
  Set<String> _selectedSuppliers = {}; // Storing UUIDs
  final Map<String, String> _supplierNameCache = {};
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
      _currentSort = SortOption.lowestPrice;
    });
  }

  // --- Dynamic Label Helpers ---

  String _getChipLabel(
    String defaultLabel,
    Set<String> selected, {
    Map<String, String>? nameMap,
  }) {
    if (selected.isEmpty) return defaultLabel;

    String firstLabel = selected.first;
    if (nameMap != null && nameMap.containsKey(firstLabel)) {
      firstLabel = nameMap[firstLabel]!;
    }

    if (selected.length == 1) return firstLabel;
    return '$firstLabel +${selected.length - 1}';
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

  // --- Facet Extraction ---

  ({Set<String> categories, Set<String> brands, Map<String, String> suppliers})
  _getAvailableFacets() {
    final baseState = ref.read(
      quoteProductSuggestionsProvider(
        ProductSearchParams(query: _currentQuery),
      ),
    );

    final items = baseState.valueOrNull ?? [];
    final categories = <String>{};
    final brands = <String>{};
    final suppliers = <String, String>{};

    // For Brands: filter base items by active categories & suppliers
    Iterable<QuoteAggregatedProduct> forBrands = items;
    if (_selectedSuppliers.isNotEmpty) {
      forBrands = forBrands.where(
        (p) => p.suppliersInfo.any(
          (info) => _selectedSuppliers.contains(info['id']),
        ),
      );
    }
    if (_selectedCategories.isNotEmpty) {
      forBrands = forBrands.where(
        (p) => _selectedCategories.contains(p.category),
      );
    }
    for (final item in forBrands) {
      if (item.brand.isNotEmpty && item.brand.toLowerCase() != 'genérico') {
        brands.add(item.brand);
      }
    }

    // For Categories: filter base items by active brands & suppliers
    Iterable<QuoteAggregatedProduct> forCategories = items;
    if (_selectedSuppliers.isNotEmpty) {
      forCategories = forCategories.where(
        (p) => p.suppliersInfo.any(
          (info) => _selectedSuppliers.contains(info['id']),
        ),
      );
    }
    if (_selectedBrands.isNotEmpty) {
      forCategories = forCategories.where(
        (p) => _selectedBrands.contains(p.brand),
      );
    }
    for (final item in forCategories) {
      if (item.category.isNotEmpty) categories.add(item.category);
    }

    // For Suppliers: filter base items by active brands & categories
    Iterable<QuoteAggregatedProduct> forSuppliers = items;
    if (_selectedBrands.isNotEmpty) {
      forSuppliers = forSuppliers.where(
        (p) => _selectedBrands.contains(p.brand),
      );
    }
    if (_selectedCategories.isNotEmpty) {
      forSuppliers = forSuppliers.where(
        (p) => _selectedCategories.contains(p.category),
      );
    }
    // Extraer proveedores del nuevo formato unificado
    for (final item in forSuppliers) {
      for (final info in item.suppliersInfo) {
        final id = info['id'];
        final name = info['name'];

        if (id != null && name != null && name.trim().isNotEmpty) {
          suppliers[id] = name;
          _supplierNameCache[id] = name;
        }
      }
    }

    return (categories: categories, brands: brands, suppliers: suppliers);
  }

  // --- Filter Logic ---

  void _showSupplierFilter() {
    final facets = _getAvailableFacets();
    final availableSuppliers = facets.suppliers;

    // Sort by name
    final options = availableSuppliers.keys.toList()
      ..sort(
        (a, b) => (availableSuppliers[a] ?? '').compareTo(
          availableSuppliers[b] ?? '',
        ),
      );

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Proveedor',
      options: options,
      selectedValues: _selectedSuppliers,
      labelBuilder: (id) => availableSuppliers[id] ?? id,
      onApply: (selected) {
        setState(() {
          _selectedSuppliers = selected.toSet();
        });
      },
    );
  }

  void _showBrandFilter() {
    final facets = _getAvailableFacets();

    final availableBrands = facets.brands.toList()..sort();

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

  void _showCategoryFilter() {
    final facets = _getAvailableFacets();
    final availableCategories = facets.categories.toList()..sort();

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
    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.valueOrNull;
    final isVerified = userProfile?.verificationStatus == 'verified';
    final colors = Theme.of(context).colorScheme;

    // 1. Fetch base query for Facets (fast UI)
    final baseParams = ProductSearchParams(query: _currentQuery);
    ref.watch(quoteProductSuggestionsProvider(baseParams));

    // 2. Fetch filtered query for Data
    final filterParams = ProductSearchParams(
      query: _currentQuery,
      filters: ProductSearchFilters(
        brands: _selectedBrands.toList(),
        categories: _selectedCategories.toList(),
        supplierIds: _selectedSuppliers.toList(),
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      ),
    );

    final suggestionsAsync = ref.watch(
      quoteProductSuggestionsProvider(filterParams),
    );

    final quoteProducts = ref.watch(createQuoteProvider).products;

    var filteredProducts = suggestionsAsync.valueOrNull ?? [];

    // Local Verification Rules
    filteredProducts = filteredProducts.where((p) {
      if (!isVerified) {
        if (!p.hasOwnInventory &&
            p.supplierCount == 1 &&
            p.firstSupplierTradeType == 'WHOLESALE') {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort Logic
    filteredProducts.sort((a, b) {
      switch (_currentSort) {
        case SortOption.lowestPrice:
          return a.minPrice.compareTo(b.minPrice);
        case SortOption.highestPrice:
          return b.minPrice.compareTo(a.minPrice);
        case SortOption.quantityAsc:
          return a.totalQuantity.compareTo(b.totalQuantity);
        case SortOption.quantityDesc:
          return b.totalQuantity.compareTo(a.totalQuantity);
        case SortOption.nameAZ:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortOption.nameZA:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        default:
          return 0;
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
      initialQuery: widget.initialQuery,

      // Filter Chips Configuration
      filters: [
        FilterChipData(
          label: _getChipLabel(
            'Proveedor',
            _selectedSuppliers,
            nameMap: _supplierNameCache,
          ),
          isActive: _selectedSuppliers.isNotEmpty,
          onTap: _showSupplierFilter,
        ),
        FilterChipData(
          label: _getChipLabel('Categoría', _selectedCategories),
          isActive: _selectedCategories.isNotEmpty,
          onTap: _showCategoryFilter,
        ),
        FilterChipData(
          label: _getChipLabel('Marca', _selectedBrands),
          isActive: _selectedBrands.isNotEmpty,
          onTap: _showBrandFilter,
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
              child: SortSelector(
                currentSort: _currentSort,
                options: const [
                  SortOption.nameAZ,
                  SortOption.nameZA,
                  SortOption.highestPrice,
                  SortOption.lowestPrice,
                  SortOption.quantityDesc,
                  SortOption.quantityAsc,
                ],
                onSortChanged: (val) => setState(() => _currentSort = val),
              ),
            ),
          ],
        ),
      ),

      filter: (product, query) => SearchUtils.matchesCombo(query, [
        product.name,
        product.brand,
        product.model,
        product.category,
      ]),
      itemBuilder: (context, product) {
        final isAlreadyInQuote = quoteProducts.any(
          (p) =>
              (p.brand ?? '').trim().toUpperCase() ==
                  product.brand.trim().toUpperCase() &&
              (p.model ?? '').trim().toUpperCase() ==
                  product.model.trim().toUpperCase() &&
              p.uom.trim().toUpperCase() == product.uom.trim().toUpperCase(),
        );

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
            uomIconName: product.uomIconName,
            imageUrl: product.imageUrl,
            showPriceAndStock: true,
            isLocked: product.isLocked,
            isAlreadyAdded: isAlreadyInQuote,
            onTap: () {
              if (isAlreadyInQuote) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Este producto ya se encuentra en la cotización',
                    ),
                  ),
                );
                return;
              }

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
