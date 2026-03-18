import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/purchase_product_list_item.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_product_details_sheet.dart';

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
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: const StandardAppBar(
        title: 'Agregar producto',
      ),
      body: Column(
        children: [
          // Search Bar (Read Only)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

          // Products List
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Text(
                      'No tienes productos registrados',
                      style: TextStyle(color: colors.outline),
                    ),
                  );
                }

                // Apply Sort
                final sortedList = List.from(products);
                sortedList.sort((a, b) {
                  switch (_currentSort) {
                    case SortOption.recent:
                      return b.createdAt.compareTo(a.createdAt);
                    case SortOption.nameAZ:
                      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                    case SortOption.nameZA:
                      return b.name.toLowerCase().compareTo(a.name.toLowerCase());
                    default:
                      return 0;
                  }
                });

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: sortedList.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = sortedList[index];
                    return PurchaseProductListItem(
                      brand: product.brand?.name ?? 'Sin marca',
                      name: product.name,
                      model: product.model ?? 'Sin modelo',
                      uom: product.uomModel,
                      imageUrl: product.imageUrl,
                      onTap: () async {
                        final result = await AddPurchaseProductDetailsSheet.show(
                          context,
                          product: product,
                        );
                        if (result != null) {
                          // TODO: Append this product with its details to the current purchase draft.
                          debugPrint('Product details picked: $result');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Producto agregado: ${product.name}'),
                            ),
                          );
                          // Optionally, navigate back if we want to return directly after choosing one product:
                          // context.pop();
                        }
                      },
                    );
                  },
                );
              },
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
