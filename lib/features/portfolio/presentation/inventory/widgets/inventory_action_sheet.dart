import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
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
import '../../../../purchases/presentation/providers/add_purchase_provider.dart';
import '../../../../purchases/presentation/widgets/add_purchase_product_details_sheet.dart';
import '../../../../purchases/presentation/widgets/register_serials_dialog.dart';
import '../../../../purchases/data/models/purchase_item_product.dart';
import '../../../../purchases/domain/models/purchase_model.dart';
import '../../../../purchases/presentation/providers/purchases_providers.dart';
import '../../../../purchases/presentation/providers/purchase_details_provider.dart';
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
            // 2. Load the selected quote into the provider (respecting draft if exists)
            final draft = await ref
                .read(createQuoteProvider.notifier)
                .checkAndRestoreDraft(quoteId: selectedQuote.id);
            if (draft == null) {
              await ref
                  .read(createQuoteProvider.notifier)
                  .loadQuote(selectedQuote.id);
            }
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
          icon: Icons.receipt_long_outlined,
          label: 'Agregar a registro de compra nuevo',
          onTap: () async {
            context.pop();
            await _addProductToNewPurchase(context, ref, product, currentPrice);
          },
        ),
        BottomSheetActionItem(
          icon: 'assets/icons/receipt_long_add.png',
          label: 'Agregar a registro de compra existente',
          onTap: () async {
            context.pop();
            // 1. Navigate to purchase selection screen
            final selectedPurchase = await context.push<Purchase>(
              '/my-purchases/select',
            );
            if (selectedPurchase == null || !context.mounted) return;

            // 2. Add product to selected purchase
            await _addProductToExistingPurchase(
              context,
              ref,
              product,
              currentPrice,
              selectedPurchase,
            );
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
        AppToast.error(
          context,
          message:
              'No se puede agregar este producto. El inventario disponible es 0 ${product.uom ?? "ud."}',
          duration: const Duration(seconds: 5),
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
      label = 'Garantía restante: ${res.time} ${_unitLabel(res.unit)}';
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
          AppToast.error(
            context,
            message:
                'No se puede agregar más de este producto. La cotización ya tiene agregada el stock máximo disponible.',
            duration: const Duration(seconds: 8),
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
      await ref
          .read(createQuoteProvider.notifier)
          .saveDraftNow(quoteId: quoteState.quote?.id);

      // Show feedback SnackBar
      if (context.mounted) {
        AppToast.info(
          context,
          message:
              'Este producto ya se encuentra en la cotización. Se ha actualizado la cantidad a ${newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 2)} ${product.uom ?? "ud."}',
          duration: const Duration(seconds: 8),
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
        AppToast.error(
          context,
          message:
              'Sin stock. Añade este producto usando la opción "Proveedor Externo" desde la cotización.',
          duration: const Duration(seconds: 8),
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
      label = 'Garantía restante: ${res.time} ${_unitLabel(res.unit)}';
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
    await ref
        .read(createQuoteProvider.notifier)
        .saveDraftNow(quoteId: ref.read(createQuoteProvider).quote?.id);

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

  static Future<void> _addProductToNewPurchase(
    BuildContext context,
    WidgetRef ref,
    Product product,
    double costPrice,
  ) async {
    if (!context.mounted) return;

    final result = await AddPurchaseProductDetailsSheet.show(
      context,
      product: product,
    );

    if (result == null) return; // User cancelled

    final double quantity = result['quantity'];
    final double cost = result['cost_price'];
    final int warrantyDuration = result['warranty_duration'];
    final String wPeriodStr = result['warranty_period'];

    final wUnit = wPeriodStr == 'Días'
        ? 'days'
        : (wPeriodStr == 'Meses' ? 'months' : 'years');

    bool usesSerials = result['uses_serials'];
    final bool needsToAsk = result['needs_to_ask_serials'] == true;
    bool registerSerialsNow = false;

    if (needsToAsk && context.mounted) {
      final dialogResult = await RegisterSerialsDialog.show(context);
      if (dialogResult == null) return; // User dismissed
      switch (dialogResult) {
        case RegisterSerialsResult.now:
          registerSerialsNow = true;
          break;
        case RegisterSerialsResult.later:
          registerSerialsNow = false;
          break;
        case RegisterSerialsResult.never:
          usesSerials = false;
          registerSerialsNow = false;
          break;
      }
    }

    final purchaseItem = PurchaseItemProduct(
      id: const Uuid().v4(),
      productId: product.id,
      name: product.name,
      model: product.model,
      brand: product.brand?.name,
      uom: product.uom ?? 'ud.',
      quantity: quantity,
      unitPrice: cost,
      warrantyTime: warrantyDuration,
      warrantyUnit: wUnit,
      requiresSerials: usesSerials,
    );

    ref.read(addPurchaseProvider.notifier).reset();
    ref.read(addPurchaseProvider.notifier).addProduct(purchaseItem);

    if (context.mounted) {
      context.push('/my-purchases/add', extra: {'initialTabIndex': 1});

      if (registerSerialsNow) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            context.push(
              '/my-purchases/add/select-product/manage-serials',
              extra: <String, dynamic>{
                'product': product,
                'quantity': quantity.toInt(),
                'purchaseItemId': purchaseItem.id,
              },
            );
          }
        });
      }
    }
  }

  static Future<void> _addProductToExistingPurchase(
    BuildContext context,
    WidgetRef ref,
    Product product,
    double costPrice,
    Purchase selectedPurchase,
  ) async {
    // Show loading indicator while fetching purchase details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    PurchaseDetailsData details;
    try {
      details = await ref
          .read(purchasesRepositoryProvider)
          .getPurchaseDetails(selectedPurchase.id);
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog
        AppToast.error(
          context,
          message: 'Error al cargar la compra: $e',
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Check if product already exists in this purchase
    final exists = details.items.any((item) => item.productId == product.id);
    if (exists) {
      AppToast.warning(
        context,
        message: 'Este producto ya se encuentra en la compra.',
      );
      context.push(
        '/my-purchases/view/${selectedPurchase.id}',
        extra: {'highlightProductId': product.id},
      );
      return;
    }

    // Load purchase details into the provider edit state
    ref
        .read(addPurchaseProvider.notifier)
        .loadFromDetails(
          details.purchase,
          details.items,
          details.serials,
          details.supplierTaxId,
        );

    // Show details sheet for the product to be added
    final result = await AddPurchaseProductDetailsSheet.show(
      context,
      product: product,
    );

    if (result == null) {
      // Reset the provider if cancelled so we don't keep dirty state
      ref.read(addPurchaseProvider.notifier).reset();
      return;
    }

    final double quantity = result['quantity'];
    final double cost = result['cost_price'];
    final int warrantyDuration = result['warranty_duration'];
    final String wPeriodStr = result['warranty_period'];

    final wUnit = wPeriodStr == 'Días'
        ? 'days'
        : (wPeriodStr == 'Meses' ? 'months' : 'years');

    bool usesSerials = result['uses_serials'];
    final bool needsToAsk = result['needs_to_ask_serials'] == true;
    bool registerSerialsNow = false;

    if (needsToAsk && context.mounted) {
      final dialogResult = await RegisterSerialsDialog.show(context);
      if (dialogResult == null) {
        ref.read(addPurchaseProvider.notifier).reset();
        return;
      }
      switch (dialogResult) {
        case RegisterSerialsResult.now:
          registerSerialsNow = true;
          break;
        case RegisterSerialsResult.later:
          registerSerialsNow = false;
          break;
        case RegisterSerialsResult.never:
          usesSerials = false;
          registerSerialsNow = false;
          break;
      }
    }

    final purchaseItem = PurchaseItemProduct(
      id: const Uuid().v4(),
      productId: product.id,
      name: product.name,
      model: product.model,
      brand: product.brand?.name,
      uom: product.uom ?? 'ud.',
      quantity: quantity,
      unitPrice: cost,
      warrantyTime: warrantyDuration,
      warrantyUnit: wUnit,
      requiresSerials: usesSerials,
    );

    // Add to existing purchase products
    ref.read(addPurchaseProvider.notifier).addProduct(purchaseItem);

    if (context.mounted) {
      // Navigate to the purchase view in EDIT mode
      context.push(
        '/my-purchases/view/${selectedPurchase.id}',
        extra: {'editMode': true},
      );

      if (registerSerialsNow) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            context.push(
              '/my-purchases/add/select-product/manage-serials',
              extra: <String, dynamic>{
                'product': product,
                'quantity': quantity.toInt(),
                'purchaseItemId': purchaseItem.id,
              },
            );
          }
        });
      }
    }
  }
}
