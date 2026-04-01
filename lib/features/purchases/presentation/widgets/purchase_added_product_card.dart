import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/utils/string_extensions.dart';
import '../../../../shared/utils/currency_formatter.dart';
import 'package:d_una_app/features/purchases/data/models/purchase_item_product.dart';
import 'package:d_una_app/shared/widgets/expandable_action_card.dart';
import 'package:d_una_app/shared/widgets/uom_status_badge.dart';

class PurchaseAddedProductCard extends StatelessWidget {
  final PurchaseItemProduct item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onAddSerials;
  final ValueChanged<double> onQuantityChanged;
  final bool isReadOnly;
  final bool hasError;

  const PurchaseAddedProductCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onEdit,
    required this.onAddSerials,
    required this.onQuantityChanged,
    this.isReadOnly = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ExpandableActionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isExpandable: !isReadOnly,
      backgroundColor: hasError
          ? colors.errorContainer.withValues(alpha: 0.8)
          : null,
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
          const SizedBox(height: 8),
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
        IconButton(
          icon: const Icon(Symbols.delete, fontWeight: FontWeight.w500),
          color: colors.onSurfaceVariant,
          onPressed: onDelete,
          tooltip: 'Eliminar producto',
        ),
        IconButton(
          icon: Image.asset(
            'assets/icons/package_edit.png',
            width: 24,
            height: 24,
            color: colors.onSurfaceVariant,
          ),
          onPressed: onEdit,
          tooltip: 'Editar detalles',
        ),
        if (item.requiresSerials)
          IconButton(
            icon: const Icon(Symbols.barcode),
            color: colors.onSurfaceVariant,
            onPressed: onAddSerials,
            tooltip: 'Gestionar seriales',
          ),
      ],
      expandedTrailing: Builder(
        builder: (context) {
          if (item.warrantyTime == null || item.warrantyTime == 0) {
            return Text(
              'Sin garantía',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            );
          }
          final unitMap = {'days': 'días', 'months': 'meses', 'years': 'años'};
          final unit = unitMap[item.warrantyUnit] ?? item.warrantyUnit ?? '';
          return Text(
            'Garantía: ${item.warrantyTime} $unit',
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          );
        },
      ),
    );
  }
}
