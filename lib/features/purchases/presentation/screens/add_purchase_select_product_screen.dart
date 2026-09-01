import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import 'package:d_una_app/shared/widgets/paginated_list_view.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';
import 'package:d_una_app/features/purchases/data/models/purchase_item_product.dart';
import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/purchase_product_selection_card.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_product_details_sheet.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/register_serials_dialog.dart';
import 'package:uuid/uuid.dart';

class AddPurchaseSelectProductScreen extends ConsumerStatefulWidget {
  const AddPurchaseSelectProductScreen({super.key});

  @override
  ConsumerState<AddPurchaseSelectProductScreen> createState() =>
      _AddPurchaseSelectProductScreenState();
}

class _AddPurchaseSelectProductScreenState
    extends ConsumerState<AddPurchaseSelectProductScreen> {
  SortOption _currentSort = SortOption.recent;
  String? _selectedProductId;
  Product? _selectedProduct;
  double _selectedQuantity = 0.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final paginatedAsync = ref.watch(paginatedProductsProvider);

    final hasSelection = _selectedQuantity > 0 && _selectedProduct != null;
    final formattedQty =
        _selectedQuantity.truncateToDouble() == _selectedQuantity
        ? _selectedQuantity.toInt().toString()
        : _selectedQuantity.toStringAsFixed(2);
    final totalCost =
        (_selectedProduct?.averageCost ?? 0.0) * _selectedQuantity;
    final formattedTotal = CurrencyFormatter.format(totalCost);
    final uom = _selectedProduct?.uomModel?.symbol ?? 'ud.';

    return Scaffold(
      appBar: const StandardAppBar(title: 'Agregar producto'),
      body: Column(
        children: [
          // Search Bar (Read Only)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: CustomSearchBar(
              readOnly: true,
              showFilterIcon: true,
              hintText: 'Buscar producto...',
              onTap: () {
                context.push('/my-purchases/add/select-product/search');
              },
            ),
          ),

          // Sort Selector
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                SortSelector(
                  currentSort: _currentSort,
                  onSortChanged: (val) {
                    setState(() {
                      _currentSort = val;
                      _selectedProductId = null;
                      _selectedProduct = null;
                      _selectedQuantity = 0.0;
                    });
                    String orderBy = 'created_at';
                    bool ascending = false;
                    if (val == SortOption.nameAZ) {
                      orderBy = 'name';
                      ascending = true;
                    } else if (val == SortOption.nameZA) {
                      orderBy = 'name';
                      ascending = false;
                    } else if (val == SortOption.recent) {
                      orderBy = 'created_at';
                      ascending = false;
                    }
                    ref
                        .read(paginatedProductsProvider.notifier)
                        .updateSort(orderBy, ascending);
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

          // Product List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _selectedProductId = null;
                  _selectedProduct = null;
                  _selectedQuantity = 0.0;
                });
                return ref.refresh(paginatedProductsProvider.future);
              },
              child: paginatedAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => FriendlyErrorWidget(
                  error: error,
                  onRetry: () => ref.refresh(paginatedProductsProvider.future),
                ),
                data: (state) {
                  if (state.items.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay productos registrados',
                        style: TextStyle(color: colors.outline),
                      ),
                    );
                  }

                  final addedProducts = ref.watch(addPurchaseProvider).products;

                  return PaginatedListView<Product>(
                    items: state.items,
                    isLoadingMore: state.isLoadingMore,
                    hasReachedEnd: state.hasReachedEnd,
                    onLoadMore: () =>
                        ref.read(paginatedProductsProvider.notifier).loadMore(),
                    padding: const EdgeInsets.only(bottom: 100),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Colors.transparent),
                    itemBuilder: (context, index, product) {
                      final isAlreadyAdded = addedProducts.any(
                        (p) => p.productId == product.id,
                      );
                      final isThisSelected = _selectedProductId == product.id;
                      final currentQty =
                          isThisSelected ? _selectedQuantity : 0.0;
                      final isLocked =
                          _selectedProductId != null &&
                          _selectedProductId != product.id;

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
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
                          context.pop(); // Pop back to Add Purchase screen
                        }
                      }
                    } else {
                      if (context.mounted) {
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
          : Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: CustomExtendedFab(
                onPressed: () {
                  context.push('/portfolio/own-inventory/add');
                },
                label: 'Nuevo',
                icon: Icons.add,
              ),
            ),
    );
  }
}
