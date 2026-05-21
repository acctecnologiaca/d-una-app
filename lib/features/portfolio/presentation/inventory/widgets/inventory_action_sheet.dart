import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../data/models/product_model.dart';
import '../../../../quotes/data/models/quote_item_product.dart';
import '../../../../quotes/domain/models/quote_model.dart';
import '../../../../quotes/presentation/create_quote/providers/create_quote_provider.dart';
import '../../../../quotes/presentation/create_quote/widgets/quote_product_sale_details_sheet.dart';
import '../../../../quotes/data/repositories/warranty_repository.dart';
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
          label: 'Agregar a cotización nueva',
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
            context.pop(); // Close action sheet
            // 1. Navigate to quote selection screen
            final selectedQuote = await context.push<Quote>(
              '/quotes/select',
              extra: {'rejected', 'finalized', 'cancelled'},
            );
            if (selectedQuote == null || !context.mounted) return;
            // 2. Load the selected quote into the provider
            await ref
                .read(createQuoteProvider.notifier)
                .loadQuote(selectedQuote.id);
            // 3. Show details sheet and add product
            if (context.mounted) {
              await _addProductToExistingQuote(
                context,
                ref,
                product,
                currentPrice,
              );
            }
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
    if (product.inventoryQuantity <= 0.0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text(
              'No se puede agregar este producto. El inventario disponible es 0 ${product.uom ?? "ud."}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final repo = ref.read(warrantyRepositoryProvider);
    final res = await repo.getResidualWarranty(product.id);

    int? suggestedTime;
    String? suggestedUnit;
    bool? isExpired;
    String? label;

    if (res != null) {
      suggestedTime = res.time;
      suggestedUnit = res.unit;
      isExpired = res.isExpired;
      label =
          'Garantía residual (Inventario propio): ${res.time} ${_unitLabel(res.unit)}';
    }

    if (!context.mounted) return;

    // 1. Show Sale Details Sheet to get price and margin
    final result = await QuoteProductSaleDetailsSheet.show(
      context,
      averageCost: costPrice,
      productName: product.name,
      uom: product.uom ?? 'ud.',
      brand: product.brand?.name,
      model: product.model,
      suggestedWarrantyTime: suggestedTime,
      suggestedWarrantyUnit: suggestedUnit,
      isWarrantyExpired: isExpired,
      warrantySuggestionLabel: label,
    );

    if (result == null) return; // User cancelled

    final double sellingPrice = result['sellingPrice'];
    final double profitMargin = result['profitMargin'];
    final double taxRate = result['taxRate'];
    final String? deliveryTimeId = result['deliveryTimeId'];
    final int? warrantyTime = result['warrantyTime'];
    final String? warrantyUnit = result['warrantyUnit'];

    // 2. Build the QuoteItemProduct
    final quoteItem = QuoteItemProduct(
      groupIndex: ref.read(createQuoteProvider).nextGroupIndex,
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
      sourceType: QuoteItemSourceType.own,
      deliveryTimeId: deliveryTimeId,
      warrantyTime: warrantyTime,
      warrantyUnit: warrantyUnit,
    );

    // 3. Add to state
    ref.read(createQuoteProvider.notifier).addProduct(quoteItem);

    // 4. Navigate to create quote screen
    if (context.mounted) {
      context.push('/quotes/create');
    }
  }

  static Future<void> _addProductToExistingQuote(
    BuildContext context,
    WidgetRef ref,
    Product product,
    double costPrice,
  ) async {
    final colors = Theme.of(context).colorScheme;
    final quoteState = ref.read(createQuoteProvider);
    final existingProducts = quoteState.products;

    // Check if this own product is already present in the current quote
    QuoteItemProduct? existingItem;
    for (final p in existingProducts) {
      if (p.productId == product.id &&
          p.sourceType == QuoteItemSourceType.own) {
        existingItem = p;
        break;
      }
    }

    if (existingItem != null) {
      // Increment quantity and update totals
      final newQty = existingItem.quantity + 1.0;
      final availableStock =
          existingItem.availableStock ?? product.inventoryQuantity;

      if (newQty > availableStock) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 8),
              content: const Text(
                'No se puede agregar más de este producto. La cotización ya tiene agregada el stock máximo disponible.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: colors.error,
              showCloseIcon: true,
            ),
          );

          final quoteId = quoteState.quote?.id;
          if (quoteId != null) {
            context.push('/quotes/edit/$quoteId');
          } else {
            context.push('/quotes/create');
          }
        }
        return;
      }

      final taxAmount = existingItem.unitPrice * (existingItem.taxRate / 100);
      final totalPrice = (existingItem.unitPrice + taxAmount) * newQty;

      final updatedItem = existingItem.copyWith(
        quantity: newQty,
        taxAmount: taxAmount,
        totalPrice: totalPrice,
      );

      // Update state
      ref.read(createQuoteProvider.notifier).updateProduct(updatedItem);

      // Show feedback SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(
              'Este producto ya se encuentra en la cotización. Se ha actualizado la cantidad a ${newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 2)} ${product.uom ?? "ud."}',
            ),
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );

        final quoteId = quoteState.quote?.id;
        if (quoteId != null) {
          context.push('/quotes/edit/$quoteId');
        } else {
          context.push('/quotes/create');
        }
      }
      return;
    }

    if (product.inventoryQuantity <= 0.0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: const Text(
              'Sin stock. Añade este producto usando la opción "Proveedor Externo" desde la cotización.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colors.error,
            showCloseIcon: true,
          ),
        );
      }
      return;
    }

    final repo = ref.read(warrantyRepositoryProvider);
    final res = await repo.getResidualWarranty(product.id);

    int? suggestedTime;
    String? suggestedUnit;
    bool? isExpired;
    String? label;

    if (res != null) {
      suggestedTime = res.time;
      suggestedUnit = res.unit;
      isExpired = res.isExpired;
      label =
          'Garantía residual (Inventario propio): ${res.time} ${_unitLabel(res.unit)}';
    }

    if (!context.mounted) return;

    // 1. Show Sale Details Sheet to get price and margin
    final result = await QuoteProductSaleDetailsSheet.show(
      context,
      averageCost: costPrice,
      productName: product.name,
      uom: product.uom ?? 'ud.',
      brand: product.brand?.name,
      model: product.model,
      suggestedWarrantyTime: suggestedTime,
      suggestedWarrantyUnit: suggestedUnit,
      isWarrantyExpired: isExpired,
      warrantySuggestionLabel: label,
    );

    if (result == null) return; // User cancelled

    final double sellingPrice = result['sellingPrice'];
    final double profitMargin = result['profitMargin'];
    final double taxRate = result['taxRate'];
    final String? deliveryTimeId = result['deliveryTimeId'];
    final int? warrantyTime = result['warrantyTime'];
    final String? warrantyUnit = result['warrantyUnit'];

    // 2. Build the QuoteItemProduct
    final quoteItem = QuoteItemProduct(
      groupIndex: ref.read(createQuoteProvider).nextGroupIndex,
      id: const Uuid().v4(),
      quoteId: ref.read(createQuoteProvider).quote?.id ?? 'draft',
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
      sourceType: QuoteItemSourceType.own,
      deliveryTimeId: deliveryTimeId,
      warrantyTime: warrantyTime,
      warrantyUnit: warrantyUnit,
    );

    // 3. Add to state
    ref.read(createQuoteProvider.notifier).addProduct(quoteItem);

    // 4. Navigate to edit/create quote screen
    if (context.mounted) {
      final quoteId = ref.read(createQuoteProvider).quote?.id;
      if (quoteId != null) {
        context.push('/quotes/edit/$quoteId');
      } else {
        context.push('/quotes/create');
      }
    }
  }

  static String _unitLabel(String unit) {
    return switch (unit) {
      'days' => 'Días',
      'months' => 'Meses',
      'years' => 'Años',
      _ => unit,
    };
  }
}
