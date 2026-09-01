import 'package:flutter/material.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/expandable_action_card.dart';
import '../../../../shared/widgets/editable_quantity_stepper.dart';
import '../../../../shared/widgets/uom_status_badge.dart';
import '../../../portfolio/data/models/product_model.dart';

class PurchaseProductSelectionCard extends StatefulWidget {
  final Product product;
  final double selectedQty;
  final ValueChanged<double> onQtyChanged;
  final bool isLocked;
  final bool isAlreadyAdded;

  const PurchaseProductSelectionCard({
    super.key,
    required this.product,
    required this.selectedQty,
    required this.onQtyChanged,
    this.isLocked = false,
    this.isAlreadyAdded = false,
  });

  @override
  State<PurchaseProductSelectionCard> createState() =>
      _PurchaseProductSelectionCardState();
}

class _PurchaseProductSelectionCardState
    extends State<PurchaseProductSelectionCard> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final uom = widget.product.uom ?? 'ud.';
    final isInactive = widget.isAlreadyAdded || widget.isLocked;
    final opacity = widget.isAlreadyAdded
        ? 0.5
        : (widget.isLocked ? 0.38 : 1.0);

    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: isInactive,
        child: ExpandableActionCard(
          isExpandable: true,
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
              Text(
                uom.isNotEmpty
                    ? '${CurrencyFormatter.format(widget.product.averageCost)}/$uom'
                    : CurrencyFormatter.format(widget.product.averageCost),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              UomStatusBadge(
                quantity: widget.selectedQty,
                showQuantity: widget.selectedQty > 0,
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
                max: 99999,
                onChanged: widget.onQtyChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
