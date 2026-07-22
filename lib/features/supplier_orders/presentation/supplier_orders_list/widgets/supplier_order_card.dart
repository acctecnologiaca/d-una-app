import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/supplier_order.dart';
import '../../../domain/models/supplier_order_status.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/standard_list_item.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart' show StockStatus;

class SupplierOrderCard extends ConsumerWidget {
  final SupplierOrder order;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SupplierOrderCard({
    super.key,
    required this.order,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Obtener proveedores y resolver nombre en formato Alias (Nombre Legal)
    final suppliers = ref.watch(suppliersProvider).valueOrNull ?? [];
    Supplier? matchedSupplier;
    for (final s in suppliers) {
      if (s.id == order.supplierId) {
        matchedSupplier = s;
        break;
      }
    }

    final supplierDisplayName = matchedSupplier != null
        ? matchedSupplier.name
        : order.supplierName;

    final canShowAlerts = order.canShowAlerts;
    final hasPriceIncrease = canShowAlerts && order.hasPriceIncrease;
    final hasOutOfStock = canShowAlerts && order.stockStatus == StockStatus.unavailable;
    final hasLowStock = canShowAlerts && order.stockStatus == StockStatus.lowStock;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer.withValues(alpha: 0.3)
            : (canShowAlerts && (hasPriceIncrease || hasOutOfStock || hasLowStock)
                  ? colors.errorContainer.withValues(alpha: 0.8)
                  : null),
      ),
      child: StandardListItem(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        onTap: onTap,
        onLongPress: onLongPress,
        overline: Text(
          '${order.orderNumber} (${dateFormat.format(order.date)})',
        ),
        title: supplierDisplayName,
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
            isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canShowAlerts) ...[
                        if (hasPriceIncrease)
                          _buildAlertIcon(
                            'assets/icons/price_increase.png',
                            'Aumento de costo',
                          ),
                        if (hasOutOfStock)
                          _buildAlertIcon(
                            'assets/icons/stock_unavailable.png',
                            'Sin stock disponible',
                          )
                        else if (hasLowStock)
                          _buildAlertIcon(
                            'assets/icons/stock_down.png',
                            'Stock bajo',
                          ),
                        const SizedBox(width: 4),
                      ],
                      if (order.status == SupplierOrderStatus.finalized) ...[
                        _buildVerificationBadge(
                          context,
                          order.verificationStatus,
                        ),
                        const SizedBox(width: 4),
                      ],
                      _buildStatusIcon(
                        order.status.iconPath,
                        order.status.label,
                      ),
                    ],
                  ),
          ],
        ),
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
            return const Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: Colors.orange,
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String assetPath, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Image.asset(
        assetPath,
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.help_outline, size: 24, color: Colors.grey);
        },
      ),
    );
  }

  Widget _buildVerificationBadge(
    BuildContext context,
    String verificationStatus,
  ) {
    final colors = Theme.of(context).colorScheme;
    String label = 'En revisión';
    Color color = colors.secondary;
    IconData icon = Icons.hourglass_empty_rounded;

    if (verificationStatus == 'approved') {
      label = 'Aprobado';
      color = const Color(0xFF388E3C);
      icon = Icons.check_circle_outline_rounded;
    } else if (verificationStatus == 'rejected') {
      label = 'Rechazado';
      color = colors.error;
      icon = Icons.cancel_outlined;
    }

    return Tooltip(
      message: 'Soporte: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 14, color: color),
            const SizedBox(width: 3),
            Icon(icon, size: 14, color: color),

            /* Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
