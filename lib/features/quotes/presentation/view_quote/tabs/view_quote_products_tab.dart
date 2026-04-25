import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/view_quote_provider.dart';
import '../../create_quote/widgets/quote_added_product_card.dart';

class ViewQuoteProductsTab extends ConsumerWidget {
  final String quoteId;
  const ViewQuoteProductsTab({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(viewQuoteProvider(quoteId));

    if (state.isLoading && state.quote == null) {
      return const Center(child: CircularProgressIndicator());
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
              'No hay productos en esta cotización',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final groupedProducts = <String, List<dynamic>>{};
    for (var product in state.products) {
      if (!groupedProducts.containsKey(product.name)) {
        groupedProducts[product.name] = [];
      }
      groupedProducts[product.name]!.add(product);
    }

    return ListView.builder(
      itemCount: groupedProducts.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final groupName = groupedProducts.keys.elementAt(index);
        final items = groupedProducts[groupName]!;
        final firstItem = items.first;

        double totalQuantity = 0;
        double totalAvailableStock = 0;
        double subtotal = 0;

        for (var item in items) {
          totalQuantity += item.quantity;
          subtotal += item.unitPrice * item.quantity;
          totalAvailableStock += item.availableStock ?? 0;
        }

        final bool hasOwnInventory = items.any(
          (i) => i.productId != null && !i.isTemporal,
        );
        final bool hasSupplierInventory = items.any(
          (i) => i.supplierBranchStockId != null,
        );
        final bool isTemporal = firstItem.isTemporal;
        final bool isExternalManagement = items.any(
          (i) => i.availableStock == -1.0,
        );

        return QuoteAddedProductCard(
          name: groupName,
          brand: firstItem.brand,
          model: firstItem.model,
          uom: firstItem.uom,
          subtotal: subtotal,
          totalQuantity: totalQuantity,
          totalAvailableStock: totalAvailableStock,
          hasOwnInventory: hasOwnInventory,
          hasSupplierInventory: hasSupplierInventory,
          isTemporal: isTemporal,
          isExternalManagement: isExternalManagement,
          isReadOnly: true,
          onDelete: () {},
          onEditPrice: () {},
          onEditSources: () {},
          onQuantityChanged: (_) {},
        );
      },
    );
  }
}
