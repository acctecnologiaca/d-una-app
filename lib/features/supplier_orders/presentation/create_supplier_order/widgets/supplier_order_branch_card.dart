import 'package:flutter/material.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/dynamic_material_symbol.dart';
import '../../../../../shared/widgets/editable_quantity_stepper.dart';
import '../../../../../core/utils/time_formatter.dart';

class SupplierOrderBranchCard extends StatefulWidget {
  final String branchCity;
  final double price;
  final int stock;
  final String uom;
  final String? uomIconName;
  final DateTime? lastUpdated;
  final double selectedQty;
  final ValueChanged<double> onQtyChanged;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  const SupplierOrderBranchCard({
    super.key,
    required this.branchCity,
    required this.price,
    required this.stock,
    required this.uom,
    this.uomIconName,
    this.lastUpdated,
    required this.selectedQty,
    required this.onQtyChanged,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  @override
  State<SupplierOrderBranchCard> createState() =>
      _SupplierOrderBranchCardState();
}

class _SupplierOrderBranchCardState extends State<SupplierOrderBranchCard> {
  bool? _isExpandedManual;

  @override
  void didUpdateWidget(SupplierOrderBranchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedQty == 0 && widget.selectedQty > 0) {
      _isExpandedManual = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasStock = widget.stock > 0;
    final isSelected = widget.selectedQty > 0;
    final showStepper = _isExpandedManual ?? isSelected;

    // Checkbox state: true (all selected), false (none), null (partial)
    bool? checkboxState;
    if (widget.selectedQty == 0) {
      checkboxState = false;
    } else if (widget.selectedQty >= widget.stock) {
      checkboxState = true;
    } else {
      checkboxState = null;
    }

    final stockColor = hasStock
        ? colors.onSecondaryContainer
        : colors.onErrorContainer;

    final stockBgColor = hasStock
        ? colors.secondaryContainer
        : colors.errorContainer;

    final formattedStock = widget.stock.toString();
    final formattedSelected =
        widget.selectedQty.truncateToDouble() == widget.selectedQty
        ? widget.selectedQty.toInt().toString()
        : widget.selectedQty.toStringAsFixed(2);

    final stockText = hasStock
        ? (isSelected
              ? '$formattedSelected/$formattedStock ${widget.uom}'
              : '$formattedStock ${widget.uom}')
        : 'Sin stock';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: isSelected
          ? colors.primaryContainer.withValues(alpha: 0.15)
          : colors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpandedManual = !showStepper;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.branchCity,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.uom.isNotEmpty
                            ? '${CurrencyFormatter.format(widget.price)}/${widget.uom}'
                            : CurrencyFormatter.format(widget.price),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: stockBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.uomIconName != null) ...[
                              DynamicMaterialSymbol(
                                symbolName: widget.uomIconName!,
                                size: 14,
                                color: stockColor,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              stockText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: stockColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          final isOutdated = TimeFormatter.isOutdated(widget.lastUpdated);
                          final iconColor = isOutdated ? colors.error : colors.onSurfaceVariant;
                          final displayText = isOutdated
                              ? 'Más de 7 días'
                              : TimeFormatter.formatRelative(widget.lastUpdated);

                          return Tooltip(
                            message: 'Última actualización',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 11,
                                  color: iconColor,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  displayText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: iconColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (showStepper) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Row(
                children: [
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
                                    widget.onSelectAll();
                                  } else {
                                    widget.onDeselectAll();
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        checkboxState == null ? 'Parcial' : 'Todos',
                        style: TextStyle(
                          fontSize: 14,
                          color: !hasStock
                              ? colors.onSurfaceVariant.withValues(alpha: 0.38)
                              : colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
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
                    max: widget.stock.toDouble(),
                    onChanged: (val) {
                      if (hasStock) {
                        widget.onQtyChanged(val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
