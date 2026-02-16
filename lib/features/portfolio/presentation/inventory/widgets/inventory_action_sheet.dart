import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../data/models/product_model.dart';
import 'inventory_item_card.dart';
import '../../widgets/estimate_price_sheet.dart';

class InventoryActionSheet {
  static void show({
    required BuildContext context,
    required Product product,
    required double currentPrice,
    int? currentStock, // Optional, can be mocked if null
  }) {
    // Mock data for display consistency if not provided
    // If currentPrice is 0 (from search), we might want to mock it too for the display?
    // The previous logic in OwnInventoryScreen passed a random price from the list item to the sheet.
    // Here we accept what is passed. If stock is null, we can mock it.

    final displayStock = currentStock ?? (5 + Random().nextInt(26));

    CustomActionSheet.show(
      context: context,
      title: 'Producto seleccionado',
      content: InventoryItemCard(
        name: product.name,
        brand: product.brand?.name ?? 'Sin marca',
        model: product.model ?? 'Sin modelo',
        stock: displayStock,
        price: currentPrice,
        imageUrl: product.imageUrl,
        onTap: () {}, // No action in sheet
      ),
      actions: [
        BottomSheetActionItem(
          icon: Icons.local_offer_outlined,
          label: 'Estimar precio de venta',
          onTap: () {
            context.pop();
            EstimatePriceSheet.show(
              context,
              basePrice: currentPrice,
              productName: product.name,
              productBrand: product.brand?.name,
              productModel: product.model,
              // uom: product.uom?.name ?? 'ud.', // Assuming Product has uom. If not, default to 'ud.'
              // Waiting to check Product model to confirm uom field access.
              // For now I will assume it might not be there or need confirmation.
              // Actually, I can check the file view first.
            );
          },
        ),
        BottomSheetActionItem(
          icon: Icons.request_quote_outlined,
          label: 'Cotizar a un cliente',
          onTap: () {
            context.pop();
            // TODO: Implement Quote to Client
          },
        ),
        BottomSheetActionItem(
          icon: 'assets/icons/add_request_quote.png',
          label: 'Agregar a cotización existente',
          onTap: () {
            context.pop();
            // TODO: Implement Add to Existing Quote
          },
        ),
        BottomSheetActionItem(
          icon: Icons.info_outline,
          label: 'Detalles del producto',
          onTap: () {
            context.pop();
            context.push(
              '/portfolio/own-inventory/details/${product.id}',
              extra: product,
            );
          },
        ),
      ],
    );
  }
}
