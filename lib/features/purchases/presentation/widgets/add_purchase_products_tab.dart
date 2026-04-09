import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_product_details_sheet.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/purchase_added_product_card.dart';
import 'package:go_router/go_router.dart';

class AddPurchaseProductsTab extends ConsumerWidget {
  const AddPurchaseProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPurchaseProvider);
    final colors = Theme.of(context).colorScheme;

    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.package_2,
              size: 64,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos agregados',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final productsAsync = ref.watch(productsProvider);
    final allProducts = productsAsync.value ?? [];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.products.length,
      itemBuilder: (context, index) {
        final item = state.products[index];
        final product = allProducts.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => Product(
            id: item.productId,
            userId: '',
            name: item.name,
            uomModel: null,
            brand: null,
            model: item.model,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final hasMissingSerials =
            item.requiresSerials &&
            state.serials.where((s) => s.productId == item.productId).length <
                item.quantity;

        return PurchaseAddedProductCard(
          item: item,
          hasError: hasMissingSerials,
          onDelete: () {
            ref
                .read(addPurchaseProvider.notifier)
                .removeProduct(item.productId);
          },
          onEdit: () async {
            final result = await AddPurchaseProductDetailsSheet.show(
              context,
              product: product,
              existingItem: item,
            );

            if (result != null) {
              final qty = (result['quantity'] as num).toDouble();
              final cost = (result['cost_price'] as num).toDouble();
              final wTime = (result['warranty_duration'] as num).toInt();
              final wPeriodStr = result['warranty_period'] as String;
              final usesSerials = result['uses_serials'] == true;

              final wUnit = wPeriodStr == 'Días'
                  ? 'days'
                  : wPeriodStr == 'Meses'
                  ? 'months'
                  : 'years';

              final updatedItem = item.copyWith(
                quantity: qty,
                unitPrice: cost,
                warrantyTime: wTime,
                warrantyUnit: wUnit,
                requiresSerials: usesSerials,
              );

              ref.read(addPurchaseProvider.notifier).updateProduct(updatedItem);

              // If user selected "Register Now", navigate to serials
              if (result['register_serials_now'] == true) {
                if (context.mounted) {
                  context.push(
                    '/my-purchases/add/select-product/manage-serials',
                    extra: <String, dynamic>{
                      'product': product,
                      'quantity': qty.toInt(),
                      'purchaseItemId': item.id,
                    },
                  );
                }
              }
            }
          },
          onAddSerials: () {
            context.push(
              '/my-purchases/add/select-product/manage-serials',
              extra: <String, dynamic>{
                'product': product,
                'quantity': item.quantity.toInt(),
                'purchaseItemId': item.id,
              },
            );
          },
          onQuantityChanged: (newQty) {
            ref
                .read(addPurchaseProvider.notifier)
                .updateProduct(item.copyWith(quantity: newQty));
          },
        );
      },
    );
  }
}
