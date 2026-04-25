import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/expandable_action_card.dart';
import '../../../../../shared/widgets/status_badge.dart';
import '../../../../../shared/widgets/uom_status_badge.dart';
import '../../../../../shared/widgets/editable_quantity_stepper.dart';
import '../providers/quote_validation_provider.dart';

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
  final bool isExternalManagement;
  final bool hasOwnInventory;
  final bool hasSupplierInventory;

  // Validation
  final QuoteValidationStatus? validationStatus;
  final String? validationMessage;
  final bool isReadOnly;

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
    this.isExternalManagement = false,
    this.hasOwnInventory = false,
    this.hasSupplierInventory = false,
    this.validationStatus,
    this.validationMessage,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasError =
        validationStatus != null &&
        validationStatus != QuoteValidationStatus.ok;

    return ExpandableActionCard(
      backgroundColor: hasError
          ? colors.errorContainer.withValues(alpha: 0.8)
          : null,
      overline: brand != null ? Text(brand!) : null,
      title: name,
      subtitle: (model != null && model!.isNotEmpty)
          ? Text(model!.toUpperCase())
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
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
              // Warning Icon
              if (hasError) ...[
                Tooltip(
                  message: validationMessage ?? 'Problema con este producto',
                  child: Icon(
                    Symbols.warning,
                    size: 20,
                    color: Colors.amber.shade700,
                    fill: 1,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              /* if (hasOwnInventory) ...[
                Tooltip(
                  message: 'Inventario propio',
                  child: Icon(
                    Symbols.inventory_2, // Icono de caja sólida
                    size: 20,
                    color: colors.primary, // Color principal
                    fill: 1,
                  ),
                ),
                const SizedBox(width: 8),
              ],*/
              if (isTemporal) ...[
                Tooltip(
                  message: validationMessage ?? 'Producto temporal',
                  child: Icon(
                    Symbols.chronic,
                    size: 20,
                    color: colors.outline,
                    fill: 1,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              if (isExternalManagement) ...[
                Tooltip(
                  message: validationMessage ?? 'Proveedor externo',
                  child: Icon(
                    Symbols.outbound_sharp,
                    size: 20,
                    color: colors.onSurfaceVariant,
                    fill: 1,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              if (hasOwnInventory) ...[
                StatusBadge(
                  backgroundColor: colors.primary,
                  textColor: colors.onPrimary,
                  borderRadius: 4.0,
                  icon: Icon(
                    Symbols.inventory_2,
                    size: 15,
                    color: colors.onPrimary,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              /*if (hasSupplierInventory) ...[
                Tooltip(
                  message: 'Proveedor afiliado',
                  child: Icon(
                    Symbols.warehouse, // Icono de almacén
                    size: 20,
                    color: colors
                        .onTertiaryContainer, // Color terciario (que asocio a proveedores)
                    fill: 0,
                  ),
                ),
                const SizedBox(width: 8),
              ],*/
              if (hasSupplierInventory) ...[
                StatusBadge(
                  backgroundColor: colors.tertiaryContainer,
                  textColor: colors.onTertiaryContainer,
                  borderRadius: 4.0,
                  icon: Icon(
                    Symbols.warehouse,
                    size: 16,
                    color: colors.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Stock Badge
              UomStatusBadge(
                quantity: totalQuantity,
                uomAbbreviation: uom,
                maxStock: totalAvailableStock,
                backgroundColor: hasError ? Colors.white : null,
                textColor: hasError ? colors.error : null,
              ),
            ],
          ),
        ],
      ),
      actions: isReadOnly ? [] : [
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
                    '¿Estás seguro de que deseas eliminar este producto de la cotización?',
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
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
      expandedTrailing: isReadOnly
          ? null
          : EditableQuantityStepper(
              label: 'Cantidad:',
              value: totalQuantity,
              min: 1, // Minimum 1, otherwise they should delete it
              max: totalAvailableStock,
              onChanged: onQuantityChanged,
            ),
    );
  }
}
