import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/paginated_list_view.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/utils/fab_scroll_padding.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import 'package:d_una_app/features/delivery_notes/domain/models/delivery_note_item_model.dart';
import 'package:d_una_app/features/delivery_notes/presentation/manage_serials/screens/delivery_note_manage_serials_screen.dart';
import 'package:d_una_app/features/delivery_notes/presentation/create_delivery_note/providers/create_delivery_note_provider.dart';
import 'package:d_una_app/features/delivery_notes/presentation/create_delivery_note/widgets/delivery_note_product_selection_card.dart';
import 'package:d_una_app/features/delivery_notes/presentation/create_delivery_note/widgets/delivery_note_product_details_sheet.dart';
import 'package:d_una_app/features/delivery_notes/presentation/create_delivery_note/widgets/delivery_note_register_serials_dialog.dart';
import 'package:d_una_app/features/delivery_notes/presentation/create_delivery_note/screens/delivery_note_product_search_screen.dart';

class SelectDeliveryNoteProductScreen extends ConsumerStatefulWidget {
  const SelectDeliveryNoteProductScreen({super.key});

  @override
  ConsumerState<SelectDeliveryNoteProductScreen> createState() =>
      _SelectDeliveryNoteProductScreenState();
}

class _SelectDeliveryNoteProductScreenState
    extends ConsumerState<SelectDeliveryNoteProductScreen> {
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
    final uom = _selectedProduct?.uom ?? _selectedProduct?.uomModel?.symbol ?? 'Ud';

    return Scaffold(
      appBar: const StandardAppBar(title: 'Agregar producto'),
      body: SafeArea(
        child: Column(
        children: [
          // 1. Buscador (Read-Only que navega a búsqueda avanzada)
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DeliveryNoteProductSearchScreen(),
                  ),
                );
              },
            ),
          ),

          // 2. Selector de Ordenamiento
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                SortSelector(
                  currentSort: _currentSort,
                  options: const [
                    SortOption.recent,
                    SortOption.nameAZ,
                    SortOption.nameZA,
                  ],
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
                ),
              ],
            ),
          ),

          // 3. Lista de Productos
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
                error: (error, _) => FriendlyErrorWidget(
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

                  final addedItems = ref.watch(createDeliveryNoteProvider).items;

                  return PaginatedListView<Product>(
                    items: state.items,
                    isLoadingMore: state.isLoadingMore,
                    hasReachedEnd: state.hasReachedEnd,
                    onLoadMore: () =>
                        ref.read(paginatedProductsProvider.notifier).loadMore(),
                    padding: const EdgeInsets.only(bottom: FabScrollPadding.list),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Colors.transparent),
                    itemBuilder: (context, index, product) {
                      final isAlreadyAdded = addedItems.any(
                        (p) => p.productId == product.id,
                      );
                      final isThisSelected = _selectedProductId == product.id;
                      final currentQty = isThisSelected ? _selectedQuantity : 0.0;
                      final isLocked =
                          _selectedProductId != null && _selectedProductId != product.id;

                      return DeliveryNoteProductSelectionCard(
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: CustomExtendedFab(
        icon: Icons.check,
        label: hasSelection
            ? 'Confirmar ($formattedQty $uom)'
            : 'Confirmar',
        isEnabled: hasSelection,
        onPressed: hasSelection
            ? () async {
                if (_selectedProduct == null || _selectedQuantity <= 0) {
                  return;
                }

                  if (_selectedQuantity > _selectedProduct!.availableQuantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La cantidad excede el stock disponible en inventario.'),
                      ),
                    );
                    return;
                  }

                  final result = await DeliveryNoteProductDetailsSheet.show(
                    context,
                    product: _selectedProduct!,
                  );

                  if (result != null && context.mounted) {
                    final hasWarranty = result['has_warranty'] as bool;
                    final wTime = (result['warranty_duration'] as num).toInt();
                    final wPeriodStr = result['warranty_period'] as String;
                    bool usesSerials = result['uses_serials'] == true;
                    final bool needsToAsk =
                        result['needs_to_ask_serials'] == true;

                    bool registerSerialsNow = false;

                    if (needsToAsk && context.mounted) {
                      final dialogResult =
                          await DeliveryNoteRegisterSerialsDialog.show(context);
                      if (dialogResult == null) return;
                      switch (dialogResult) {
                        case DeliveryNoteRegisterSerialsResult.now:
                          registerSerialsNow = true;
                          break;
                        case DeliveryNoteRegisterSerialsResult.later:
                          registerSerialsNow = false;
                          break;
                        case DeliveryNoteRegisterSerialsResult.never:
                          usesSerials = false;
                          registerSerialsNow = false;
                          break;
                      }
                    }

                    final wUnit = wPeriodStr == 'Días'
                        ? 'days'
                        : wPeriodStr == 'Meses'
                            ? 'months'
                            : 'years';

                    final item = DeliveryNoteItemModel(
                      id: const Uuid().v4(),
                      deliveryNoteId: '',
                      productId: _selectedProduct!.id,
                      name: _selectedProduct!.name,
                      brand: _selectedProduct!.brand?.name,
                      model: _selectedProduct!.model,
                      uom: _selectedProduct!.uom ??
                          _selectedProduct!.uomModel?.symbol ??
                          'Ud',
                      description: _selectedProduct!.specs,
                      quantity: _selectedQuantity,
                      unitPrice: 0.0,
                      totalPrice: 0.0,
                      orderIndex: ref
                          .read(createDeliveryNoteProvider)
                          .items
                          .length,
                      warrantyTime: hasWarranty ? wTime : null,
                      warrantyUnit: hasWarranty ? wUnit : null,
                      requiresSerials: usesSerials,
                      serials: const [],
                    );

                    final currentItems =
                        ref.read(createDeliveryNoteProvider).items;
                    if (currentItems.any((i) => i.productId == item.productId)) {
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

                    ref
                        .read(createDeliveryNoteProvider.notifier)
                        .addItem(item);

                    if (registerSerialsNow && context.mounted) {
                      final itemIndex = ref
                              .read(createDeliveryNoteProvider)
                              .items
                              .length -
                          1;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DeliveryNoteManageSerialsScreen(
                            item: item,
                            onSerialsSaved: (serials) {
                              ref
                                  .read(createDeliveryNoteProvider.notifier)
                                  .updateItemSerials(itemIndex, serials);
                            },
                          ),
                        ),
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Return to wizard
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Return to wizard
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
                }
              : null,
      ),
    );
  }
}
