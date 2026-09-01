import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../shared/utils/currency_formatter.dart';
import 'package:d_una_app/features/purchases/data/models/purchase_item_product.dart';
import 'package:d_una_app/shared/widgets/expandable_action_card.dart';
import 'package:d_una_app/shared/widgets/editable_quantity_stepper.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/uom_status_badge.dart';

class PurchaseAddedProductCard extends StatelessWidget {
  final PurchaseItemProduct item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onAddSerials;
  final ValueChanged<double> onQuantityChanged;
  final bool isReadOnly;
  final bool isEditable;
  final bool hasError;
  final Color? backgroundColor;

  const PurchaseAddedProductCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onEdit,
    required this.onAddSerials,
    required this.onQuantityChanged,
    this.isReadOnly = false,
    this.isEditable = true,
    this.hasError = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ExpandableActionCard(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      isExpandable: !isReadOnly,
      backgroundColor: backgroundColor ?? (hasError
          ? colors.errorContainer.withValues(alpha: 0.8)
          : null),
      overline: item.brand != null ? Text(item.brand!.toTitleCase) : null,
      title: item.name.toTitleCase,
      subtitle: (item.model != null && item.model!.isNotEmpty)
          ? Text(item.model!.toUpperCase())
          : null,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.format(item.subtotal),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          Text(
            "(${CurrencyFormatter.format(item.subtotal / item.quantity)}/${item.uom})",
            style: TextStyle(fontSize: 12, color: colors.onSurface),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasError) ...[
                Image.asset(
                  'assets/icons/no_barcode.png',
                  width: 20,
                  height: 20,
                  color:
                      colors.onSurfaceVariant, // Mismo estilo que en la lista
                ),
                const SizedBox(width: 4),
              ],
              UomStatusBadge(
                quantity: item.quantity,
                uomAbbreviation: item.uom,
                backgroundColor: hasError ? Colors.white : null,
                //textColor: hasError ? colors.error : null,
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (isEditable && !isReadOnly)
          IconButton(
            icon: const Icon(Symbols.delete, fontWeight: FontWeight.w500),
            color: colors.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            onPressed: () {
              CustomDialog.show(
                context: context,
                dialog: CustomDialog.destructive(
                  title: '¿Eliminar producto?',
                  contentText:
                      '¿Estás seguro de que deseas eliminar este producto de la compra?',
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
        if (!isReadOnly)
          IconButton(
            icon: const Icon(Symbols.sell),
            color: colors.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            tooltip: 'Ajustar detalles de compra',
          ),
        if (!isReadOnly)
          IconButton(
            icon: const Icon(Symbols.barcode),
            color: colors.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            onPressed: onAddSerials,
            tooltip: 'Gestionar seriales',
          ),
      ],
      expandedTrailing: (isReadOnly || !isEditable)
          ? null
          : EditableQuantityStepper(
              label: 'Cantidad:',
              value: item.quantity,
              min: 1,
              max: 99999,
              onChanged: onQuantityChanged,
            ),
    );
  }
}
