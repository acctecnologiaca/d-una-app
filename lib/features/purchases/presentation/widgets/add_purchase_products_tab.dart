import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_product_details_sheet.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/register_serials_dialog.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/purchase_added_product_card.dart';
import 'package:go_router/go_router.dart';

class AddPurchaseProductsTab extends ConsumerWidget {
  final String? highlightProductId;

  const AddPurchaseProductsTab({
    super.key,
    this.highlightProductId,
  });

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
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
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

        final isLinkedToOrder = state.supplierOrderId != null;

        Widget buildCard(Color? highlightColor) {
          return PurchaseAddedProductCard(
            item: item,
            hasError: hasMissingSerials,
            backgroundColor: highlightColor,
            isEditable: !isLinkedToOrder,
            onDelete: () {
              if (isLinkedToOrder) return;
              ref
                  .read(addPurchaseProvider.notifier)
                  .removeProduct(item.productId);
            },
            onEdit: () async {
              final result = await AddPurchaseProductDetailsSheet.show(
                context,
                product: product,
                existingItem: item,
                isLinkedToOrder: isLinkedToOrder,
              );

              if (result != null) {
                final qty = (result['quantity'] as num).toDouble();
                final cost = (result['cost_price'] as num).toDouble();
                final hasWarranty = result['has_warranty'] as bool;
                final wQty = result['warranty_duration'] as int;
                final wPeriodStr = result['warranty_period'] as String;
                bool usesSerials = result['uses_serials'] as bool;
                final bool needsToAsk = result['needs_to_ask_serials'] == true;

                bool registerSerialsNow = false;

                if (needsToAsk && context.mounted) {
                  final dialogResult = await RegisterSerialsDialog.show(context);
                  if (dialogResult == null) return;
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

                final wUnit = wPeriodStr == 'Días'
                    ? 'days'
                    : (wPeriodStr == 'Meses' ? 'months' : 'years');

                final updatedItem = item.copyWith(
                  quantity: qty,
                  unitPrice: cost,
                  warrantyTime: hasWarranty ? wQty : null,
                  warrantyUnit: hasWarranty ? wUnit : null,
                  requiresSerials: usesSerials,
                );

                ref.read(addPurchaseProvider.notifier).updateProduct(updatedItem);

                // If user selected "Register Now", navigate to serials
                if (registerSerialsNow) {
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
              if (isLinkedToOrder) return;
              ref
                  .read(addPurchaseProvider.notifier)
                  .updateProduct(item.copyWith(quantity: newQty));
            },
          );
        }

        if (item.productId == highlightProductId) {
          return HighlightableWidget(
            builder: (context, highlightColor) => buildCard(highlightColor),
          );
        }
        return buildCard(null);
      },
    );
  }
}

class HighlightableWidget extends StatefulWidget {
  final Widget Function(BuildContext context, Color? color) builder;
  const HighlightableWidget({super.key, required this.builder});

  @override
  State<HighlightableWidget> createState() => _HighlightableWidgetState();
}

class _HighlightableWidgetState extends State<HighlightableWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // 500ms per half-blink cycle
    );

    _colorAnimation = ColorTween(
      begin: null, // Let it default to the card's default background
      end: Colors.yellow.withValues(alpha: 0.25),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Repeat the blink animation (reverse is true to go back to transparent)
    _controller.repeat(reverse: true);
    
    // Stop blinking after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.stop();
        _controller.value = 0.0;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return widget.builder(context, _colorAnimation.value);
      },
    );
  }
}
