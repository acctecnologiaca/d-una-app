import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/purchase_added_product_card.dart';

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
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.products.length,
      itemBuilder: (context, index) {
        final item = state.products[index];
        
        return PurchaseAddedProductCard(
          item: item,
          onDelete: () {
            ref.read(addPurchaseProvider.notifier).removeProduct(item.productId);
          },
          onEdit: () {
            // TODO: Open edit sheet for quantity, cost, warranty
          },
          onAddSerials: () {
            // TODO: Open serials management screen/sheet
          },
        );
      },
    );
  }
}
