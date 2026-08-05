import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../quotes/data/models/quote_item_product.dart';
import '../../../../quotes/domain/models/quote_model.dart';
import '../../../../quotes/presentation/create_quote/providers/create_quote_provider.dart';
import '../../../../quotes/presentation/create_quote/widgets/quote_product_sale_details_sheet.dart';
import 'supplier_product_row.dart';
import '../../widgets/estimate_price_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../supplier_orders/presentation/create_supplier_order/providers/create_supplier_order_provider.dart';
import '../../../../supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import '../../../../supplier_orders/domain/models/supplier_order.dart';
import '../../../../supplier_orders/domain/models/supplier_order_item.dart';
import '../../../../supplier_orders/domain/models/supplier_order_status.dart';

class ProductActionSheet {
  static void show(
    BuildContext context, {
    required WidgetRef ref,
    required String supplierBranchStockId,
    required String supplierName,
    required String productName,
    required double price,
    required int stock,
    required bool isWholesale,
    String uom = 'ud.',
    String? uomIconName,
    String? location,
    String? brand,
    String? model,
  }) {
    CustomActionSheet.show(
      context: context,
      title: 'Proveedor y sucursal seleccionada',
      content: SupplierProductRow(
        supplierName: supplierName,
        price: price,
        stock: stock,
        uom: uom,
        uomIconName: uomIconName,
        isWholesale: isWholesale,
        locationName: location,
      ),
      actions: [
        BottomSheetActionItem(
          icon: Icons.sell_outlined,
          label: 'Estimar precio de venta',
          onTap: () {
            context.pop();
            EstimatePriceSheet.show(
              context,
              basePrice: price,
              productName: productName,
              productBrand: brand,
              productModel: model,
              uom: uom,
            );
          },
        ),
        BottomSheetActionItem(
          icon: Icons.shopping_cart_outlined,
          label: 'Agregar a orden de compra nueva',
          onTap: () async {
            context.pop();
            // Initialize new draft order with this supplier
            final response = await Supabase.instance.client
                .from('suppliers')
                .select('id, name')
                .eq('name', supplierName)
                .maybeSingle();

            final String supplierId = response != null
                ? response['id'] as String
                : '';

            ref
                .read(createSupplierOrderProvider.notifier)
                .initializeNew(
                  supplierId: supplierId,
                  supplierName: supplierName,
                );

            // Add the product directly
            ref
                .read(createSupplierOrderProvider.notifier)
                .addItem(
                  name: productName,
                  brand: brand,
                  model: model,
                  uom: uom,
                  uomIconName: uomIconName,
                  quantity: 1.0,
                  unitPrice: price,
                  supplierBranchStockId: supplierBranchStockId,
                  currentSupplierStock: stock.toDouble(),
                );

            if (context.mounted) {
              context.push('/supplier-orders/create');
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.add_shopping_cart,
          label: 'Agregar a orden de compra existente',
          onTap: () async {
            context.pop();

            final selectedOrder = await context.push<SupplierOrder>(
              '/supplier-orders/select',
              extra: {
                'statuses': {
                  SupplierOrderStatus.draft,
                  SupplierOrderStatus.sent,
                  SupplierOrderStatus.resent,
                },
                'supplierName': supplierName,
              },
            );
            if (selectedOrder == null || !context.mounted) return;

            final repo = ref.read(supplierOrdersRepositoryProvider);
            final details = await repo.getSupplierOrderDetails(
              selectedOrder.id,
            );
            ref
                .read(createSupplierOrderProvider.notifier)
                .loadFromExisting(details.order, details.items);

            if (context.mounted) {
              await _addSupplierProductToExistingOrder(
                context,
                ref,
                supplierBranchStockId: supplierBranchStockId,
                supplierName: supplierName,
                productName: productName,
                price: price,
                stock: stock,
                uom: uom,
                uomIconName: uomIconName,
                brand: brand,
                model: model,
              );
            }
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
            await _addSupplierProductToQuote(
              context,
              ref,
              supplierBranchStockId: supplierBranchStockId,
              supplierName: supplierName,
              productName: productName,
              price: price,
              stock: stock,
              uom: uom,
              uomIconName: uomIconName,
              brand: brand,
              model: model,
            );
          },
        ),
        BottomSheetActionItem(
          icon: 'assets/icons/add_request_quote.png',
          label: 'Agregar a cotización existente',
          onTap: () async {
            context.pop();
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
              await _addSupplierProductToExistingQuote(
                context,
                ref,
                supplierBranchStockId: supplierBranchStockId,
                supplierName: supplierName,
                productName: productName,
                price: price,
                stock: stock,
                uom: uom,
                uomIconName: uomIconName,
                brand: brand,
                model: model,
              );
            }
          },
        ),
      ],
    );
  }

  static Future<void> _addSupplierProductToQuote(
    BuildContext context,
    WidgetRef ref, {
    required String supplierBranchStockId,
    required String supplierName,
    required String productName,
    required double price,
    required int stock,
    required String uom,
    String? uomIconName,
    String? brand,
    String? model,
  }) async {
    // Defensive stock validation
    if (stock <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text(
              'No se puede agregar este producto. El stock del proveedor es 0 $uom',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // 1. Show Sale Details Sheet
    final result = await QuoteProductSaleDetailsSheet.show(
      context,
      averageCost: price,
      productName: productName,
      uom: uom,
      brand: brand,
      model: model,
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
      supplierBranchStockId: supplierBranchStockId,
      supplierName: supplierName,
      name: productName,
      brand: brand,
      model: model,
      uom: uom,
      uomIconName: uomIconName,
      availableStock: stock.toDouble(),
      quantity: 1.0,
      costPrice: price,
      profitMargin: profitMargin,
      unitPrice: sellingPrice,
      taxRate: taxRate * 100, // Percentage
      taxAmount: sellingPrice * taxRate,
      totalPrice: (sellingPrice * (1 + taxRate)),
      sourceType: QuoteItemSourceType.affiliated,
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

  static Future<void> _addSupplierProductToExistingQuote(
    BuildContext context,
    WidgetRef ref, {
    required String supplierBranchStockId,
    required String supplierName,
    required String productName,
    required double price,
    required int stock,
    required String uom,
    String? uomIconName,
    String? brand,
    String? model,
  }) async {
    final colors = Theme.of(context).colorScheme;
    final quoteState = ref.read(createQuoteProvider);
    final existingProducts = quoteState.products;

    // Check if this supplier product is already in the quote
    // (by supplierBranchStockId, not productId)
    QuoteItemProduct? existingItem;
    for (final p in existingProducts) {
      if (p.supplierBranchStockId == supplierBranchStockId &&
          p.sourceType == QuoteItemSourceType.affiliated) {
        existingItem = p;
        break;
      }
    }

    if (existingItem != null) {
      // Increment quantity
      final newQty = existingItem.quantity + 1.0;
      final availableStock = existingItem.availableStock ?? stock.toDouble();

      if (newQty > availableStock) {
        // Show max-stock error
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
          _navigateToQuote(context, quoteState.quote?.id);
        }
        return;
      }

      // Recalculate totals
      final taxAmount = existingItem.unitPrice * (existingItem.taxRate / 100);
      final totalPrice = (existingItem.unitPrice + taxAmount) * newQty;

      final updatedItem = existingItem.copyWith(
        quantity: newQty,
        taxAmount: taxAmount,
        totalPrice: totalPrice,
      );

      ref.read(createQuoteProvider.notifier).updateProduct(updatedItem);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(
              'Este producto ya se encuentra en la cotización. Se ha actualizado la cantidad a ${newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 2)} $uom',
            ),
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );
        _navigateToQuote(context, quoteState.quote?.id);
      }
      return;
    }

    // Defensive stock validation
    if (stock <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(
              'No se puede agregar este producto. El stock del proveedor es 0 $uom',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colors.error,
            showCloseIcon: true,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // 1. Show Sale Details Sheet
    final result = await QuoteProductSaleDetailsSheet.show(
      context,
      averageCost: price,
      productName: productName,
      uom: uom,
      brand: brand,
      model: model,
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
      supplierBranchStockId: supplierBranchStockId,
      supplierName: supplierName,
      name: productName,
      brand: brand,
      model: model,
      uom: uom,
      uomIconName: uomIconName,
      availableStock: stock.toDouble(),
      quantity: 1.0,
      costPrice: price,
      profitMargin: profitMargin,
      unitPrice: sellingPrice,
      taxRate: taxRate * 100, // Percentage
      taxAmount: sellingPrice * taxRate,
      totalPrice: (sellingPrice * (1 + taxRate)),
      sourceType: QuoteItemSourceType.affiliated,
      deliveryTimeId: deliveryTimeId,
      warrantyTime: warrantyTime,
      warrantyUnit: warrantyUnit,
    );

    // 3. Add to state
    ref.read(createQuoteProvider.notifier).addProduct(quoteItem);

    // 4. Navigate to edit/create quote screen
    if (context.mounted) {
      _navigateToQuote(context, ref.read(createQuoteProvider).quote?.id);
    }
  }

  static void _navigateToQuote(BuildContext context, String? quoteId) {
    if (quoteId != null) {
      context.push('/quotes/edit/$quoteId');
    } else {
      context.push('/quotes/create');
    }
  }

  static Future<void> _addSupplierProductToExistingOrder(
    BuildContext context,
    WidgetRef ref, {
    required String supplierBranchStockId,
    required String supplierName,
    required String productName,
    required double price,
    required int stock,
    required String uom,
    String? uomIconName,
    String? brand,
    String? model,
  }) async {
    final colors = Theme.of(context).colorScheme;
    final orderState = ref.read(createSupplierOrderProvider);
    final existingItems = orderState.items;

    // Check if product already exists in order for this specific branch stock
    SupplierOrderItem? existingItem;
    for (final item in existingItems) {
      if (item.supplierBranchStockId != null &&
          supplierBranchStockId.isNotEmpty) {
        if (item.supplierBranchStockId == supplierBranchStockId) {
          existingItem = item;
          break;
        }
      } else if (item.supplierBranchStockId == null &&
          item.name.trim().toLowerCase() == productName.trim().toLowerCase() &&
          (item.brand ?? '').trim().toLowerCase() ==
              (brand ?? '').trim().toLowerCase() &&
          (item.model ?? '').trim().toLowerCase() ==
              (model ?? '').trim().toLowerCase() &&
          item.uom.trim().toLowerCase() == uom.trim().toLowerCase()) {
        existingItem = item;
        break;
      }
    }

    if (existingItem != null) {
      final double newQty = existingItem.quantity + 1.0;
      final double maxAvailable =
          existingItem.currentSupplierStock ?? stock.toDouble();

      if (newQty > maxAvailable) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 8),
              content: Text(
                'No se puede agregar más de este producto. La orden de compra ya tiene el stock máximo disponible ($maxAvailable $uom).',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: colors.error,
              showCloseIcon: true,
            ),
          );
          _navigateToSupplierOrder(context, orderState.id);
        }
        return;
      }

      // Update quantity of existing item
      ref
          .read(createSupplierOrderProvider.notifier)
          .updateItem(existingItem.id, quantity: newQty);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(
              'Este producto ya se encontraba en la orden. Se actualizó la cantidad a ${newQty.toStringAsFixed(newQty.truncateToDouble() == newQty ? 0 : 2)} $uom.',
            ),
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );
        _navigateToSupplierOrder(context, orderState.id);
      }
      return;
    }

    // Defensive stock check
    if (stock <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text(
              'No se puede agregar este producto. El stock en la sucursal es 0 $uom.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: colors.error,
            showCloseIcon: true,
          ),
        );
      }
      return;
    }

    // Add item with full branch & stock metadata
    ref
        .read(createSupplierOrderProvider.notifier)
        .addItem(
          name: productName,
          brand: brand,
          model: model,
          uom: uom,
          uomIconName: uomIconName,
          quantity: 1.0,
          unitPrice: price,
          supplierBranchStockId: supplierBranchStockId,
          currentSupplierStock: stock.toDouble(),
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text('Se agregó "$productName" a la orden de compra.'),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      );
      _navigateToSupplierOrder(context, orderState.id);
    }
  }

  static void _navigateToSupplierOrder(BuildContext context, String? orderId) {
    if (orderId != null && orderId.isNotEmpty) {
      context.push('/supplier-orders/edit/$orderId');
    } else {
      context.push('/supplier-orders/create');
    }
  }
}
