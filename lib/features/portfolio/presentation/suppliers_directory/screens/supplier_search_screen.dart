import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/generic_search_screen.dart';
import 'package:d_una_app/shared/widgets/filter_bottom_sheet.dart';
import 'package:d_una_app/shared/widgets/price_filter_sheet.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';
import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';
import 'package:d_una_app/features/portfolio/domain/models/aggregated_product.dart';
import 'package:d_una_app/features/portfolio/domain/models/search_result_item.dart';
import 'package:d_una_app/features/portfolio/presentation/suppliers_directory/widgets/compact_supplier_card.dart';
import 'package:d_una_app/features/portfolio/presentation/suppliers_directory/widgets/aggregated_product_card.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/product_search_provider.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/portfolio/domain/models/product_search_filters.dart';
import 'package:d_una_app/features/portfolio/presentation/suppliers_directory/widgets/product_action_sheet.dart';
import 'package:d_una_app/features/portfolio/presentation/suppliers_directory/screens/product_suppliers_screen.dart';

class SupplierSearchScreen extends ConsumerStatefulWidget {
  final String? initialSupplierId;

  const SupplierSearchScreen({super.key, this.initialSupplierId});

  @override
  ConsumerState<SupplierSearchScreen> createState() =>
      _SupplierSearchScreenState();
}

