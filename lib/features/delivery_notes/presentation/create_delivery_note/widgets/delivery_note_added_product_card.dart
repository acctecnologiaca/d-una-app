import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';
import 'package:d_una_app/shared/widgets/expandable_action_card.dart';
import 'package:d_una_app/shared/widgets/editable_quantity_stepper.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/uom_status_badge.dart';
import 'package:d_una_app/features/delivery_notes/domain/models/delivery_note_item_model.dart';

class DeliveryNoteAddedProductCard extends StatelessWidget {
  final DeliveryNoteItemModel item;
  final VoidCallback? onDelete;
  final VoidCallback? onEditDetails;
  final VoidCallback? onManageSerials;
  final ValueChanged<double>? onQuantityChanged;
  final VoidCallback? onTap;
  final bool isReadOnly;
  final bool isEditable;
  final Color? backgroundColor;
  final double? availableStock;

  const DeliveryNoteAddedProductCard({
    super.key,
    required this.item,
    this.onDelete,
    this.onEditDetails,
    this.onManageSerials,
    this.onQuantityChanged,
    this.onTap,
    this.isReadOnly = false,
    this.isEditable = true,
    this.backgroundColor,
    this.availableStock,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasMissing = item.hasMissingSerials;

    return ExpandableActionCard(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      isExpandable: !isReadOnly,
      onTap: onTap,
      backgroundColor: backgroundColor ??
          (hasMissing ? colors.errorContainer.withValues(alpha: 0.8) : null),
      overline: item.brand != null && item.brand!.isNotEmpty
          ? Text(item.brand!.toTitleCase)
          : null,
      title: item.name.toTitleCase,
      subtitle: (item.model != null && item.model!.isNotEmpty)
          ? Text(item.model!.toUpperCase())
          : null,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasMissing) ...[
                Image.asset(
                  'assets/icons/no_barcode.png',
                  width: 20,
                  height: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
              ],
              UomStatusBadge(
                quantity: item.quantity,
                maxStock: availableStock,
                uomAbbreviation: item.uom,
                backgroundColor: hasMissing ? Colors.white : null,
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (isEditable && !isReadOnly && onDelete != null)
          IconButton(
            icon: const Icon(Symbols.delete, fontWeight: FontWeight.w500),
            color: colors.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            tooltip: 'Eliminar producto',
            onPressed: () {
              CustomDialog.show(
                context: context,
                dialog: CustomDialog.destructive(
                  title: '¿Eliminar producto?',
                  contentText:
                      '¿Estás seguro de que deseas eliminar este producto de la nota de entrega?',
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        onDelete!();
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
          ),
        if (!isReadOnly && onEditDetails != null)
          IconButton(
            icon: const Icon(Symbols.tune),
            color: colors.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            tooltip: 'Ajustar detalles del producto',
            onPressed: onEditDetails,
          ),
        if (!isReadOnly && item.requiresSerials && onManageSerials != null)
          IconButton(
            icon: const Icon(Symbols.barcode),
            color: hasMissing ? colors.error : colors.onSurfaceVariant,
            visualDensity: VisualDensity.compact,
            tooltip: 'Gestionar seriales',
            onPressed: onManageSerials,
          ),
      ],
      expandedTrailing: (isReadOnly || !isEditable || onQuantityChanged == null)
          ? null
          : EditableQuantityStepper(
              label: 'Cantidad:',
              value: item.quantity,
              min: 1,
              max: availableStock != null && availableStock! > 0
                  ? (availableStock! > item.quantity
                      ? availableStock!
                      : item.quantity)
                  : 99999,
              onChanged: onQuantityChanged!,
            ),
    );
  }
}
