import 'package:flutter/material.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../domain/models/supplier_order.dart';
import '../../domain/models/supplier_order_item.dart';
import '../../domain/models/supplier_order_status.dart';

class ViewSupplierOrderProductsTab extends StatelessWidget {
  final SupplierOrder order;
  final List<SupplierOrderItem> items;

  const ViewSupplierOrderProductsTab({
    super.key,
    required this.order,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canShowAlerts = order.status == SupplierOrderStatus.sent || order.status == SupplierOrderStatus.resent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          final hasWarning = canShowAlerts && (item.hasPriceIncrease || item.isOutOfStock || item.hasLowStock);
          Color? cardBgColor;
          if (hasWarning) {
            cardBgColor = colors.errorContainer.withValues(alpha: 0.15);
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: cardBgColor ?? colors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: hasWarning
                    ? colors.error.withValues(alpha: 0.5)
                    : colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(item.total),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.brand ?? "Sin marca"} • ${item.model ?? "Sin modelo"}',
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${CurrencyFormatter.format(item.unitPrice)} x ${item.quantity} ${item.uom}',
                        style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
                      ),
                      if (canShowAlerts) ...[
                        if (item.isOutOfStock)
                          _buildWarningBadge(colors.error, Icons.block, 'Sin Stock')
                        else if (item.hasLowStock)
                          _buildWarningBadge(Colors.orange, Icons.warning_amber_rounded, 'Stock Bajo (${item.currentSupplierStock})')
                        else if (item.hasPriceIncrease)
                          _buildWarningBadge(colors.error, Icons.trending_up, 'Aumento costo (${CurrencyFormatter.format(item.currentSupplierPrice ?? 0.0)})'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWarningBadge(Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
