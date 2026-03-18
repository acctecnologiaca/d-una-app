import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/standard_list_item.dart';
import 'package:d_una_app/features/purchases/data/models/purchase_item_product.dart';

class PurchaseAddedProductCard extends StatefulWidget {
  final PurchaseItemProduct item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onAddSerials;

  const PurchaseAddedProductCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onEdit,
    required this.onAddSerials,
  });

  @override
  State<PurchaseAddedProductCard> createState() => _PurchaseAddedProductCardState();
}

class _PurchaseAddedProductCardState extends State<PurchaseAddedProductCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final String quantityText = 
        '${widget.item.quantity.truncateToDouble() == widget.item.quantity 
            ? widget.item.quantity.toInt() 
            : widget.item.quantity} ${widget.item.uom}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          StandardListItem(
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12.0),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            overline: widget.item.brand != null
                ? Text(widget.item.brand!.toTitleCase)
                : null,
            title: widget.item.name.toTitleCase,
            subtitle: (widget.item.model != null && widget.item.model!.isNotEmpty)
                ? Text(widget.item.model!.toUpperCase())
                : null,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(widget.item.subtotal),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Symbols.delete),
                              color: colors.onSurfaceVariant,
                              onPressed: widget.onDelete,
                              tooltip: 'Eliminar producto',
                            ),
                            IconButton(
                              icon: const Icon(Symbols.edit),
                              color: colors.onSurfaceVariant,
                              onPressed: widget.onEdit,
                              tooltip: 'Editar detalles',
                            ),
                            if (widget.item.requiresSerials)
                              IconButton(
                                icon: const Icon(Symbols.barcode),
                                color: colors.onSurfaceVariant,
                                onPressed: widget.onAddSerials,
                                tooltip: 'Gestionar seriales',
                              ),
                            const Spacer(),
                            // Quantity display in expanded mode
                            Text(
                              'Garantía: ${widget.item.warrantyTime ?? "N/A"} ${widget.item.warrantyUnit ?? ""}',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.onSurfaceVariant,
                              ),
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
