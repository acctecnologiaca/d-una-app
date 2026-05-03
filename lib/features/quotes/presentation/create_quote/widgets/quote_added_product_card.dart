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
  final String? uomIconName;

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
  final List<QuoteValidationStatus> alerts;
  final bool isReadOnly;
  final VoidCallback? onTap;

  const QuoteAddedProductCard({
    super.key,
    required this.name,
    this.brand,
    this.model,
    required this.subtotal,
    required this.totalQuantity,
    required this.totalAvailableStock,
    required this.uom,
    this.uomIconName,
    required this.onDelete,
    required this.onEditPrice,
    required this.onEditSources,
    this.onEditTemporal,
    required this.onQuantityChanged,
    this.isTemporal = false,
    this.isExternalManagement = false,
    this.hasOwnInventory = false,
    this.hasSupplierInventory = false,
    this.alerts = const [],
    this.isReadOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasError = alerts.isNotEmpty;

    return ExpandableActionCard(
      backgroundColor: hasError
          ? colors.errorContainer.withValues(alpha: 0.8)
          : null,
      onTap: onTap,
      overline: brand != null ? Text(brand!) : null,
      title: name,
      subtitle: (model != null && model!.isNotEmpty)
          ? Text(model!.toUpperCase())
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12.0),
      trailing: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 64,
              child: Row(
                children: [
                  // Columna 1: Alertas
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price Alert Icon
                        if (alerts.contains(
                          QuoteValidationStatus.priceIncreased,
                        )) ...[
                          const SizedBox(height: 2),
                          Tooltip(
                            message: 'El precio de costo aumentó',
                            child: Image.asset(
                              'assets/icons/price_increase.png',
                              width: 20,
                              height: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],

                        // Stock Alert Icon
                        if (alerts.contains(QuoteValidationStatus.outOfStock) ||
                            alerts.contains(
                              QuoteValidationStatus.lowStock,
                            )) ...[
                          const SizedBox(height: 2),
                          Tooltip(
                            message:
                                alerts.contains(
                                  QuoteValidationStatus.outOfStock,
                                )
                                ? 'Sin stock disponible'
                                : 'Stock insuficiente',
                            child: Image.asset(
                              alerts.contains(QuoteValidationStatus.outOfStock)
                                  ? 'assets/icons/stock_unavailable.png'
                                  : 'assets/icons/stock_down.png',
                              width: 20,
                              height: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],

                        // Missing Product Icon
                        if (alerts.contains(QuoteValidationStatus.missing)) ...[
                          const SizedBox(height: 2),
                          Tooltip(
                            message: 'Producto ya no disponible',
                            child: Icon(
                              Symbols.warning,
                              size: 20,
                              color: Colors.amber.shade700,
                              fill: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Columna 2: Estados/Origen
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isTemporal) ...[
                          const SizedBox(height: 2),
                          StatusBadge(
                            backgroundColor: colors.outline,
                            textColor: colors.surface,
                            borderRadius: 4.0,
                            icon: Icon(
                              Symbols.chronic,
                              size: 16,
                              color: colors.surface,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],

                        if (isExternalManagement) ...[
                          const SizedBox(height: 2),
                          StatusBadge(
                            backgroundColor: colors.onSurfaceVariant,
                            textColor: colors.surface,
                            borderRadius: 4.0,
                            icon: Icon(
                              Symbols.outbound,
                              size: 16,
                              color: colors.surface,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],

                        if (hasSupplierInventory) ...[
                          const SizedBox(height: 2),
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
                          const SizedBox(height: 2),
                        ],

                        if (hasOwnInventory) ...[
                          const SizedBox(height: 2),
                          StatusBadge(
                            backgroundColor: colors.primary,
                            textColor: colors.onPrimary,
                            borderRadius: 4.0,
                            icon: Icon(
                              Symbols.inventory_2,
                              size: 16,
                              color: colors.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ],
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
                // Sale Price
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(subtotal),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  "(${CurrencyFormatter.format(subtotal / totalQuantity)}/$uom)",
                  style: TextStyle(fontSize: 12, color: colors.onSurface),
                ),
                const SizedBox(height: 4),

                // Stock Badge
                UomStatusBadge(
                  quantity: totalQuantity,
                  uomAbbreviation: uom,
                  uomIconName: uomIconName,
                  maxStock:
                      ((isTemporal || isExternalManagement) &&
                          !hasOwnInventory &&
                          !hasSupplierInventory)
                      ? totalQuantity
                      : totalAvailableStock,
                  backgroundColor: (hasError) ? colors.surface : null,
                  textColor:
                      (hasError &&
                          !alerts.contains(
                            QuoteValidationStatus.priceIncreased,
                          ))
                      ? colors.error
                      : null,
                ),
                const SizedBox(height: 2),
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
