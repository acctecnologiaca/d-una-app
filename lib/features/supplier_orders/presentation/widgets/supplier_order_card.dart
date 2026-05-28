import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/supplier_order.dart';
import '../../domain/models/supplier_order_status.dart';
import '../providers/supplier_orders_providers.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/standard_list_item.dart';

class SupplierOrderCard extends ConsumerWidget {
  final SupplierOrder order;
  final VoidCallback? onTap;

  const SupplierOrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Watch details for live alerts (only for sent/resent status)
    final canShowAlerts = order.status == SupplierOrderStatus.sent || order.status == SupplierOrderStatus.resent;
    
    bool hasPriceIncrease = false;
    bool hasOutOfStock = false;
    bool hasLowStock = false;

    if (canShowAlerts) {
      final detailsAsync = ref.watch(supplierOrderDetailProvider(order.id));
      final items = detailsAsync.valueOrNull?.items ?? [];
      hasPriceIncrease = items.any((item) => item.hasPriceIncrease);
      hasOutOfStock = items.any((item) => item.isOutOfStock);
      hasLowStock = items.any((item) => item.hasLowStock);
    }

    return StandardListItem(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      onTap: onTap,
      overline: Text(
        '#${order.orderNumber} (${dateFormat.format(order.date)})',
      ),
      title: order.supplierName,
      subtitle: order.branchName != null
          ? Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16),
                const SizedBox(width: 4),
                Text(order.branchName!),
              ],
            )
          : null,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.format(order.total),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canShowAlerts) ...[
                if (hasPriceIncrease)
                  _buildAlertIcon('assets/icons/price_increase.png', 'Aumento de costo'),
                if (hasOutOfStock)
                  _buildAlertIcon('assets/icons/stock_unavailable.png', 'Sin stock disponible')
                else if (hasLowStock)
                  _buildAlertIcon('assets/icons/stock_down.png', 'Stock bajo'),
                const SizedBox(width: 4),
              ],
              _buildStatusIcon(order.status.iconPath, order.status.label, order.status.statusColor(colors)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertIcon(String assetPath, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Tooltip(
        message: tooltip,
        child: Image.asset(
          assetPath,
          width: 20,
          height: 20,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange);
          },
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String assetPath, String tooltip, Color statusColor) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              width: 16,
              height: 16,
              color: statusColor,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.info_outline, size: 16, color: statusColor);
              },
            ),
            const SizedBox(width: 4),
            Text(
              tooltip,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
