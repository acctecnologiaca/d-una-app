import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/create_quote_provider.dart';
import '../../../domain/models/quote_aggregated_product.dart';
import '../../../data/models/quote_item_product.dart';
import '../widgets/quote_added_product_card.dart';
import '../widgets/quote_product_sale_details_sheet.dart';
import '../providers/quote_validation_provider.dart';

class QuoteProductsTab extends ConsumerStatefulWidget {
  const QuoteProductsTab({super.key});

  @override
  ConsumerState<QuoteProductsTab> createState() => _QuoteProductsTabState();
}

class _QuoteProductsTabState extends ConsumerState<QuoteProductsTab>
    with AutomaticKeepAliveClientMixin {
  bool _showRefreshHint = true;
  Timer? _hintTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Trigger validation once on entering the tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quoteValidationProvider(null).notifier).startValidation();
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(createQuoteProvider);
    final validationState = ref.watch(quoteValidationProvider(null));

    // Si hay productos pero no hay datos de validación (probablemente porque se cargaron asíncronamente
    // después del initState), disparamos la validación.
    final needsInitialValidation =
        state.products.isNotEmpty &&
        !validationState.isValidating &&
        validationState.items.isEmpty;

    if (needsInitialValidation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Ignorar si el widget ya no está montado
        if (!mounted) return;
        ref.read(quoteValidationProvider(null).notifier).startValidation();
      });
    }

    // Mostrar pantalla de carga si estamos en la validación inicial
    if (state.products.isNotEmpty &&
        (validationState.isValidating || needsInitialValidation) &&
        validationState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Sincronizando inventario...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (state.products.isNotEmpty && _showRefreshHint && _hintTimer == null) {
      _hintTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _showRefreshHint = false);
        }
      });
    }

    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.package_2,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos agregados',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final groupedProducts = <int, List<QuoteItemProduct>>{};
    for (var product in state.products) {
      if (!groupedProducts.containsKey(product.groupIndex)) {
        groupedProducts[product.groupIndex] = [];
      }
      groupedProducts[product.groupIndex]!.add(product);
    }

    final sortedIndices = groupedProducts.keys.toList()..sort();

    return Column(
      children: [
        if (validationState.isValidating)
          const LinearProgressIndicator(minHeight: 2)
        else
          const SizedBox(height: 2),
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: _showRefreshHint
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    'Desliza hacia abajo para actualizar cambios de stock y precios de proveedores',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(quoteValidationProvider(null).notifier).validate(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: sortedIndices.length,
              itemBuilder: (context, index) {
                final groupIndex = sortedIndices[index];
                final items = groupedProducts[groupIndex]!;
                final firstItem = items.first;
                final groupName = firstItem.name;

                double totalQuantity = 0;
                double totalAvailableStock = 0;
                double totalCost = 0;
                double subtotal = 0;

                for (var item in items) {
                  totalQuantity += item.quantity;
                  totalCost += item.costPrice * item.quantity;
                  subtotal += item.unitPrice * item.quantity;
                }

                double averageCost = totalQuantity > 0
                    ? totalCost / totalQuantity
                    : firstItem.costPrice;

                final bool hasOwnInventory = items.any(
                  (i) => i.sourceType == QuoteItemSourceType.own,
                );
                final bool hasSupplierInventory = items.any(
                  (i) => i.sourceType == QuoteItemSourceType.affiliated,
                );
                final bool isTemporal =
                    firstItem.sourceType == QuoteItemSourceType.temporal;
                final bool isExternalManagement = items.any(
                  (i) => i.sourceType == QuoteItemSourceType.external,
                );

                // Determine group validation status and fresh stock
                final Set<QuoteValidationStatus> groupAlerts = {};

                if (!isTemporal) {
                  for (var item in items) {
                    if (item.sourceType == QuoteItemSourceType.external) {
                      // Tope rígido: Solo permitimos incrementar hasta la cantidad externa que
                      // ya fue negociada (item.quantity).
                      totalAvailableStock += item.quantity;
                    } else {
                      final vInfo = validationState.items[item.id];
                      if (vInfo != null) {
                        totalAvailableStock += vInfo.currentStock;
                      } else {
                        totalAvailableStock +=
                            item.availableStock ?? double.infinity;
                      }
                    }

                    // Collect alerts
                    final vInfo = validationState.items[item.id];
                    if (vInfo != null &&
                        vInfo.status != QuoteValidationStatus.ok) {
                      groupAlerts.add(vInfo.status);
                    }
                  }
                } else {
                  // Es un grupo puramente temporal. Debe permitir incrementos infinitos en el stepper.
                  totalAvailableStock += 999999;
                }

                return QuoteAddedProductCard(
                  name: groupName,
                  brand: firstItem.brand,
                  model: firstItem.model,
                  uom: firstItem.uom,
                  uomIconName: firstItem.uomIconName,
                  subtotal: subtotal,
                  totalQuantity: totalQuantity,
                  totalAvailableStock: totalAvailableStock,
                  hasOwnInventory: hasOwnInventory,
                  hasSupplierInventory: hasSupplierInventory,
                  isTemporal: isTemporal,
                  isExternalManagement: isExternalManagement,
                  onDelete: () {
                    ref
                        .read(createQuoteProvider.notifier)
                        .removeProductGroup(groupIndex);
                  },
                  onEditPrice: () async {
                    final result = await QuoteProductSaleDetailsSheet.show(
                      context,
                      averageCost: averageCost,
                      productName: groupName,
                      uom: firstItem.uom,
                      brand: firstItem.brand,
                      model: firstItem.model,
                      initialPrice: firstItem.unitPrice,
                      initialMargin: firstItem.profitMargin,
                      initialDeliveryTimeId: firstItem.deliveryTimeId,
                    );
                    if (result != null) {
                      final newPrice = result['sellingPrice'] as double;
                      final newMargin = result['profitMargin'] as double;
                      final newDeliveryTimeId =
                          result['deliveryTimeId'] as String?;
                      ref
                          .read(createQuoteProvider.notifier)
                          .updateGroupPrice(
                            groupIndex,
                            newPrice,
                            newMargin,
                            newDeliveryTimeId,
                          );
                    }
                  },
                  onEditSources: () {
                    // Build the initial selections map
                    final Map<String, double> initialSelections = {};
                    final Map<String, double> initialCostPrices = {};
                    double? externalCostPrice;
                    String? externalProviderName;

                    for (var item in items) {
                      final isExternal =
                          item.sourceType == QuoteItemSourceType.external;
                      final sourceId = isExternal
                          ? 'external-management'
                          : (item.supplierBranchStockId ?? item.productId);

                      if (sourceId != null) {
                        initialSelections[sourceId] = item.quantity;
                        initialCostPrices[sourceId] = item.costPrice;
                        if (isExternal) {
                          externalCostPrice = item.costPrice;
                          externalProviderName = item.externalProviderName;
                        }
                      }
                    }

                    // Construct a QuoteAggregatedProduct to pass to sources screen
                    final productObj = QuoteAggregatedProduct(
                      name: groupName,
                      brand: firstItem.brand ?? '',
                      model: firstItem.model ?? '',
                      uom: firstItem.uom,
                      uomIconName: firstItem.uomIconName ?? 'package_2',
                      minPrice: firstItem.costPrice,
                      totalQuantity: totalAvailableStock,
                      supplierCount: items.length,
                      hasOwnInventory: items.any((i) => i.productId != null),
                      frequencyScore: 0,
                      lastAddedAt: DateTime.now(),
                      category: '',
                      sources: [],
                    );
                    context.push(
                      '/quotes/create/select-product/product-sources',
                      extra: {
                        'product': productObj,
                        'initialSelections': initialSelections,
                        'initialCostPrices': initialCostPrices,
                        'externalCostPrice': externalCostPrice,
                        'externalProviderName': externalProviderName,
                        'groupIndex': groupIndex,
                      },
                    );
                  },
                  onEditTemporal: isTemporal
                      ? () async {
                          await context.push<bool>(
                            '/quotes/create/select-product/temporal-product',
                            extra: firstItem,
                          );
                        }
                      : null,
                  onQuantityChanged: (newQty) {
                    ref
                        .read(createQuoteProvider.notifier)
                        .updateGroupQuantity(groupIndex, newQty);
                  },
                  alerts: groupAlerts.toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
