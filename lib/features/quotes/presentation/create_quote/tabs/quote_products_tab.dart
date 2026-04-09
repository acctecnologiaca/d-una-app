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
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Trigger validation once on entering the tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quoteValidationProvider.notifier).startValidation();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(createQuoteProvider);
    final validationState = ref.watch(quoteValidationProvider);

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

    final groupedProducts = <String, List<QuoteItemProduct>>{};
    for (var product in state.products) {
      if (!groupedProducts.containsKey(product.name)) {
        groupedProducts[product.name] = [];
      }
      groupedProducts[product.name]!.add(product);
    }

    return Column(
      children: [
        if (validationState.isValidating)
          const LinearProgressIndicator(minHeight: 2)
        else
          const SizedBox(height: 2),

        // Header with Refresh Action
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              /*Text(
                'Productos en cotización',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),*/
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Symbols.refresh, size: 20),
                onPressed: () => ref
                    .read(quoteValidationProvider.notifier)
                    .startValidation(),
                tooltip: 'Sincronizar disponibilidad',
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            itemCount: groupedProducts.length,
            itemBuilder: (context, index) {
              final groupName = groupedProducts.keys.elementAt(index);
              final items = groupedProducts[groupName]!;
              final firstItem = items.first;

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
                (i) => i.productId != null && !i.isTemporal,
              );
              final bool hasSupplierInventory = items.any(
                (i) => i.supplierProductId != null,
              );
              final bool isTemporal = firstItem.isTemporal;
              final bool isExternalManagement = items.any(
                (i) => i.availableStock == -1.0,
              );

              // Determine group validation status and fresh stock
              QuoteValidationStatus? groupStatus;
              String? validationMessage;

              if (!isTemporal) {
                for (var item in items) {
                  if (item.availableStock == -1.0) {
                    totalAvailableStock += item.quantity;
                    continue;
                  }
                  final vInfo = validationState.items[item.id];
                  // SYNC: Use fresh stock from validation if available
                  if (vInfo != null) {
                    totalAvailableStock += vInfo.currentStock;
                  } else if (item.availableStock == -1.0) {
                    // External management: treat as unlimited
                    totalAvailableStock += item.quantity;
                  } else {
                    totalAvailableStock +=
                        item.availableStock ?? double.infinity;
                  }

                  if (vInfo != null &&
                      vInfo.status != QuoteValidationStatus.ok) {
                    // Prioritize outOfStock > lowStock > priceIncreased
                    if (groupStatus == null ||
                        vInfo.status == QuoteValidationStatus.outOfStock ||
                        (groupStatus != QuoteValidationStatus.outOfStock &&
                            vInfo.status == QuoteValidationStatus.lowStock)) {
                      groupStatus = vInfo.status;

                      switch (groupStatus) {
                        case QuoteValidationStatus.outOfStock:
                          validationMessage = 'Sin stock disponible';
                          break;
                        case QuoteValidationStatus.lowStock:
                          final diff = (item.quantity - vInfo.currentStock)
                              .toInt();
                          validationMessage = 'Faltan $diff unidades por stock';
                          break;
                        case QuoteValidationStatus.priceIncreased:
                          validationMessage = 'El precio de costo aumentó';
                          break;
                        case QuoteValidationStatus.missing:
                          validationMessage = 'Producto ya no disponible';
                          break;
                        default:
                          break;
                      }
                    }
                  }
                }
              } else {
                totalAvailableStock =
                    99999; // Temporal products always have "infinite" stock
              }

              return QuoteAddedProductCard(
                name: groupName,
                brand: firstItem.brand,
                model: firstItem.model,
                uom: firstItem.uom,
                subtotal: subtotal,
                totalQuantity: totalQuantity,
                totalAvailableStock: isTemporal ? 999999 : totalAvailableStock,
                hasOwnInventory: hasOwnInventory,
                hasSupplierInventory: hasSupplierInventory,
                isTemporal: isTemporal,
                isExternalManagement: isExternalManagement,
                onDelete: () {
                  ref
                      .read(createQuoteProvider.notifier)
                      .removeProductGroup(groupName);
                },
                onEditPrice: () async {
                  final result = await QuoteProductSaleDetailsSheet.show(
                    context,
                    averageCost: averageCost,
                    productName: groupName,
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
                          groupName,
                          newPrice,
                          newMargin,
                          newDeliveryTimeId,
                        );
                  }
                },
                onEditSources: () {
                  // Build the initial selections map
                  final Map<String, double> initialSelections = {};
                  double? externalCostPrice;

                  for (var item in items) {
                    final isExternal = item.availableStock == -1.0;
                    final sourceId = isExternal
                        ? 'external-management'
                        : (item.supplierProductId ?? item.productId);

                    if (sourceId != null) {
                      initialSelections[sourceId] = item.quantity;
                      if (isExternal) {
                        externalCostPrice = item.costPrice;
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
                      'externalCostPrice': externalCostPrice,
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
                      .updateGroupQuantity(groupName, newQty);
                },
                validationStatus: groupStatus,
                validationMessage: validationMessage,
              );
            },
          ),
        ),
      ],
    );
  }
}
