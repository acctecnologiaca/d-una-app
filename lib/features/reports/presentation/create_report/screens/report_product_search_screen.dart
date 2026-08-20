import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/horizontal_filter_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../../portfolio/data/models/product_model.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../providers/create_report_provider.dart';
import '../providers/report_product_selection_provider.dart';
import '../widgets/report_product_selection_card.dart';
import '../widgets/report_product_sale_details_sheet.dart';

class ReportProductSearchScreen extends ConsumerStatefulWidget {
  const ReportProductSearchScreen({super.key});

  @override
  ConsumerState<ReportProductSearchScreen> createState() =>
      _ReportProductSearchScreenState();
}

class _ReportProductSearchScreenState
    extends ConsumerState<ReportProductSearchScreen> {
  final Set<String> _selectedCategories = {};
  final Set<String> _selectedBrands = {};
  SortOption _currentSort = SortOption.recent;

  String? _selectedProductId;
  double _selectedQuantity = 0.0;
  Product? _selectedProduct;

  String _getChipLabel(String defaultLabel, Set<String> selected) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) return selected.first;
    return '${selected.first} +${selected.length - 1}';
  }

  void _showCategoryFilter(List<Product> products) async {
    final allCategories = await ref.read(categoriesProvider.future);
    final availableCategoryNames = products
        .map((p) => p.category?.name)
        .whereType<String>()
        .toSet();

    final options = allCategories
        .where(
          (c) =>
              availableCategoryNames.contains(c.name) ||
              _selectedCategories.contains(c.name),
        )
        .map((c) => c.name)
        .toList();

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
      },
    );
  }

  void _showBrandFilter(List<Product> products) async {
    final allBrands = await ref.read(brandsProvider.future);
    final availableBrandNames = products
        .map((p) => p.brand?.name)
        .whereType<String>()
        .toSet();

    final options = allBrands
        .where(
          (b) =>
              availableBrandNames.contains(b.name) ||
              _selectedBrands.contains(b.name),
        )
        .map((b) => b.name)
        .toList();

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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(reportOwnProductSuggestionsProvider);
    final reportState = ref.watch(createReportProvider);
    final reportProducts = reportState.products;
    final allProducts = productsAsync.valueOrNull ?? [];

    final hasSelection = _selectedQuantity > 0 && _selectedProduct != null;

    final formattedQty =
        _selectedQuantity.truncateToDouble() == _selectedQuantity
        ? _selectedQuantity.toInt().toString()
        : _selectedQuantity.toStringAsFixed(2);
    final totalCost =
        (_selectedProduct?.averageCost ?? 0.0) * _selectedQuantity;
    final formattedTotal = CurrencyFormatter.format(totalCost);
    final uom = _selectedProduct?.uom ?? 'ud.';

    return GenericSearchScreen<Product>(
      hintText: 'Buscar producto...',
      historyKey: 'report_product_search_history',
      data: productsAsync,
      filter: (product, query) {
        final normQuery = query.normalized;
        final matchesQuery =
            query.isEmpty ||
            product.name.normalized.contains(normQuery) ||
            (product.brand?.name.normalized.contains(normQuery) ?? false) ||
            (product.model?.normalized.contains(normQuery) ?? false);

        final matchesCategory =
            _selectedCategories.isEmpty ||
            (product.category?.name != null &&
                _selectedCategories.contains(product.category!.name));

        final matchesBrand =
            _selectedBrands.isEmpty ||
            (product.brand?.name != null &&
                _selectedBrands.contains(product.brand!.name));

        return matchesQuery && matchesCategory && matchesBrand;
      },
      comparator: (a, b) {
        switch (_currentSort) {
          case SortOption.nameAZ:
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case SortOption.nameZA:
            return b.name.toLowerCase().compareTo(a.name.toLowerCase());
          case SortOption.recent:
          default:
            return b.updatedAt.compareTo(a.updatedAt);
        }
      },
      filters: [
        FilterChipData(
          label: _getChipLabel('Categoría', _selectedCategories),
          isActive: _selectedCategories.isNotEmpty,
          onTap: () => _showCategoryFilter(allProducts),
        ),
        FilterChipData(
          label: _getChipLabel('Marca', _selectedBrands),
          isActive: _selectedBrands.isNotEmpty,
          onTap: () => _showBrandFilter(allProducts),
        ),
      ],
      bottomFilterWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            SortSelector(
              currentSort: _currentSort,
              onSortChanged: (sort) {
                setState(() => _currentSort = sort);
              },
              options: const [
                SortOption.recent,
                SortOption.nameAZ,
                SortOption.nameZA,
              ],
            ),
          ],
        ),
      ),
      onResetFilters: () {
        setState(() {
          _selectedCategories.clear();
          _selectedBrands.clear();
          _currentSort = SortOption.recent;
        });
      },
      itemBuilder: (context, product) {
        final isAlreadyInReport = reportProducts.any(
          (p) => p.productId == product.id,
        );
        final isThisSelected = _selectedProductId == product.id;
        final currentQty = isThisSelected ? _selectedQuantity : 0.0;
        final isLocked =
            _selectedProductId != null && _selectedProductId != product.id;

        return ReportProductSelectionCard(
          key: ValueKey(product.id),
          product: product,
          selectedQty: currentQty,
          isLocked: isLocked,
          isAlreadyInReport: isAlreadyInReport,
          onQtyChanged: (qty) {
            setState(() {
              if (qty > 0) {
                _selectedProductId = product.id;
                _selectedQuantity = qty;
                _selectedProduct = product;
              } else {
                if (_selectedProductId == product.id) {
                  _selectedProductId = null;
                  _selectedQuantity = 0.0;
                  _selectedProduct = null;
                }
              }
            });
          },
        );
      },
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: hasSelection
          ? Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: CustomExtendedFab(
                icon: Icons.check,
                label: 'Confirmar ($formattedQty $uom - $formattedTotal)',
                isEnabled: true,
                onPressed: () async {
                  if (_selectedProduct == null || _selectedQuantity <= 0) {
                    return;
                  }

                  final item = await ReportProductSaleDetailsSheet.show(
                    context,
                    product: _selectedProduct!,
                    reportState: reportState,
                    selectedQuantity: _selectedQuantity,
                  );

                  if (item != null && context.mounted) {
                    ref.read(createReportProvider.notifier).addProduct(item);
                    Navigator.pop(context, true);
                  }
                },
              ),
            )
          : null,
    );
  }
}
