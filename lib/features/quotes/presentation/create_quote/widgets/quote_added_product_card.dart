import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/standard_list_item.dart';

class QuoteAddedProductCard extends StatefulWidget {
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
  State<QuoteAddedProductCard> createState() => _QuoteAddedProductCardState();
}

class _QuoteAddedProductCardState extends State<QuoteAddedProductCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    String formatValue(double value) {
      if (value == double.infinity || value >= 99999.0) return '∞';
      return value.truncateToDouble() == value
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
    }

    final String stockText =
        '${formatValue(widget.totalQuantity)}/${formatValue(widget.totalAvailableStock)} ${widget.uom}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          StandardListItem(
            padding: const EdgeInsets.symmetric(
              horizontal: 0.0,
              vertical: 12.0,
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            overline: widget.brand != null
                ? Text(widget.brand!.toTitleCase)
                : null,
            title: widget.name.toTitleCase,
            subtitle: (widget.model != null && widget.model!.isNotEmpty)
                ? Text(widget.model!.toUpperCase())
                : null,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Sale Price
                Text(
                  CurrencyFormatter.format(widget.subtotal),
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
                    if (widget.isTemporal) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Symbols.edit_note,
                              size: 14,
                              color: colors.onTertiaryContainer,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Temp',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.onTertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Stock Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Symbols.package_2,
                            size: 14,
                            color: colors.onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            stockText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0),
                        child: Divider(height: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 0,
                          right: 0,
                          top: 12,
                          bottom: 12,
                        ),
                        child: Row(
                          children: [
                            // Actions: Delete, Warehouse, Sell
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
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          widget.onDelete();
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
                            if (!widget.isTemporal) ...[
                              IconButton(
                                icon: const Icon(Symbols.warehouse),
                                color: colors.onSurfaceVariant,
                                visualDensity: VisualDensity.compact,
                                onPressed: widget.onEditSources,
                                tooltip: 'Cambiar sucursales/proveedores',
                              ),
                              IconButton(
                                icon: const Icon(Symbols.sell),
                                color: colors.onSurfaceVariant,
                                visualDensity: VisualDensity.compact,
                                onPressed: widget.onEditPrice,
                                tooltip: 'Ajustar detalles de venta',
                              ),
                            ] else if (widget.onEditTemporal != null) ...[
                              IconButton(
                                icon: const Icon(Symbols.edit_document),
                                color: colors.onSurfaceVariant,
                                visualDensity: VisualDensity.compact,
                                onPressed: widget.onEditTemporal,
                                tooltip: 'Editar producto temporal',
                              ),
                            ],
                            const Spacer(),
                            // Dynamic Stepper
                            _CardQuantitySelector(
                              value: widget.totalQuantity,
                              min:
                                  1, // Minimum 1, otherwise they should delete it
                              max: widget.totalAvailableStock,
                              onChanged: widget.onQuantityChanged,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CardQuantitySelector extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _CardQuantitySelector({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Cantidad:',
          style: TextStyle(
            fontSize: 13,
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: value > min
              ? () => onChanged((value - 1).clamp(min, max))
              : null,
          icon: const Icon(Icons.remove),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          color: colors.primary,
        ),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            value.truncateToDouble() == value
                ? value.toInt().toString()
                : value.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        IconButton(
          onPressed: value < max
              ? () => onChanged((value + 1).clamp(min, max))
              : null,
          icon: const Icon(Icons.add),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          color: colors.primary,
        ),
      ],
    );
  }
}