class _SupplierSearchScreenState extends ConsumerState<SupplierSearchScreen> {
  // Query state maintained by GenericSearchScreen, but we need it for provider params
  String _currentQuery = '';
  late ProductSearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialSupplierId != null
        ? ProductSearchFilters(supplierIds: [widget.initialSupplierId!])
        : const ProductSearchFilters();
  }

  // Suppliers Filter State (Kept for compatibility)
  final Set<String> _selectedTradeTypes = {};

  void _onQueryChanged(String query) {
    // Debounce is handled by GenericSearchScreen updates?
    // GenericSearchScreen calls onQueryChanged instantly on text changed.
    // We should implement local debounce here if we trigger API calls.
    // Actually, productSearchProvider listens to this params.
    // Let's debounce the setState update.
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _currentQuery = query;
        });
      }
    });
  }

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _filters = const ProductSearchFilters();
      _selectedTradeTypes.clear();
    });
  }

  // --- Dynamic Label Helpers ---

  String _getChipLabel(
    String defaultLabel,
    Set<String> selected, [
    Map<String, String>? nameMap,
  ]) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) {
      final value = selected.first;
      return nameMap?[value] ?? value;
    }
    // For multiple: "First + N"
    final first = nameMap?[selected.first] ?? selected.first;
    return '$first +${selected.length - 1}';
  }

  String _getPriceLabel() {
    final min = _filters.minPrice;
    final max = _filters.maxPrice;
    if (min == null && max == null) return 'Precio';

    if (min != null && max != null) {
      return '\$${min.toInt()} - \$${max.toInt()}';
    } else if (min != null) {
      return '> \$${min.toInt()}';
    } else {
      return '< \$${max!.toInt()}';
    }
  }

  // --- Filter Logic ---

  void _showSupplierFilter() {
    final suppliers = ref.read(suppliersProvider).valueOrNull ?? [];
    final options = suppliers.map((s) => s.id).toList();
    final nameMap = {for (var s in suppliers) s.id: s.name};

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Proveedor',
      options: options,
      selectedValues: _filters.supplierIds.toSet(),
      labelBuilder: (id) => nameMap[id] ?? id,
      onApply: (selected) {
        setState(() {
          _filters = _filters.copyWith(supplierIds: selected.toList());
        });
      },
    );
  }

  void _showCategoryFilter() async {
    final categories = await ref.read(categoriesProvider.future);
    final options = categories.map((c) => c.name).toList();

    if (!mounted) return;

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Categoría',
      options: options,
      selectedValues: _filters.categories.toSet(),
      onApply: (selected) {
        setState(() {
          _filters = _filters.copyWith(categories: selected.toList());
        });
      },
    );
  }

  void _showBrandFilter() async {
    final brands = await ref.read(brandsProvider.future);
    final options = brands.map((b) => b.name).toList();

    if (!mounted) return;

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Marca',
      options: options,
      selectedValues: _filters.brands.toSet(),
      onApply: (selected) {
        setState(() {
          _filters = _filters.copyWith(brands: selected.toList());
        });
      },
    );
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PriceFilterSheet(
        initialMin: _filters.minPrice,
        initialMax: _filters.maxPrice,
        onApply: (min, max) {
          setState(() {
            _filters = _filters.copyWith(minPrice: min, maxPrice: max);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch Data
    final suppliersAsync = ref.watch(suppliersProvider);
    final productsAsync = ref.watch(
      productSearchProvider(
        ProductSearchParams(query: _currentQuery.normalized, filters: _filters),
      ),
    );

    // 2. Combine Data into unified list
    final combinedAsync = _combineData(suppliersAsync, productsAsync);

    // Dynamic label helpers
    final suppliers = suppliersAsync.valueOrNull ?? [];
    final supplierNameMap = {for (var s in suppliers) s.id: s.name};

    return GenericSearchScreen<SearchResultItem>(
      title: 'Proveedores',
      hintText: 'Buscar proveedores, productos, marcas...',
      historyKey: 'supplier_search_history',
      data: combinedAsync,
      // We handle query updates via onQueryChanged to feed the provider
      onQueryChanged: _onQueryChanged,
      onResetFilters: _resetFilters,
      bottomFilterWidget: Padding(
        padding: const EdgeInsets.only(
          top: 8.0,
          left: 16,
          right: 16,
          bottom: 8.0,
        ),
        child: Text(
          'Precios no incluyen impuesto y pueden variar sin previo aviso',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),

      // Filter Chips Configuration
      filters: [
        FilterChipData(
          label: _getChipLabel(
            'Proveedor',
            _filters.supplierIds.toSet(),
            supplierNameMap,
          ),
          isActive: _filters.supplierIds.isNotEmpty,
          onTap: _showSupplierFilter,
        ),
        FilterChipData(
          label: _getChipLabel('Categoría', _filters.categories.toSet()),
          isActive: _filters.categories.isNotEmpty,
          onTap: _showCategoryFilter,
        ),
        FilterChipData(
          label: _getChipLabel('Marca', _filters.brands.toSet()),
          isActive: _filters.brands.isNotEmpty,
          onTap: _showBrandFilter,
        ),
        FilterChipData(
          label: _getPriceLabel(),
          isActive: _filters.minPrice != null || _filters.maxPrice != null,
          onTap: _showPriceFilter,
        ),
      ],

      // Filter Predicate: Always true because filtering is done by Providers upstream
      // GenericSearchScreen might run this check, so we ensure it passes.
      filter: (item, query) => true,

      itemBuilder: (context, item) {
        if (item is HeaderResultItem) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              item.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        } else if (item is DividerResultItem) {
          return const Divider(height: 32);
        } else if (item is SupplierResultItem) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: CompactSupplierCard(supplier: item.supplier, onTap: () {}),
          );
        } else if (item is ProductResultItem) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: AggregatedProductCard(
              product: item.product,
              onTap: () {
                // Always navigate to ProductSuppliersScreen as per new UX requirement.
                // Single supplier might have multiple branches.
                /* 
                // Previous Logic: Open Action Sheet if single supplier
                if (item.product.supplierCount == 1 &&
                    item.product.firstSupplierId != null) {
                  ProductActionSheet.show(
                    context,
                    supplierName: item.product.firstSupplierName ?? 'Proveedor',
                    productName: item.product.name,
                    price: item.product.minPrice,
                    stock: item.product.totalQuantity,
                    isWholesale:
                        item.product.firstSupplierTradeType == 'WHOLESALE',
                  );
                } else { 
                */
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductSuppliersScreen(
                      product: item.product,
                      filters: _filters,
                    ),
                  ),
                );
                // }
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  AsyncValue<List<SearchResultItem>> _combineData(
    AsyncValue<List<Supplier>> suppliersAsync,
    AsyncValue<List<AggregatedProduct>> productsAsync,
  ) {
    if (suppliersAsync.isLoading || productsAsync.isLoading) {
      return const AsyncValue.loading();
    }

    // Logic from previous implementation to filter Suppliers locally
    // (Product filtering is server-side, Supplier filtering is client-side text match)
    final suppliers = suppliersAsync.valueOrNull ?? [];
    final products = productsAsync.valueOrNull ?? [];

    // Filter suppliers by query & types locally (matches previous logic)
    final matchedSuppliers = suppliers.where((s) {
      final matchesName = s.name.normalized.contains(_currentQuery.normalized);
      // Simple Trade Filter logic if we were using it, but _selectedTradeTypes is cleared/unused in new filters?
      // The new filter chips (Supplier, Cat, Brand, Price) are Product focused.
      // The previous implementation used _selectedTradeTypes.
      // I'll skip trade type logic for now as it wasn't in the new chips list.
      return matchesName;
    }).toList();

    List<SearchResultItem> items = [];

    // 1. Suppliers Section
    // Only show if no pure-product filters are active (logic from previous code)
    bool hasProductFilters =
        _filters.brands.isNotEmpty ||
        _filters.categories.isNotEmpty ||
        _filters.supplierIds.isNotEmpty ||
        _filters.minPrice != null ||
        _filters.maxPrice != null;

    if (matchedSuppliers.isNotEmpty && !hasProductFilters) {
      items.add(const HeaderResultItem('Proveedores'));
      // Show top 3 or all? Previous code had "View All" logic.
      // GenericSearchScreen doesn't support "View All" toggle easily inside itemBuilder.
      // We will show ALL matched suppliers if "View All" isn't feasible,
      // OR we just limit to 3 for compactness if there are products.
      final showLimit = (products.isNotEmpty) ? 3 : matchedSuppliers.length;
      final count = (matchedSuppliers.length > showLimit)
          ? showLimit
          : matchedSuppliers.length;

      for (var i = 0; i < count; i++) {
        items.add(SupplierResultItem(matchedSuppliers[i]));
      }

      if (products.isNotEmpty) {
        items.add(const DividerResultItem());
      }
    }

    // 2. Products Section
    if (products.isNotEmpty) {
      items.add(const HeaderResultItem('Productos'));
      for (final p in products) {
        items.add(ProductResultItem(p));
      }
    } else if (items.isEmpty && _currentQuery.isNotEmpty) {
      // Return empty list to trigger Empty State
      return const AsyncValue.data([]);
    }

    return AsyncValue.data(items);
  }
}
