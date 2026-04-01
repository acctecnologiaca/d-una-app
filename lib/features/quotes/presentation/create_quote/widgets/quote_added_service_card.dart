import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/expandable_action_card.dart';
import '../../../../../shared/widgets/status_badge.dart';
import '../../../../../shared/widgets/uom_status_badge.dart';
import '../../../../../shared/widgets/editable_quantity_stepper.dart';

class QuoteAddedServiceCard extends StatelessWidget {
  final String name;
  final String? category;
  final double subtotal; // This could be the total for this line or unit price
  final double quantity;
  final String rateSuffix;
  final String? executionTime; // Can be null if time-based rate

  // Actions
  final VoidCallback onDelete;
  final VoidCallback onEditSaleDetails;
  final ValueChanged<double> onQuantityChanged;
  final bool isTemporal;

  const QuoteAddedServiceCard({
    super.key,
    required this.name,
    this.category,
    required this.subtotal,
    required this.quantity,
    required this.rateSuffix,
    this.executionTime,
    required this.onDelete,
    required this.onEditSaleDetails,
    required this.onQuantityChanged,
    this.isTemporal = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ExpandableActionCard(
      overline: category != null
          ? Text(category!.toTitleCase)
          : const Text('Sin categoría'),
      title: name.toTitleCase,
      subtitle: executionTime != null
          ? Text(
              'Entrega: $executionTime',
              style: TextStyle(color: colors.onSurfaceVariant),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12.0),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sale Price (Total for this item)
          Text(
            CurrencyFormatter.format(subtotal * quantity),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Badges row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Temp badge
              if (isTemporal) ...[
                StatusBadge(
                  backgroundColor: colors.tertiaryContainer,
                  textColor: colors.onTertiaryContainer,
                  text: 'Temp',
                  icon: Icon(Symbols.edit_note, size: 14, color: colors.onTertiaryContainer),
                ),
                const SizedBox(width: 6),
              ],
              // Quantity Badge
              UomStatusBadge(
                quantity: quantity,
                uomAbbreviation: rateSuffix.replaceAll('/', ''),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Symbols.delete),
          color: colors.onSurfaceVariant,
          visualDensity: VisualDensity.compact,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Eliminar servicio'),
                content: const Text(
                  '¿Estás seguro de que deseas eliminar este servicio de la cotización?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colors.error,
                    ),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );
          },
          tooltip: 'Eliminar servicio',
        ),
        IconButton(
          icon: const Icon(Symbols.edit_document),
          color: colors.onSurfaceVariant,
          visualDensity: VisualDensity.compact,
          onPressed: onEditSaleDetails,
          tooltip: 'Ajustar detalles del servicio',
        ),
      ],
      expandedTrailing: EditableQuantityStepper(
        label: 'Cantidad:',
        value: quantity,
        min: 1, // Minimum 1, otherwise they should delete it
        max: 99999, // Practically unlimited for services
        onChanged: onQuantityChanged,
      ),
    );
  }
}
