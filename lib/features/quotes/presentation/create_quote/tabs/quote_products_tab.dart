import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/create_quote_provider.dart';
import '../../../domain/models/quote_aggregated_product.dart';
import '../../../data/models/quote_item_product.dart';
import '../widgets/quote_added_product_card.dart';
import '../widgets/quote_product_sale_details_sheet.dart';

class QuoteProductsTab extends ConsumerWidget {
  const QuoteProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createQuoteProvider);

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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          totalAvailableStock += item.availableStock ?? double.infinity;
          totalCost += item.costPrice * item.quantity;
          subtotal += item.unitPrice * item.quantity;
        }

        double averageCost = totalQuantity > 0
            ? totalCost / totalQuantity
            : firstItem.costPrice;

        final bool isTemporal = firstItem.isTemporal;

        return QuoteAddedProductCard(
          name: groupName,
          brand: firstItem.brand,
          model: firstItem.model,
          uom: firstItem.uom,
          subtotal: subtotal,
          totalQuantity: totalQuantity,
          totalAvailableStock: isTemporal ? 99999 : totalAvailableStock,
          isTemporal: isTemporal,
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
            );
            if (result != null) {
              final newPrice = result['sellingPrice'] as double;
              final newMargin = result['profitMargin'] as double;
              ref
                  .read(createQuoteProvider.notifier)
                  .updateGroupPrice(groupName, newPrice, newMargin);
            }
          },
          onEditSources: () {
            // Build the initial selections map
            final Map<String, double> initialSelections = {};
            for (var item in items) {
              final sourceId = item.supplierProductId ?? item.productId;
              if (sourceId != null) {
                initialSelections[sourceId] = item.quantity;
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
        );
      },
    );
  }
}
