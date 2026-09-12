import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:d_una_app/shared/widgets/generic_search_screen.dart';
import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:d_una_app/shared/widgets/filter_bottom_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/features/portfolio/data/models/category_model.dart';
import 'package:d_una_app/features/portfolio/data/models/brand_model.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';
import 'package:d_una_app/core/utils/search_utils.dart';
import 'package:d_una_app/features/delivery_notes/domain/models/delivery_note_item_model.dart';
import 'package:d_una_app/features/delivery_notes/presentation/manage_serials/screens/delivery_note_manage_serials_screen.dart';
import 'package:d_una_app/features/delivery_notes/presentation/create_delivery_note/providers/create_delivery_note_provider.dart';
import 'package:d_una_app/features/delivery_notes/presentation/create_delivery_note/widgets/delivery_note_product_selection_card.dart';
import 'package:d_una_app/features/delivery_notes/presentation/create_delivery_note/widgets/delivery_note_product_details_sheet.dart';
import 'package:d_una_app/features/delivery_notes/presentation/create_delivery_note/widgets/delivery_note_register_serials_dialog.dart';

class DeliveryNoteProductSearchScreen extends ConsumerStatefulWidget {
  const DeliveryNoteProductSearchScreen({super.key});

  @override
  ConsumerState<DeliveryNoteProductSearchScreen> createState() =>
      _DeliveryNoteProductSearchScreenState();
}

class _DeliveryNoteProductSearchScreenState
    extends ConsumerState<DeliveryNoteProductSearchScreen> {
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

    // Categorías derivadas
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final categoryMap = queryMatchedProducts
        .map((p) => p.category)
        .whereType<Category>()
        .where((cat) => cat.isVerified || (currentUserId != null && cat.userId == currentUserId))
        .fold<Map<String, String>>({}, (map, cat) {
          map[cat.id] = cat.name.toTitleCase;
          return map;
        });

    // Marcas derivadas
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
    final uom = _selectedProduct?.uom ?? _selectedProduct?.uomModel?.symbol ?? 'Ud';

    return GenericSearchScreen<Product>(
      title: 'Buscar producto',
      hintText: 'Nombre, marca o modelo...',
      historyKey: 'delivery_note_product_selection_search_history',
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
        final currentItems = ref.watch(createDeliveryNoteProvider).items;
        final isAlreadyAdded = currentItems.any(
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
                        Navigator.of(context).pop(); // Pop search
                        Navigator.of(context).pop(); // Pop select
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Pop search
                        Navigator.of(context).pop(); // Pop select
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
