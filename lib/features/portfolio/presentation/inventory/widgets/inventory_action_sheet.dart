import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../data/models/product_model.dart';
import '../../../../quotes/data/models/quote_item_product.dart';
import '../../../../quotes/presentation/create_quote/providers/create_quote_provider.dart';
import '../../../../quotes/presentation/create_quote/widgets/quote_product_sale_details_sheet.dart';
import 'inventory_item_card.dart';
import '../../widgets/estimate_price_sheet.dart';

class InventoryActionSheet {
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required Product product,
    required double currentPrice,
    double? currentStock, // Optional, can be mocked if null
  }) {
    // Mock data for display consistency if not provided
    // If currentPrice is 0 (from search), we might want to mock it too for the display?
    // The previous logic in OwnInventoryScreen passed a random price from the list item to the sheet.
    // Here we accept what is passed. If stock is null, we can mock it.

    final displayStock = currentStock ?? 0.0;

    CustomActionSheet.show(
      context: context,
      title: 'Producto seleccionado',
      content: InventoryItemCard(
        name: product.name,
        brand: product.brand?.name ?? 'Sin marca',
        model: product.model ?? 'Sin modelo',
        stock: displayStock,
        price: currentPrice,
        unit: product.uom,
        uomIconName: product.uomModel?.iconName,
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
          onTap: () async {
            context.pop();
            // 1. Reset quote provider to start fresh
            ref.read(createQuoteProvider.notifier).reset();
            // 2. Add product to quote
            await _addProductToQuote(context, ref, product, currentPrice);
          },
        ),
        BottomSheetActionItem(
          icon: 'assets/icons/add_request_quote.png',
          label: 'Agregar a cotización existente',
          onTap: () async {
            context.pop();
            // 1. Add product to existing quote (don't reset)
            await _addProductToQuote(context, ref, product, currentPrice);
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

  static Future<void> _addProductToQuote(
    BuildContext context,
    WidgetRef ref,
    Product product,
    double costPrice,
  ) async {
    // 1. Show Sale Details Sheet to get price and margin
    final result = await QuoteProductSaleDetailsSheet.show(
      context,
      averageCost: costPrice,
      productName: product.name,
      uom: product.uom ?? 'ud.',
      brand: product.brand?.name,
      model: product.model,
    );

    if (result == null) return; // User cancelled

    final double sellingPrice = result['sellingPrice'];
    final double profitMargin = result['profitMargin'];
    final double taxRate = result['taxRate'];

    // 2. Build the QuoteItemProduct
    final quoteItem = QuoteItemProduct(
      id: const Uuid().v4(),
      quoteId: 'draft',
      productId: product.id,
      name: product.name,
      model: product.model,
      uom: product.uom ?? 'ud.',
      uomIconName: product.uomModel?.iconName,
      availableStock: product.inventoryQuantity,
      quantity: 1.0, // Default to 1
      costPrice: costPrice,
      profitMargin: profitMargin,
      unitPrice: sellingPrice,
      taxRate: taxRate * 100, // QuoteItemProduct expects percentage
      taxAmount: sellingPrice * taxRate,
      totalPrice: (sellingPrice * (1 + taxRate)),
    );

    // 3. Add to state
    ref.read(createQuoteProvider.notifier).addProduct(quoteItem);

    // 4. Navigate to create quote screen
    if (context.mounted) {
      context.push('/quotes/create');
    }
  }
}
