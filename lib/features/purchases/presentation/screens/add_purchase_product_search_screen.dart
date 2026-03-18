import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/generic_search_screen.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/purchase_product_list_item.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';

class AddPurchaseProductSearchScreen extends ConsumerWidget {
  const AddPurchaseProductSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return GenericSearchScreen<Product>(
      title: 'Buscar producto',
      hintText: 'Nombre, marca o modelo...',
      historyKey: 'purchase_product_selection_search_history',
      data: productsAsync,
      filter: (product, query) {
        final q = query.normalized;
        final name = product.name.normalized;
        final brand = (product.brand?.name ?? '').normalized;
        final model = (product.model ?? '').normalized;
        return name.contains(q) || brand.contains(q) || model.contains(q);
      },
      itemBuilder: (context, product) {
        return PurchaseProductListItem(
          brand: product.brand?.name ?? 'Sin marca',
          name: product.name,
          model: product.model ?? 'Sin modelo',
          uom: product.uomModel,
          imageUrl: product.imageUrl,
          onTap: () {
            // Placeholder for modal bottom sheet (deferred)
          },
        );
      },
    );
  }
}
