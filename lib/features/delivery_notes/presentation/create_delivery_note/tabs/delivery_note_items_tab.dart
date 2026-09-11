import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/utils/fab_scroll_padding.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import '../../../domain/models/delivery_note_item_model.dart';
import '../../manage_serials/screens/delivery_note_manage_serials_screen.dart';
import '../providers/create_delivery_note_provider.dart';
import '../widgets/delivery_note_added_product_card.dart';
import '../widgets/delivery_note_product_details_sheet.dart';
import '../widgets/delivery_note_register_serials_dialog.dart';

class DeliveryNoteItemsTab extends ConsumerWidget {
  final String? highlightProductId;
  final VoidCallback? onManageSerialsPressed;

  const DeliveryNoteItemsTab({
    super.key,
    this.highlightProductId,
    this.onManageSerialsPressed,
  });

  void _openManageSerials(
    BuildContext context,
    WidgetRef ref,
    DeliveryNoteItemModel item,
    int index,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeliveryNoteManageSerialsScreen(
          item: item,
          onSerialsSaved: (serials) {
            ref
                .read(createDeliveryNoteProvider.notifier)
                .updateItemSerials(index, serials);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createDeliveryNoteProvider);
    final colors = Theme.of(context).colorScheme;

    if (state.items.isEmpty) {
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
      padding: const EdgeInsets.fromLTRB(0, 8, 0, FabScrollPadding.single),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        final product = allProducts.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => Product(
            id: item.productId ?? '',
            userId: '',
            name: item.name,
            uomModel: null,
            brand: null,
            model: item.model,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        Widget buildCard(Color? highlightColor) {
          return DeliveryNoteAddedProductCard(
            item: item,
            backgroundColor: highlightColor,
            availableStock: product.availableQuantity,
            onDelete: () {
              ref.read(createDeliveryNoteProvider.notifier).removeItem(index);
            },
            onEditDetails: () async {
              final result = await DeliveryNoteProductDetailsSheet.show(
                context,
                product: product,
                existingItem: item,
              );

              if (result != null && context.mounted) {
                final hasWarranty = result['has_warranty'] as bool;
                final wQty = result['warranty_duration'] as int;
                final wPeriodStr = result['warranty_period'] as String;
                bool usesSerials = result['uses_serials'] as bool;
                final bool needsToAsk = result['needs_to_ask_serials'] == true;

                bool registerSerialsNow = false;

                if (needsToAsk && context.mounted) {
                  final dialogResult =
                      await DeliveryNoteRegisterSerialsDialog.show(context);
                  if (dialogResult == null) return;
                  switch (dialogResult) {
                    case DeliveryNoteRegisterSerialsResult.now:
                      registerSerialsNow = true;
                      break;
                    case DeliveryNoteRegisterSerialsResult.later:
                      registerSerialsNow = false;
                      break;
                    case DeliveryNoteRegisterSerialsResult.never:
                      usesSerials = false;
                      registerSerialsNow = false;
                      break;
                  }
                }

                final wUnit = wPeriodStr == 'Días'
                    ? 'days'
                    : (wPeriodStr == 'Meses' ? 'months' : 'years');

                final updatedItem = item.copyWith(
                  warrantyTime: hasWarranty ? wQty : null,
                  warrantyUnit: hasWarranty ? wUnit : null,
                  requiresSerials: usesSerials,
                );

                ref
                    .read(createDeliveryNoteProvider.notifier)
                    .updateItem(index, updatedItem);

                if (registerSerialsNow && context.mounted) {
                  _openManageSerials(context, ref, updatedItem, index);
                }
              }
            },
            onManageSerials: () {
              _openManageSerials(context, ref, item, index);
            },
            onQuantityChanged: (newQty) {
              ref
                  .read(createDeliveryNoteProvider.notifier)
                  .updateItemQuantity(index, newQty);
            },
          );
        }

        final isHighlighted =
            item.productId != null && item.productId == highlightProductId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: isHighlighted
              ? HighlightableWidget(
                  builder: (context, highlightColor) =>
                      buildCard(highlightColor),
                )
              : buildCard(null),
        );
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
      duration: const Duration(milliseconds: 500),
    );

    _colorAnimation = ColorTween(
      begin: null,
      end: Colors.yellow.withValues(alpha: 0.25),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);

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
