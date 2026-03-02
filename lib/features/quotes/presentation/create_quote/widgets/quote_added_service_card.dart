import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/standard_list_item.dart';

class QuoteAddedServiceCard extends StatefulWidget {
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
  State<QuoteAddedServiceCard> createState() => _QuoteAddedServiceCardState();
}

class _QuoteAddedServiceCardState extends State<QuoteAddedServiceCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    String formatValue(double value) {
      return value.truncateToDouble() == value
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
    }

    final String quantityText =
        '${formatValue(widget.quantity)} ${widget.rateSuffix.replaceAll('/', '')}';

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
            overline: widget.category != null
                ? Text(widget.category!.toTitleCase)
                : const Text('Sin categoría'),
            title: widget.name.toTitleCase,
            subtitle: widget.executionTime != null
                ? Text(
                    'Entrega: ${widget.executionTime}',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  )
                : null,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Sale Price (Total for this item)
                Text(
                  CurrencyFormatter.format(widget.subtotal * widget.quantity),
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
                    // Quantity Badge
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
                            Symbols.design_services,
                            size: 14,
                            color: colors.onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            quantityText,
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
                            // Actions: Delete, Edit Details
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
                              tooltip: 'Eliminar servicio',
                            ),
                            IconButton(
                              icon: const Icon(Symbols.edit_document),
                              color: colors.onSurfaceVariant,
                              visualDensity: VisualDensity.compact,
                              onPressed: widget.onEditSaleDetails,
                              tooltip: 'Ajustar detalles del servicio',
                            ),
                            const Spacer(),
                            // Dynamic Stepper
                            _CardQuantitySelector(
                              value: widget.quantity,
                              min:
                                  1, // Minimum 1, otherwise they should delete it
                              max: 99999, // Practically unlimited for services
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
