import 'package:d_una_app/shared/widgets/info_disclaimer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../shared/widgets/aggregated_product_card.dart';
import '../../../../../shared/widgets/friendly_error_widget.dart';
import '../providers/create_supplier_order_provider.dart';
import '../providers/supplier_order_product_selection_provider.dart';

class SelectSupplierOrderProductScreen extends ConsumerStatefulWidget {
  const SelectSupplierOrderProductScreen({super.key});

  @override
  ConsumerState<SelectSupplierOrderProductScreen> createState() =>
      _SelectSupplierOrderProductScreenState();
}

class _SelectSupplierOrderProductScreenState
    extends ConsumerState<SelectSupplierOrderProductScreen> {
  SortOption _currentSort = SortOption.recent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final orderState = ref.watch(createSupplierOrderProvider);
    final supplierId = orderState.supplierId ?? '';
    final orderNumber = orderState.currentOrderNumber ?? '';
    final orderItems = orderState.items;

    final suggestionsAsync = ref.watch(
      supplierOrderProductSuggestionsProvider(supplierId: supplierId),
    );

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Agregar producto',
        subtitle: 'Orden de Compra #$orderNumber',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar (Read-only -> Navigates to Search)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: InkWell(
              onTap: () {
                context
                    .push('/supplier-orders/create/select-product/search')
                    .then((result) {
                      if (result == true) {
                        if (context.mounted) {
                          context.pop(true);
                        }
                      }
                    });
              },
              borderRadius: BorderRadius.circular(12),
              child: IgnorePointer(
                child: CustomSearchBar(
                  hintText: 'Buscar producto...',
                  onChanged: (_) {},
                  readOnly: true,
                  showFilterIcon: true,
                ),
              ),
            ),
          ),

          // 2. Disclaimer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const InfoDisclaimerCard(
              text: 'MPD: Menor precio disponible.',
              showCloseButton: true,
              askDismissForever: true,
              dismissKey: 'disclaimer_mpd',
            ),
          ),

          // 3. Sort Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SortSelector(
                  currentSort: _currentSort,
                  onSortChanged: (val) => setState(() => _currentSort = val),
                  options: const [
                    SortOption.recent,
                    SortOption.nameAZ,
                    SortOption.nameZA,
                  ],
                ),
              ],
            ),
          ),

          // 4. List
          Expanded(
            child: suggestionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => FriendlyErrorWidget(error: err),
              data: (products) {
                // Determine sort list
                final sortedProducts = List.of(products);
                sortedProducts.sort((a, b) {
                  switch (_currentSort) {
                    case SortOption.nameAZ:
                      return a.name.toLowerCase().compareTo(
                        b.name.toLowerCase(),
                      );
                    case SortOption.nameZA:
                      return b.name.toLowerCase().compareTo(
                        a.name.toLowerCase(),
                      );
                    default:
                      return 0; // standard order
                  }
                });

                if (sortedProducts.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay sugerencias disponibles',
                      style: TextStyle(color: colors.outline),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: sortedProducts.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Colors.transparent),
                  itemBuilder: (context, index) {
                    final product = sortedProducts[index];
                    final isAlreadyInOrder = orderItems.any(
                      (item) =>
                          (item.brand ?? '').trim().toUpperCase() ==
                              product.brand.trim().toUpperCase() &&
                          (item.model ?? '').trim().toUpperCase() ==
                              product.model.trim().toUpperCase() &&
                          item.uom.trim().toUpperCase() ==
                              product.uom.trim().toUpperCase(),
                    );

                    return AggregatedProductCard(
                      name: product.name,
                      brand: product.brand,
                      model: product.model,
                      minPrice: product.minPrice,
                      totalQuantity: product.totalQuantity,
                      supplierCount: product.supplierCount,
                      uom: product.uom,
                      uomIconName: product.uomIconName,
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
