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
import '../../../../portfolio/domain/models/aggregated_product.dart';
import '../../../../portfolio/domain/models/product_search_filters.dart';
import '../../supplier_orders_list/providers/supplier_orders_providers.dart';
import '../providers/create_supplier_order_provider.dart';
import '../providers/supplier_order_product_selection_provider.dart';

class SupplierOrderProductSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SupplierOrderProductSearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SupplierOrderProductSearchScreen> createState() =>
      _SupplierOrderProductSearchScreenState();
}

class _SupplierOrderProductSearchScreenState
    extends ConsumerState<SupplierOrderProductSearchScreen> {
  late final String _currentQuery = widget.initialQuery ?? '';
  SortOption _currentSort = SortOption.nameAZ;

  // Filters State
  Set<String> _selectedBrands = {};
  Set<String> _selectedCategories = {};
  Set<String> _selectedBranchIds = {};
  double? _minPrice;
  double? _maxPrice;

  void _resetFilters() {
    setState(() {
      _selectedBrands.clear();
      _selectedCategories.clear();
      _selectedBranchIds.clear();
      _minPrice = null;
      _maxPrice = null;
      _currentSort = SortOption.nameAZ;
    });
    ref
        .read(paginatedSupplierOrderProductSearchProvider.notifier)
        .updateFilters(const ProductSearchFilters());
    ref
        .read(paginatedSupplierOrderProductSearchProvider.notifier)
        .updateBranchFilter([]);
  }

  String _getChipLabel(String defaultLabel, Set<String> selected, {Map<String, String>? nameMap}) {
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

  ({Set<String> categories, Set<String> brands}) _getAvailableFacets() {
    final supplierId = ref.read(createSupplierOrderProvider).supplierId ?? '';
    final baseState = ref.read(
      supplierOrderProductSuggestionsProvider(supplierId: supplierId, query: _currentQuery),
    );

    final items = baseState.valueOrNull ?? [];
    final categories = <String>{};
    final brands = <String>{};

    for (final item in items) {
      if (item.brand.isNotEmpty && item.brand.toLowerCase() != 'genérico') {
        brands.add(item.brand);
      }
      if (item.category.isNotEmpty) {
        categories.add(item.category);
      }
    }

    return (categories: categories, brands: brands);
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
        _applyFiltersToServer();
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
        _applyFiltersToServer();
      },
    );
  }

  void _showBranchFilter(List<Map<String, dynamic>> branches) {
    final options = branches.map((b) => b['id'] as String).toList();
    final nameMap = {for (final b in branches) b['id'] as String: b['name'] as String};

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Sucursal',
      options: options,
      selectedValues: _selectedBranchIds,
      labelBuilder: (id) => nameMap[id] ?? id,
      onApply: (selected) {
        setState(() {
          _selectedBranchIds = selected.toSet();
        });
        ref
            .read(paginatedSupplierOrderProductSearchProvider.notifier)
            .updateBranchFilter(_selectedBranchIds.toList());
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
          _applyFiltersToServer();
        },
      ),
    );
  }

  void _applyFiltersToServer() {
    ref
        .read(paginatedSupplierOrderProductSearchProvider.notifier)
        .updateFilters(
          ProductSearchFilters(
            brands: _selectedBrands.toList(),
            categories: _selectedCategories.toList(),
            minPrice: _minPrice,
            maxPrice: _maxPrice,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final orderState = ref.watch(createSupplierOrderProvider);
    final supplierId = orderState.supplierId ?? '';
    final orderItems = orderState.items;

    // Load facets base data
    ref.watch(supplierOrderProductSuggestionsProvider(supplierId: supplierId, query: _currentQuery));

    final paginatedAsync = ref.watch(paginatedSupplierOrderProductSearchProvider);

    final branchesAsync = ref.watch(supplierBranchesProvider(supplierId));
    final branches = branchesAsync.valueOrNull ?? [];
    final hasBranches = branches.isNotEmpty;
    final branchNameMap = {for (final b in branches) b['id'] as String: b['name'] as String};

    return GenericSearchScreen<AggregatedProduct>(
      title: 'Buscar Producto',
      hintText: 'Buscar productos, modelos, marcas...',
      historyKey: 'supplier_order_product_search_history',
      isPaginatedMode: true,
      paginatedDataAsync: paginatedAsync,
      onServerSearch: (query) {
        ref
            .read(paginatedSupplierOrderProductSearchProvider.notifier)
            .updateSearch(query);
      },
      onLoadMore: () {
        ref.read(paginatedSupplierOrderProductSearchProvider.notifier).loadMore();
      },
      onResetFilters: _resetFilters,
      initialQuery: widget.initialQuery,
      filters: [
        if (hasBranches)
          FilterChipData(
            label: _getChipLabel('Sucursal', _selectedBranchIds, nameMap: branchNameMap),
            isActive: _selectedBranchIds.isNotEmpty,
            onTap: () => _showBranchFilter(branches),
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        final isAlreadyInOrder = orderItems.any(
          (item) =>
              (item.brand ?? '').trim().toUpperCase() == product.brand.trim().toUpperCase() &&
              (item.model ?? '').trim().toUpperCase() == product.model.trim().toUpperCase() &&
              item.uom.trim().toUpperCase() == product.uom.trim().toUpperCase(),
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
            imageUrl: null,
            showPriceAndStock: true,
            isLocked: product.isLocked,
            isAlreadyAdded: isAlreadyInOrder,
            onTap: () {
              if (isAlreadyInOrder) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Este producto ya se encuentra en la orden de compra',
                    ),
                  ),
                );
                return;
              }

              context
                  .push(
                    '/supplier-orders/create/select-product/branches',
                    extra: product,
                  )
                  .then((result) {
                    if (result == true) {
                      if (context.mounted) {
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
