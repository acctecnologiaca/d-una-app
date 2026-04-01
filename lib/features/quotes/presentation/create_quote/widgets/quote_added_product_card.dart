import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/expandable_action_card.dart';
import '../../../../../shared/widgets/status_badge.dart';
import '../../../../../shared/widgets/uom_status_badge.dart';
import '../../../../../shared/widgets/editable_quantity_stepper.dart';

class QuoteAddedProductCard extends StatelessWidget {
  final String name;
  final String? brand;
  final String? model;
  final double subtotal; // Changed from salePrice
  final double totalQuantity;
  final double totalAvailableStock;
  final String uom;

  // Actions
  final VoidCallback onDelete;
  final VoidCallback onEditPrice;
  final VoidCallback onEditSources;
  final VoidCallback? onEditTemporal;
  final ValueChanged<double> onQuantityChanged;
  final bool isTemporal;

  const QuoteAddedProductCard({
    super.key,
    required this.name,
    this.brand,
    this.model,
    required this.subtotal,
    required this.totalQuantity,
    required this.totalAvailableStock,
    required this.uom,
    required this.onDelete,
    required this.onEditPrice,
    required this.onEditSources,
    this.onEditTemporal,
    required this.onQuantityChanged,
    this.isTemporal = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ExpandableActionCard(
      overline: brand != null ? Text(brand!.toTitleCase) : null,
      title: name.toTitleCase,
      subtitle: (model != null && model!.isNotEmpty) ? Text(model!.toUpperCase()) : null,
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12.0),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Sale Price
          Text(
            CurrencyFormatter.format(subtotal),
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
              // Stock Badge
              UomStatusBadge(
                quantity: totalQuantity,
                uomAbbreviation: uom,
                maxStock: totalAvailableStock,
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
                title: const Text('Eliminar producto'),
                content: const Text(
                  '¿Estás seguro de que deseas eliminar este producto de la cotización?',
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
          tooltip: 'Eliminar producto',
        ),
        if (!isTemporal) ...[
          IconButton(
            icon: const Icon(Symbols.warehouse),
            color: colors.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            onPressed: onEditSources,
            tooltip: 'Cambiar sucursales/proveedores',
          ),
          IconButton(
            icon: const Icon(Symbols.sell),
            color: colors.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            onPressed: onEditPrice,
            tooltip: 'Ajustar detalles de venta',
          ),
        ] else if (onEditTemporal != null) ...[
          IconButton(
            icon: const Icon(Symbols.edit_document),
            color: colors.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            onPressed: onEditTemporal,
            tooltip: 'Editar producto temporal',
          ),
        ],
      ],
      expandedTrailing: EditableQuantityStepper(
        label: 'Cantidad:',
        value: totalQuantity,
        min: 1, // Minimum 1, otherwise they should delete it
        max: totalAvailableStock,
        onChanged: onQuantityChanged,
      ),
    );
  }
}
