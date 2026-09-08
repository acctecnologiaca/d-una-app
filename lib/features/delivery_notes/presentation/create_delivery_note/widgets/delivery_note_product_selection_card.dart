import 'package:flutter/material.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';
import 'package:d_una_app/shared/widgets/expandable_action_card.dart';
import 'package:d_una_app/shared/widgets/editable_quantity_stepper.dart';
import 'package:d_una_app/shared/widgets/uom_status_badge.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';

class DeliveryNoteProductSelectionCard extends StatefulWidget {
  final Product product;
  final double selectedQty;
  final ValueChanged<double> onQtyChanged;
  final bool isLocked;
  final bool isAlreadyAdded;

  const DeliveryNoteProductSelectionCard({
    super.key,
    required this.product,
    required this.selectedQty,
    required this.onQtyChanged,
    this.isLocked = false,
    this.isAlreadyAdded = false,
  });

  @override
  State<DeliveryNoteProductSelectionCard> createState() =>
      _DeliveryNoteProductSelectionCardState();
}

class _DeliveryNoteProductSelectionCardState
    extends State<DeliveryNoteProductSelectionCard> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final uom = widget.product.uom ?? widget.product.uomModel?.symbol ?? 'ud.';
    final hasStock = widget.product.availableQuantity > 0;
    final maxStock = widget.product.availableQuantity;

    final isInactive = widget.isAlreadyAdded || widget.isLocked || !hasStock;
    final opacity = (widget.isAlreadyAdded || !hasStock)
        ? 0.5
        : (widget.isLocked ? 0.38 : 1.0);

    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: isInactive,
        child: ExpandableActionCard(
          isExpandable: hasStock && !widget.isAlreadyAdded,
          isExpanded: widget.selectedQty > 0 ? true : null,
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12.0),
          overline: widget.product.brand?.name != null &&
                  widget.product.brand!.name.isNotEmpty
              ? Text(
                  widget.product.brand!.name.toTitleCase,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
          title: widget.product.name,
          subtitle: (widget.product.model != null &&
                  widget.product.model!.isNotEmpty)
              ? Text(
                  widget.product.model!.toUpperCase(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isAlreadyAdded) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Agregado',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              UomStatusBadge(
                quantity: widget.selectedQty > 0
                    ? widget.selectedQty
                    : widget.product.availableQuantity,
                maxStock: widget.selectedQty > 0
                    ? widget.product.availableQuantity
                    : null,
                showQuantity: true,
                uomAbbreviation: uom,
                uomIconName: widget.product.uomModel?.iconName,
              ),
            ],
          ),
          actions: [
            if (widget.selectedQty > 0)
              TextButton.icon(
                onPressed: () => widget.onQtyChanged(0.0),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Limpiar', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                  foregroundColor: colors.error,
                ),
              ),
          ],
          expandedTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cantidad:',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              EditableQuantityStepper(
                value: widget.selectedQty,
                min: 0,
                max: maxStock > 0 ? maxStock : 0,
                onChanged: widget.onQtyChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
