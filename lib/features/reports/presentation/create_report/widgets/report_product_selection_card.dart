import 'package:flutter/material.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/expandable_action_card.dart';
import '../../../../../shared/widgets/editable_quantity_stepper.dart';
import '../../../../../shared/widgets/uom_status_badge.dart';
import '../../../../portfolio/data/models/product_model.dart';

class ReportProductSelectionCard extends StatefulWidget {
  final Product product;
  final double selectedQty;
  final ValueChanged<double> onQtyChanged;
  final bool isLocked;
  final bool isAlreadyInReport;

  const ReportProductSelectionCard({
    super.key,
    required this.product,
    required this.selectedQty,
    required this.onQtyChanged,
    this.isLocked = false,
    this.isAlreadyInReport = false,
  });

  @override
  State<ReportProductSelectionCard> createState() =>
      _ReportProductSelectionCardState();
}

class _ReportProductSelectionCardState
    extends State<ReportProductSelectionCard> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final uom = widget.product.uom ?? widget.product.uomModel?.symbol ?? 'ud.';
    final physicalStock = widget.product.inventoryQuantity;
    final effectiveAvailable = widget.product.availableQuantity;
    final isReservedByOthers = physicalStock > 0 && effectiveAvailable <= 0;
    final hasStock = effectiveAvailable > 0;
    final maxStock = effectiveAvailable;

    // Checkbox state for expanded row
    bool? checkboxState;
    if (widget.selectedQty == 0) {
      checkboxState = false;
    } else if (hasStock && widget.selectedQty == maxStock) {
      checkboxState = true;
    } else {
      checkboxState = null; // Indeterminate / Parcial
    }

    final isInactive = widget.isAlreadyInReport || widget.isLocked || !hasStock;
    final opacity = (widget.isAlreadyInReport || !hasStock)
        ? 0.5
        : (widget.isLocked ? 0.38 : 1.0);

    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: isInactive,
        child: ExpandableActionCard(
          isExpandable: hasStock,
          isExpanded: widget.selectedQty > 0 ? true : null,
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12.0),
          overline: widget.product.brand?.name != null &&
                  widget.product.brand!.name.isNotEmpty
              ? Text(
                  widget.product.brand!.name,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
          title: widget.product.name,
          subtitle: (widget.product.model != null &&
                      widget.product.model!.isNotEmpty) ||
                  widget.product.reservedQuantity > 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.product.model != null &&
                        widget.product.model!.isNotEmpty)
                      Text(
                        widget.product.model!.toUpperCase(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    if (isReservedByOthers) ...[
                      if (widget.product.model != null &&
                          widget.product.model!.isNotEmpty)
                        const SizedBox(height: 2),
                      Text(
                        'Todo el inventario propio está reservado en cotizaciones aprobadas o notas de entrega no finalizadas.',
                        style: TextStyle(
                          color: colors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else if (widget.product.reservedQuantity > 0) ...[
                      if (widget.product.model != null &&
                          widget.product.model!.isNotEmpty)
                        const SizedBox(height: 2),
                      Text(
                        'Hay ${effectiveAvailable.toStringAsFixed(effectiveAvailable.truncateToDouble() == effectiveAvailable ? 0 : 2)} $uom disponibles de ${physicalStock.toStringAsFixed(physicalStock.truncateToDouble() == physicalStock ? 0 : 2)} en inventario propio.',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
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
                quantity: widget.selectedQty > 0
                    ? widget.selectedQty
                    : (isReservedByOthers ? physicalStock : effectiveAvailable),
                maxStock: widget.selectedQty > 0 ? effectiveAvailable : null,
                uomAbbreviation: uom,
                uomIconName: widget.product.uomModel?.iconName,
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: checkboxState,
                    tristate: true,
                    activeColor: colors.primary,
                    side: BorderSide(
                      color: checkboxState == false
                          ? colors.onSurfaceVariant
                          : colors.primary,
                      width: 2,
                    ),
                    onChanged: !hasStock
                        ? null
                        : (bool? newValue) {
                            if (checkboxState == false) {
                              widget.onQtyChanged(maxStock);
                            } else {
                              widget.onQtyChanged(0.0);
                            }
                          },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  checkboxState == null ? 'Parcial' : 'Todos',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
                max: maxStock > 0 ? maxStock : 0.0,
                onChanged: widget.onQtyChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
