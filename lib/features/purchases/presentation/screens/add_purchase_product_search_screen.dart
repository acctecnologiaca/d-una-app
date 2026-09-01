import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/generic_search_screen.dart';
import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:d_una_app/shared/widgets/filter_bottom_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/features/portfolio/data/models/category_model.dart';
import 'package:d_una_app/features/portfolio/data/models/brand_model.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/purchase_product_selection_card.dart';
import 'package:d_una_app/features/purchases/data/models/purchase_item_product.dart';
import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_product_details_sheet.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/register_serials_dialog.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';
import 'package:d_una_app/core/utils/search_utils.dart';
import 'package:uuid/uuid.dart';

class AddPurchaseProductSearchScreen extends ConsumerStatefulWidget {
  const AddPurchaseProductSearchScreen({super.key});

  @override
  ConsumerState<AddPurchaseProductSearchScreen> createState() =>
      _AddPurchaseProductSearchScreenState();
}

class _AddPurchaseProductSearchScreenState
    extends ConsumerState<AddPurchaseProductSearchScreen> {
  Set<String> _selectedCategoryIds = {};
  Set<String> _selectedBrandIds = {};
  String _searchQuery = '';

  String? _selectedProductId;
  Product? _selectedProduct;
  double _selectedQuantity = 0.0;

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedProductSearchProvider);
    final products = paginatedAsync.valueOrNull?.items ?? [];

    final q = _searchQuery.normalized;
    final queryMatchedProducts = q.isEmpty
        ? products
        : products.where((p) {
            return p.name.normalized.contains(q) ||
                (p.brand?.name.normalized ?? '').contains(q) ||
                (p.model?.normalized ?? '').contains(q);
          }).toList();

    // Derive available categories from search results, filtered by verified or owned by the current user
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final categoryMap = queryMatchedProducts
        .map((p) => p.category)
        .whereType<Category>()
        .where((cat) => cat.isVerified || (currentUserId != null && cat.userId == currentUserId))
        .fold<Map<String, String>>({}, (map, cat) {
          map[cat.id] = cat.name.toTitleCase;
          return map;
        });

    // Derive available brands from search results, filtered by verified or owned by the current user
    final brandMap = queryMatchedProducts
        .map((p) => p.brand)
        .whereType<Brand>()
        .where(
          (brand) =>
              brand.isVerified ||
              (currentUserId != null && brand.userId == currentUserId),
        )
        .fold<Map<String, String>>({}, (map, brand) {
          map[brand.id] = brand.name.toTitleCase;
          return map;
        });

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
      title: 'Buscar producto',
      hintText: 'Nombre, marca o modelo...',
      historyKey: 'purchase_product_selection_search_history',
      isPaginatedMode: true,
      paginatedDataAsync: paginatedAsync,
      onServerSearch: (query) {
        ref.read(paginatedProductSearchProvider.notifier).updateSearch(query);
      },
      onLoadMore: () {
        ref.read(paginatedProductSearchProvider.notifier).loadMore();
      },
      onQueryChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      filters: [
        FilterChipData(
          label: HorizontalFilterBar.formatLabel(
            defaultLabel: 'Categoría',
            selectedValues: _selectedCategoryIds.toList(),
            valueToLabelMap: categoryMap,
          ),
          isActive: _selectedCategoryIds.isNotEmpty,
          onTap: () {
            FilterBottomSheet.showMulti(
              context: context,
              title: 'Categorías',
              options: categoryMap.keys.toList(),
              labelBuilder: (id) => categoryMap[id] ?? 'Desconocida',
              selectedValues: _selectedCategoryIds,
              onApply: (selected) {
                setState(() {
                  _selectedCategoryIds = selected;
                });
              },
            );
          },
        ),
        FilterChipData(
          label: HorizontalFilterBar.formatLabel(
            defaultLabel: 'Marca',
            selectedValues: _selectedBrandIds.toList(),
            valueToLabelMap: brandMap,
          ),
          isActive: _selectedBrandIds.isNotEmpty,
          onTap: () {
            FilterBottomSheet.showMulti(
              context: context,
              title: 'Marcas',
              options: brandMap.keys.toList(),
              labelBuilder: (id) => brandMap[id] ?? 'Desconocida',
              selectedValues: _selectedBrandIds,
              onApply: (selected) {
                setState(() {
                  _selectedBrandIds = selected;
                });
              },
            );
          },
        ),
      ],
      onResetFilters: () {
        setState(() {
          _selectedCategoryIds.clear();
          _selectedBrandIds.clear();
          _searchQuery = '';
          _selectedProductId = null;
          _selectedProduct = null;
          _selectedQuantity = 0.0;
        });
        ref.read(paginatedProductSearchProvider.notifier).updateSearch(null);
      },
      filter: (product, query) {
        final matchesQuery = SearchUtils.matchesCombo(query, [
          product.name,
          product.brand?.name,
          product.model,
          product.category?.name,
        ]);

        final matchesCategory =
            _selectedCategoryIds.isEmpty ||
            (product.categoryId != null &&
                _selectedCategoryIds.contains(product.categoryId));

        final matchesBrand =
            _selectedBrandIds.isEmpty ||
            (product.brandId != null &&
                _selectedBrandIds.contains(product.brandId));

        return matchesQuery && matchesCategory && matchesBrand;
      },
      itemBuilder: (context, product) {
        final addedProducts = ref.watch(addPurchaseProvider).products;
        final isAlreadyAdded = addedProducts.any(
          (p) => p.productId == product.id,
        );
        final isThisSelected = _selectedProductId == product.id;
        final currentQty = isThisSelected ? _selectedQuantity : 0.0;
        final isLocked =
            _selectedProductId != null && _selectedProductId != product.id;

        return PurchaseProductSelectionCard(
          key: ValueKey(product.id),
          product: product,
          selectedQty: currentQty,
          isLocked: isLocked,
          isAlreadyAdded: isAlreadyAdded,
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

                  final result = await AddPurchaseProductDetailsSheet.show(
                    context,
                    product: _selectedProduct!,
                    initialQuantity: _selectedQuantity,
                  );

                  if (result != null && context.mounted) {
                    final qty = (result['quantity'] as num).toDouble();
                    final cost = (result['cost_price'] as num).toDouble();
                    final hasWarranty = result['has_warranty'] as bool;
                    final wTime = (result['warranty_duration'] as num).toInt();
                    final wPeriodStr = result['warranty_period'] as String;
                    bool usesSerials = result['uses_serials'] == true;
                    final bool needsToAsk =
                        result['needs_to_ask_serials'] == true;

                    bool registerSerialsNow = false;

                    if (needsToAsk && context.mounted) {
                      final dialogResult =
                          await RegisterSerialsDialog.show(context);
                      if (dialogResult == null) return;
                      switch (dialogResult) {
                        case RegisterSerialsResult.now:
                          registerSerialsNow = true;
                          break;
                        case RegisterSerialsResult.later:
                          registerSerialsNow = false;
                          break;
                        case RegisterSerialsResult.never:
                          usesSerials = false;
                          registerSerialsNow = false;
                          break;
                      }
                    }

                    // Map period to DB value
                    final wUnit = wPeriodStr == 'Días'
                        ? 'days'
                        : wPeriodStr == 'Meses'
                        ? 'months'
                        : 'years';

                    final item = PurchaseItemProduct(
                      id: const Uuid().v4(),
                      productId: _selectedProduct!.id,
                      name: _selectedProduct!.name,
                      brand: _selectedProduct!.brand?.name,
                      model: _selectedProduct!.model,
                      uom: _selectedProduct!.uomModel?.symbol ?? 'ud.',
                      quantity: qty,
                      unitPrice: cost,
                      warrantyTime: hasWarranty ? wTime : null,
                      warrantyUnit: hasWarranty ? wUnit : null,
                      requiresSerials: usesSerials,
                    );

                    final added = ref
                        .read(addPurchaseProvider.notifier)
                        .addProduct(item);

                    if (!added) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'El producto "${_selectedProduct!.name}" ya está agregado.',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    if (registerSerialsNow) {
                      if (context.mounted) {
                        final confirmed = await context.push<bool>(
                          '/my-purchases/add/select-product/manage-serials',
                          extra: <String, dynamic>{
                            'product': _selectedProduct!,
                            'quantity': qty.toInt(),
                            'purchaseItemId': item.id,
                          },
                        );
                        if (confirmed == true && context.mounted) {
                          context.pop(); // Pop back from search
                          context.pop(); // Pop back to Add Purchase screen
                        }
                      }
                    } else {
                      if (context.mounted) {
                        context.pop(); // Pop back from search
                        context.pop(); // Pop back to Add Purchase screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Producto agregado: ${_selectedProduct!.name}',
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            )
          : null,
    );
  }
}
