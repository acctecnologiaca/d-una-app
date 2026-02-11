import 'package:flutter/material.dart';

import '../../../../../shared/widgets/bottom_sheet_action_item.dart';

class ProductActionSheet extends StatelessWidget {
  final String supplierName;
  final String productName;
  final double price;
  final int stock;
  final bool isWholesale;

  const ProductActionSheet({
    super.key,
    required this.supplierName,
    required this.productName,
    required this.price,
    required this.stock,
    required this.isWholesale,
  });

  static void show(
    BuildContext context, {
    required String supplierName,
    required String productName,
    required double price,
    required int stock,
    required bool isWholesale,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Important for custom shape
      builder: (context) => ProductActionSheet(
        supplierName: supplierName,
        productName: productName,
        price: price,
        stock: stock,
        isWholesale: isWholesale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We reuse CustomActionSheet logic but customized for this specific layout
    // The user mock shows a header with "Proveedor seleccionado" and supplier details

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Proveedor seleccionado',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance close button
                ],
              ),
            ),

            const Divider(),

            // Supplier Info Block
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWholesale ? 'Mayorista' : 'Minorista',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              supplierName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.info,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                        // Location could go here if available
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer
                              .withOpacity(0.5), // Subtle badge
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 14,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$stock ud.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),

            // Actions List
            BottomSheetActionItem(
              icon: Icons.sell_outlined,
              label: 'Estimar precio de venta',
              onTap: () {
                Navigator.pop(context);
                // Implementation pending
              },
            ),
            BottomSheetActionItem(
              icon: Icons.shopping_cart_outlined,
              label: 'Realizar nuevo pedido',
              onTap: () {
                Navigator.pop(context);
                // Implementation pending
              },
            ),
            BottomSheetActionItem(
              icon: Icons.add_shopping_cart,
              label: 'Agregar a pedido existente',
              onTap: () {
                Navigator.pop(context);
                // Implementation pending
              },
            ),
            BottomSheetActionItem(
              icon: Icons.request_quote_outlined,
              label: 'Cotizar a cliente',
              onTap: () {
                Navigator.pop(context);
                // Implementation pending
              },
            ),
            BottomSheetActionItem(
              icon: Icons.post_add,
              label: 'Agregar a cotización existente',
              onTap: () {
                Navigator.pop(context);
                // Implementation pending
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
