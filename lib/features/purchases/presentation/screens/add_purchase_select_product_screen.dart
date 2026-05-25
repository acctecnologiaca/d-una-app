import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import 'package:d_una_app/shared/widgets/paginated_list_view.dart';
import 'package:d_una_app/shared/models/paginated_state.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/features/purchases/data/models/purchase_item_product.dart';
import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/purchase_product_list_item.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_product_details_sheet.dart';
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final paginatedAsync = ref.watch(paginatedProductsProvider);

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
                    setState(() => _currentSort = val);
                    String orderBy = 'created_at';
                    bool ascending = false;
                    if (val == SortOption.nameAZ) {
                      orderBy = 'name';
                      ascending = true;
                    } else if (val == SortOption.nameZA) {
                      orderBy = 'name';
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

          // Products List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(paginatedProductsProvider.notifier).refresh();
              },
              child: Builder(
                builder: (context) {
                  final state =
                      paginatedAsync.valueOrNull ??
                      const PaginatedState<Product>();

                  if (paginatedAsync.hasError && state.items.isEmpty) {
                    return FriendlyErrorWidget(
                      error: paginatedAsync.error!,
                      onRetry: () => ref
                          .read(paginatedProductsProvider.notifier)
                          .refresh(),
                    );
                  }

                  if (paginatedAsync.isLoading && state.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.items.isEmpty) {
                    return Center(
                      child: Text(
                        'No tienes productos registrados',
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

                      return PurchaseProductListItem(
                        brand: product.brand?.name ?? 'Sin marca',
                        name: product.name,
                        model: product.model ?? 'Sin modelo',
                        uom: product.uomModel,
                        imageUrl: product.imageUrl,
                        enabled: !isAlreadyAdded,
                        onDisabledTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'El producto "${product.name}" ya está agregado. Si deseas agregar más unidades, por favor modifica el ya existente.',
                              ),
                            ),
                          );
                        },
                        onTap: () async {
                          final result =
                              await AddPurchaseProductDetailsSheet.show(
                                context,
                                product: product,
                              );
                          if (result != null) {
                            final qty = (result['quantity'] as num).toDouble();
                            final cost = (result['cost_price'] as num)
                                .toDouble();
                            final wTime = (result['warranty_duration'] as num)
                                .toInt();
                            final wPeriodStr =
                                result['warranty_period'] as String;
                            final usesSerials = result['uses_serials'] == true;

                            // Map period to DB value
                            final wUnit = wPeriodStr == 'Días'
                                ? 'days'
                                : wPeriodStr == 'Meses'
                                ? 'months'
                                : 'years';

                            final item = PurchaseItemProduct(
                              id: const Uuid().v4(),
                              productId: product.id,
                              name: product.name,
                              brand: product.brand?.name,
                              model: product.model,
                              uom: product.uomModel?.symbol ?? 'ud.',
                              quantity: qty,
                              unitPrice: cost,
                              warrantyTime: wTime,
                              warrantyUnit: wUnit,
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
                                      'El producto "${product.name}" ya está agregado.',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            final bool registerNow =
                                result['register_serials_now'] == true;
                            if (registerNow) {
                              if (context.mounted) {
                                final confirmed = await context.push<bool>(
                                  '/my-purchases/add/select-product/manage-serials',
                                  extra: <String, dynamic>{
                                    'product': product,
                                    'quantity': qty.toInt(),
                                    'purchaseItemId': item.id,
                                  },
                                );
                                if (confirmed == true && context.mounted) {
                                  context
                                      .pop(); // Pop back to Add Purchase screen
                                }
                              }
                            } else {
                              if (context.mounted) {
                                context
                                    .pop(); // Pop back to Add Purchase screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Producto agregado: ${product.name}',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
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
      floatingActionButton: Padding(
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
