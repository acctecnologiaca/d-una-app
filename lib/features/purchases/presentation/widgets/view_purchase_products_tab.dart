import 'package:flutter/material.dart';
import '../providers/purchase_details_provider.dart';
import 'purchase_added_product_card.dart';

class ViewPurchaseProductsTab extends StatelessWidget {
  final PurchaseDetailsData data;

  const ViewPurchaseProductsTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.items.isEmpty) {
      return Center(
        child: Text(
          'No hay productos registrados',
          style: TextStyle(
            color: Theme.of(context).colorScheme.outlineVariant,
            fontSize: 16,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 100,
        ),
        itemCount: data.items.length,
        itemBuilder: (context, index) {
          final item = data.items[index];
          final hasMissingSerials = item.requiresSerials &&
              data.serials.where((s) => s.productId == item.productId).length <
                  item.quantity;

          return PurchaseAddedProductCard(
            item: item,
            isReadOnly: true,
            hasError: hasMissingSerials,
            onDelete: () {},
            onEdit: () {},
            onAddSerials: () {},
            onQuantityChanged: (_) {},
          );
        },
      ),
    );
  }
}
