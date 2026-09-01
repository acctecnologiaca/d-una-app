import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product_model.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../widgets/inventory_item_card.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../widgets/inventory_action_sheet.dart';
import '../../providers/products_provider.dart';
import '../../providers/lookup_providers.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/brand_model.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../../ads/presentation/providers/ads_provider.dart';

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

  void _showCategoryFilter() async {
    final allCategories = await ref.read(categoriesProvider.future);
    final currentProducts = ref.read(paginatedProductSearchProvider).valueOrNull?.items ?? [];
    
    Iterable<Category> availableCategories = allCategories;
    if (currentProducts.isNotEmpty) {
      final validCategoryIds = currentProducts.map((p) => p.categoryId).whereType<String>().toSet();
      availableCategories = allCategories.where((c) => validCategoryIds.contains(c.id) || _selectedCategories.contains(c.name));
    }
    
    final options = availableCategories.map((c) => c.name).toList();

    if (!mounted) return;

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Categoría',
      options: options,
      selectedValues: _selectedCategories,
      onApply: (selected) {
        setState(() {
          _selectedCategories.clear();
          _selectedCategories.addAll(selected);
        });

        String? categoryId;
        if (selected.isNotEmpty) {
          final catName = selected.first;
          categoryId = allCategories.firstWhere((c) => c.name == catName).id;
        }

        ref
            .read(paginatedProductSearchProvider.notifier)
            .updateFilters(categoryId: categoryId);
      },
    );
  }

  void _showBrandFilter() async {
    final allBrands = await ref.read(brandsProvider.future);
    final currentProducts = ref.read(paginatedProductSearchProvider).valueOrNull?.items ?? [];
    
    Iterable<Brand> availableBrands = allBrands;
    if (currentProducts.isNotEmpty) {
      final validBrandIds = currentProducts.map((p) => p.brandId).whereType<String>().toSet();
      availableBrands = allBrands.where((b) => validBrandIds.contains(b.id) || _selectedBrands.contains(b.name));
    }
    
    final options = availableBrands.map((b) => b.name).toList();

    if (!mounted) return;

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Marca',
      options: options,
      selectedValues: _selectedBrands,
      onApply: (selected) {
        setState(() {
          _selectedBrands.clear();
          _selectedBrands.addAll(selected);
        });

        String? brandId;
        if (selected.isNotEmpty) {
          final brandName = selected.first;
          brandId = allBrands.firstWhere((b) => b.name == brandName).id;
        }

        ref
            .read(paginatedProductSearchProvider.notifier)
            .updateFilters(brandId: brandId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedProductSearchProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final occupationIds = <String>[
      if (userProfile?.occupationId != null) userProfile!.occupationId!,
      ...userProfile?.secondaryOccupationIds ?? [],
    ];

    final isAdsEnabled =
        ref.watch(isAdPlacementEnabledProvider('product_search'));
    final adBannersAsync = isAdsEnabled
        ? ref.watch(
            adBannersProvider(
              AdBannerParams(
                occupationIds: occupationIds,
              ),
            ),
          )
        : null;

    return GenericSearchScreen<Product>(
      hintText: 'Buscar productos...',
      historyKey: _getHistoryKey(),
      isPaginatedMode: true,
      paginatedDataAsync: paginatedAsync,
      banners: isAdsEnabled ? adBannersAsync?.valueOrNull : null,
      screenContext: 'own_inventory_search',
      onServerSearch: (query) {
        ref.read(paginatedProductSearchProvider.notifier).updateSearch(query);
      },
      onLoadMore: () {
        ref.read(paginatedProductSearchProvider.notifier).loadMore();
      },
      onResetFilters: () {
        setState(() {
          _currentSort = SortOption.lowestPrice;
          _selectedCategories.clear();
          _selectedBrands.clear();
        });
        ref.read(paginatedProductSearchProvider.notifier).updateSearch(null);
        ref
            .read(paginatedProductSearchProvider.notifier)
            .updateFilters(categoryId: null, brandId: null);
        ref
            .read(paginatedProductSearchProvider.notifier)
            .updateSort('created_at', false);
      },
      onQueryChanged: (query) {
        // Debounced by server search
      },
      filters: [
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
      ],
      bottomFilterWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SortSelector(
          currentSort: _currentSort,
          options: _sortOptions,
          onSortChanged: (val) {
            setState(() {
              _currentSort = val;
            });
            String orderBy = 'created_at';
            bool ascending = false;
            if (val == SortOption.nameAZ) {
              orderBy = 'name';
              ascending = true;
            } else if (val == SortOption.nameZA) {
              orderBy = 'name';
              ascending = false;
            } else if (val == SortOption.highestPrice) {
              orderBy = 'average_cost';
              ascending = false;
            } else if (val == SortOption.lowestPrice) {
              orderBy = 'average_cost';
              ascending = true;
            } else if (val == SortOption.quantityDesc) {
              orderBy = 'inventory_quantity';
              ascending = false;
            } else if (val == SortOption.quantityAsc) {
              orderBy = 'inventory_quantity';
              ascending = true;
            }

            ref
                .read(paginatedProductSearchProvider.notifier)
                .updateSort(orderBy, ascending);
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
        final normalizedQuery = query.normalizeFingerprint;
        final matchesQuery =
            normalizedQuery.isEmpty ||
            p.name.normalizeFingerprint.contains(normalizedQuery) ||
            (p.brand?.name.normalizeFingerprint ?? '').contains(
              normalizedQuery,
            ) ||
            (p.model?.normalizeFingerprint ?? '').contains(normalizedQuery);

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
