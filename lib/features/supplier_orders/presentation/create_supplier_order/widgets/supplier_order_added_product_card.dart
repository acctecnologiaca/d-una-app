import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/expandable_action_card.dart';
import '../../../../../shared/widgets/uom_status_badge.dart';
import '../../../../../shared/widgets/editable_quantity_stepper.dart';

class SupplierOrderAddedProductCard extends StatelessWidget {
  final String name;
  final String? brand;
  final String? model;
  final double totalQuantity;
  final double averageUnitPrice;
  final double totalCost;
  final String uom;
  final String? uomIconName;
  final double? totalAvailableStock;

  // Alerts
  final bool hasPriceIncrease;
  final bool isOutOfStock;
  final bool hasLowStock;

  // Actions
  final VoidCallback onDelete;
  final VoidCallback onEditSources;
  final ValueChanged<double> onQuantityChanged;
  final bool isReadOnly;

  const SupplierOrderAddedProductCard({
    super.key,
    required this.name,
    this.brand,
    this.model,
    required this.totalQuantity,
    required this.averageUnitPrice,
    required this.totalCost,
    required this.uom,
    this.uomIconName,
    required this.totalAvailableStock,
    required this.hasPriceIncrease,
    required this.isOutOfStock,
    required this.hasLowStock,
    required this.onDelete,
    required this.onEditSources,
    required this.onQuantityChanged,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasError = isOutOfStock || hasLowStock || hasPriceIncrease;

    return ExpandableActionCard(
      backgroundColor: hasError
          ? colors.errorContainer.withValues(alpha: 0.8)
          : null,
      overline: brand != null && brand!.isNotEmpty ? Text(brand!) : null,
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
            // Alerts Column
            if (hasError)
              SizedBox(
                width: 32,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasPriceIncrease)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Tooltip(
                          message: 'El precio de costo aumentó',
                          child: Image.asset(
                            'assets/icons/price_increase.png',
                            width: 18,
                            height: 18,
                          ),
                        ),
                      ),
                    if (isOutOfStock || hasLowStock)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Tooltip(
                          message: isOutOfStock
                              ? 'Sin stock disponible'
                              : 'Stock insuficiente',
                          child: Image.asset(
                            isOutOfStock
                                ? 'assets/icons/stock_unavailable.png'
                                : 'assets/icons/stock_down.png',
                            width: 18,
                            height: 18,
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
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(totalCost),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  "(${CurrencyFormatter.format(averageUnitPrice)}/$uom)",
                  style: TextStyle(fontSize: 12, color: colors.onSurface),
                ),
                const SizedBox(height: 4),

                // Stock / Quantity Badge
                UomStatusBadge(
                  quantity: totalQuantity,
                  uomAbbreviation: uom,
                  uomIconName: uomIconName,
                  maxStock: isOutOfStock ? 0 : totalAvailableStock,
                  backgroundColor: hasError ? colors.surface : null,
                  textColor: hasError && !hasPriceIncrease
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
                          '¿Estás seguro de que deseas eliminar este producto de la orden de compra?',
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
              IconButton(
                icon: const Icon(Symbols.warehouse),
                color: colors.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                onPressed: onEditSources,
                tooltip: 'Cambiar sucursales/cantidades',
              ),
            ],
      expandedTrailing: isReadOnly
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                EditableQuantityStepper(
                  label: 'Cantidad:',
                  value: totalQuantity,
                  min: 1, // Minimum 1
                  max: totalAvailableStock ?? double.infinity,
                  onChanged: onQuantityChanged,
                ),
              ],
            ),
    );
  }
}
