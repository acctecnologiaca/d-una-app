import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../../../shared/widgets/expandable_action_card.dart';
import '../../../../../shared/widgets/editable_quantity_stepper.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../../shared/widgets/status_badge.dart';
import '../../../../../shared/widgets/uom_status_badge.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../data/models/service_report_item_service.dart';

class ReportAddedServiceCard extends StatelessWidget {
  final ServiceReportItemService service;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onDelete;
  final VoidCallback? onEditSaleDetails;
  final bool isReadOnly;
  final VoidCallback? onTap;

  const ReportAddedServiceCard({
    super.key,
    required this.service,
    required this.onQuantityChanged,
    required this.onDelete,
    this.onEditSaleDetails,
    this.isReadOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isTemporal = service.serviceId == null;

    final category = service.categoryName;
    final executionTime = service.executionTimeLabel;

    return ExpandableActionCard(
      onTap: onTap,
      overline: category != null && category.isNotEmpty
          ? Text(category.toTitleCase)
          : (isTemporal
                ? const Text('Servicio temporal')
                : const Text('Sin categoría')),
      title: service.name,
      subtitle: executionTime != null && executionTime.isNotEmpty
          ? Row(
              children: [
                Icon(Symbols.timer, size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  executionTime,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            )
          : ((service.description != null && service.description!.isNotEmpty)
                ? Text(
                    service.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null),
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12.0),
      trailing: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isTemporal)
              // Source badge
              SizedBox(
                width: 72,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: StatusBadge(
                        backgroundColor: colors.outline,
                        textColor: colors.surface,
                        borderRadius: 4.0,
                        icon: Icon(
                          Symbols.chronic,
                          size: 16,
                          color: colors.surface,
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
                // Total price
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(service.totalPrice),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                // Unit price
                Text(
                  "(${CurrencyFormatter.format(service.unitPrice)}/${service.rateSymbol})",
                  style: TextStyle(fontSize: 12, color: colors.onSurface),
                ),
                const SizedBox(height: 4),
                // UoM Status Badge
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: UomStatusBadge(
                    quantity: service.quantity,
                    uomAbbreviation: service.rateSymbol,
                    uomIconName: service.rateIconName,
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
                      title: 'Eliminar servicio',
                      contentText:
                          '¿Estás seguro de que deseas eliminar este servicio del reporte?',
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
                tooltip: 'Eliminar servicio',
              ),
              if (onEditSaleDetails != null)
                IconButton(
                  icon: const Icon(Symbols.edit_document),
                  color: colors.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                  onPressed: onEditSaleDetails,
                  tooltip: 'Ajustar detalles del servicio',
                ),
            ],
      expandedTrailing: isReadOnly
          ? null
          : EditableQuantityStepper(
              label: 'Cantidad:',
              value: service.quantity,
              min: 1,
              max: 99999,
              onChanged: onQuantityChanged,
            ),
    );
  }
}
