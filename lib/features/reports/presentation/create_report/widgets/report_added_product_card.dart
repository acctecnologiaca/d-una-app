import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../shared/widgets/expandable_action_card.dart';
import '../../../../../shared/widgets/editable_quantity_stepper.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../../shared/widgets/status_badge.dart';
import '../../../../../shared/widgets/uom_status_badge.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../data/models/service_report_item_product.dart';

class ReportAddedProductCard extends StatelessWidget {
  final ServiceReportItemProduct product;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onDelete;
  final VoidCallback? onEditTemporal;
  final VoidCallback? onEditPrice;
  final bool isReadOnly;
  final VoidCallback? onTap;

  const ReportAddedProductCard({
    super.key,
    required this.product,
    required this.onQuantityChanged,
    required this.onDelete,
    this.onEditTemporal,
    this.onEditPrice,
    this.isReadOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isTemporal = product.sourceType == ReportProductSourceType.temporal;

    return ExpandableActionCard(
      onTap: onTap,
      overline: product.brand != null && product.brand!.isNotEmpty
          ? Text(product.brand!)
          : null,
      title: product.name,
      subtitle: (product.model != null && product.model!.isNotEmpty)
          ? Text(product.model!.toUpperCase())
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12.0),
      trailing: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Source badge (Own inventory vs Temporal)
            SizedBox(
              width: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: StatusBadge(
                      backgroundColor: isTemporal
                          ? colors.outline
                          : colors.primary,
                      textColor: isTemporal ? colors.surface : colors.onPrimary,
                      borderRadius: 4.0,
                      icon: Icon(
                        isTemporal ? Symbols.chronic : Symbols.inventory_2,
                        size: 16,
                        color: isTemporal ? colors.surface : colors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Total subtotal price
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(product.totalPrice),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                // Unit price
                Text(
                  "(${CurrencyFormatter.format(product.unitPrice)}/${product.uom})",
                  style: TextStyle(fontSize: 12, color: colors.onSurface),
                ),
                const SizedBox(height: 4),
                // UoM Status Badge
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: UomStatusBadge(
                    quantity: product.quantity,
                    uomAbbreviation: product.uom,
                    uomIconName: product.uomIconName,
                    maxStock: product.availableStock ?? product.quantity,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: isReadOnly
          ? []
          : [
              IconButton(
                icon: const Icon(Symbols.delete),
                color: colors.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  CustomDialog.show(
                    context: context,
                    dialog: CustomDialog.destructive(
                      title: 'Eliminar producto',
                      contentText:
                          '¿Estás seguro de que deseas eliminar este producto del reporte?',
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context, rootNavigator: true).pop(),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                            onDelete();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.error,
                            foregroundColor: colors.onError,
                          ),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Eliminar producto',
              ),
              if (!isTemporal && onEditPrice != null)
                IconButton(
                  icon: const Icon(Symbols.sell),
                  color: colors.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                  onPressed: onEditPrice,
                  tooltip: 'Ajustar detalles de venta',
                ),
              if (isTemporal && onEditTemporal != null)
                IconButton(
                  icon: const Icon(Symbols.edit_document),
                  color: colors.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                  onPressed: onEditTemporal,
                  tooltip: 'Editar producto temporal',
                ),
            ],
      expandedTrailing: isReadOnly
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                EditableQuantityStepper(
                  label: 'Cantidad:',
                  value: product.quantity,
                  min: 1,
                  max:
                      product.availableStock != null &&
                          product.availableStock! > 0
                      ? product.availableStock!
                      : 99999,
                  onChanged: onQuantityChanged,
                ),
              ],
            ),
    );
  }
}
