import 'dart:async';
import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/generic_search_screen.dart';
import 'package:d_una_app/shared/widgets/filter_bottom_sheet.dart';
import 'package:d_una_app/shared/widgets/price_filter_sheet.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';
import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';
import 'package:d_una_app/features/portfolio/domain/models/aggregated_product.dart';
import 'package:d_una_app/features/portfolio/domain/models/search_result_item.dart';
import 'package:d_una_app/features/portfolio/presentation/suppliers_directory/widgets/compact_supplier_card.dart';
import 'package:d_una_app/shared/widgets/aggregated_product_card.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/product_search_provider.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/portfolio/domain/models/product_search_filters.dart';
import 'package:d_una_app/features/portfolio/presentation/suppliers_directory/screens/product_suppliers_screen.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import '../../../../profile/domain/models/user_profile.dart'; // Ensure model is available if needed
import '../../../domain/models/product_sort_option.dart';

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
  ProductSortOption _currentSort = ProductSortOption.priceAsc;

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
      _currentSort = ProductSortOption.priceAsc;
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

  // --- Facet Extraction ---

  ({Set<String> categories, Set<String> brands}) _getAvailableFacets() {
    // If no query, return empty sets to indicate "show all"
    if (_currentQuery.trim().isEmpty) {
      return (categories: <String>{}, brands: <String>{});
    }

    // Note: productSearchProvider returns List<AggregatedProduct>
    final searchState = ref.read(
      productSearchProvider(
        ProductSearchParams(query: _currentQuery.normalized, filters: _filters),
      ),
    );

    final items = searchState.valueOrNull ?? [];
    final categories = <String>{};
    final brands = <String>{};

    for (final item in items) {
      // item is AggregatedProduct directly
      if (item.category.isNotEmpty) {
        categories.add(item.category);
      }
      if (item.brand.isNotEmpty) {
        brands.add(item.brand);
      }
    }

    return (categories: categories, brands: brands);
  }

  void _showCategoryFilter() async {
    final allCategories = await ref.read(categoriesProvider.future);
    final facets = _getAvailableFacets();

    // Filter options:
    // If facets are empty (no query), show all.
    // If facets exist, show only those in facets OR currently selected.
    final availableCategories = facets.categories.isEmpty
        ? allCategories
        : allCategories
              .where(
                (c) =>
                    facets.categories.contains(c.name) ||
                    _filters.categories.contains(c.name),
              )
              .toList();

    final options = availableCategories.map((c) => c.name).toList();

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
    final allBrands = await ref.read(brandsProvider.future);
    final facets = _getAvailableFacets();

    // Filter options:
    // If facets are empty (no query), show all.
    // If facets exist, show only those in facets OR currently selected.
    final availableBrands = facets.brands.isEmpty
        ? allBrands
        : allBrands
              .where(
                (b) =>
                    facets.brands.contains(b.name) ||
                    _filters.brands.contains(b.name),
              )
              .toList();

    final options = availableBrands.map((b) => b.name).toList();

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

    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.valueOrNull;

    // 2. Combine Data into unified list
    final combinedAsync = _combineData(
      suppliersAsync,
      productsAsync,
      userProfile,
    );

    // Dynamic label helpers
    final suppliers = suppliersAsync.valueOrNull ?? [];
    final supplierNameMap = {for (var s in suppliers) s.id: s.name};
    final colors = Theme.of(context).colorScheme;

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
          final s = item.supplier;
          bool isLocked = false;
          final isVerified = userProfile?.verificationStatus == 'verified';
          final isBusiness = userProfile?.verificationType == 'business';

          if (!isVerified) {
            // Unverified: Wholesale is visible but locked
            if (s.tradeType == 'WHOLESALE') {
              isLocked = true;
            }
          } else {
            // Verified: Check specific restrictions
            // If Business: Unlocked (isLocked remains false)
            // If Individual: Lock if Wholesale doesn't accept 'individual'
            if (!isBusiness && s.tradeType == 'WHOLESALE') {
              // If allowedTypes is empty, we generally assume open or check specific rule.
              // Assuming logic: if explicitly listed, must be in it.
              // (Reuse logic from ProductSuppliersScreen)
              if (s.allowedVerificationTypes.isNotEmpty &&
                  !s.allowedVerificationTypes.contains('individual')) {
                isLocked = true;
              }
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: CompactSupplierCard(
              supplier: item.supplier,
              isLocked: isLocked,
              onTap: () {
                if (isLocked) return;
                // Navigate to Supplier Details (Product List filtered by Supplier)
                // Re-use SupplierSearchScreen but pre-filtered
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SupplierSearchScreen(initialSupplierId: s.id),
                  ),
                );
              },
            ),
          );
        } else if (item is ProductResultItem) {
          final p = item.product;
          final isProductLocked = p.isLocked;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: AggregatedProductCard(
              name: item.product.name,
              brand: item.product.brand,
              model: item.product.model,
              minPrice: item.product.minPrice,
              totalQuantity: item.product.totalQuantity,
              supplierCount: item.product.supplierCount,
              uom: item.product.uom,
              isLocked: isProductLocked,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductSuppliersScreen(
                      product: item.product,
                      filters: _filters,
                    ),
                  ),
                );
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
    UserProfile? userProfile,
  ) {
    if (suppliersAsync.isLoading || productsAsync.isLoading) {
      return const AsyncValue.loading();
    }

    // Logic from previous implementation to filter Suppliers locally
    // (Product filtering is server-side, Supplier filtering is client-side text match)
    final suppliers = suppliersAsync.valueOrNull ?? [];
    final products = productsAsync.valueOrNull ?? [];

    // Filter suppliers by query & types locally (matches previous logic)
    // Filter suppliers by query & types locally (matches previous logic)
    // We removed the visibility filter here so Unverified users can see Wholesale suppliers (locked).
    final matchedSuppliers = suppliers.where((s) {
      final matchesName = s.name.normalized.contains(_currentQuery.normalized);
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
      // Sort Products
      var sortedProducts = List<AggregatedProduct>.from(products);

      // Filter Logic for Products (Best Effort for Unverified)
      final isVerified = userProfile?.verificationStatus == 'verified';
      if (!isVerified) {
        sortedProducts = sortedProducts.where((p) {
          // If purely wholesale (or single wholesale supplier), hide it
          if (p.supplierCount == 1 && p.firstSupplierTradeType == 'WHOLESALE') {
            return false;
          }
          // If multiple suppliers, we assume some *might* be retail, allow visibility.
          // Or strictly enforce 'no wholesale at all'? But we lack granular data here.
          // Let's hide if we detect ANY wholesale flag if we want stricter rules,
          // but firstSupplierTradeType is our best hint.
          return true;
        }).toList();
      }

      sortedProducts.sort((a, b) {
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

      items.add(const HeaderResultItem('Productos'));
      for (final p in sortedProducts) {
        items.add(ProductResultItem(p));
      }
    } else if (items.isEmpty && _currentQuery.isNotEmpty) {
      // Return empty list to trigger Empty State
      return const AsyncValue.data([]);
    }

    return AsyncValue.data(items);
  }
}
