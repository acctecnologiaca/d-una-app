import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../domain/models/supplier_order.dart';
import '../../../domain/models/supplier_order_item.dart';
import '../../../domain/models/supplier_order_status.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';

class ViewSupplierOrderSummaryTab extends ConsumerWidget {
  final SupplierOrder order;
  final List<SupplierOrderItem> items;
  final Function(int) onNavigateToTab;

  const ViewSupplierOrderSummaryTab({
    super.key,
    required this.order,
    required this.items,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Obtener proveedores y resolver nombre formateado
    final suppliers = ref.watch(suppliersProvider).valueOrNull ?? [];
    Supplier? matchedSupplier;
    for (final s in suppliers) {
      if (s.id == order.supplierId) {
        matchedSupplier = s;
        break;
      }
    }
    final supplierDisplayName = matchedSupplier != null
        ? (matchedSupplier.legalName != null &&
                  matchedSupplier.legalName!.isNotEmpty
              ? '${matchedSupplier.name} (${matchedSupplier.legalName})'
              : matchedSupplier.name)
        : order.supplierName;

    // Group items by product key
    final Map<String, List<SupplierOrderItem>> groups = {};
    for (final item in items) {
      final key = "${item.name}|${item.brand ?? ''}|${item.model ?? ''}";
      groups.putIfAbsent(key, () => []).add(item);
    }

    final sortedKeys = groups.keys.toList()..sort();
    final totalGroupedProducts = sortedKeys.length;

    // Only display top 3 products
    final displayProducts = sortedKeys
        .take(3)
        .map((key) => MapEntry(key, groups[key]!))
        .toList();

    return Scaffold(
      backgroundColor: colors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (matchedSupplier != null &&
                matchedSupplier.minimumPurchaseAmount > 0 &&
                order.subtotal < matchedSupplier.minimumPurchaseAmount) ...[
              Card(
                color: colors.errorContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colors.error),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colors.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El subtotal de esta orden (${CurrencyFormatter.format(order.subtotal)} USD) no alcanza el monto mínimo de compra exigido por el proveedor (${CurrencyFormatter.format(matchedSupplier.minimumPurchaseAmount)} USD).\n\n'
                          'Faltan ${CurrencyFormatter.format(matchedSupplier.minimumPurchaseAmount - order.subtotal)} USD.',
                          style: TextStyle(
                            color: colors.onErrorContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // 0. Status & Last Mod Card
            _buildInfoCard(context, order),
            const SizedBox(height: 16),

            // 1. Proveedor Section
            _buildSectionHeader(context, Icons.warehouse, 'Proveedor'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.outlineVariant),
              ),
              color: colors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      context,
                      Icons.business,
                      'Nombre',
                      supplierDisplayName,
                      isTextValue: true,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      context,
                      Icons.location_on,
                      'Sucursal',
                      order.branchName ?? 'Ninguna',
                      isTextValue: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Pedido Section
            _buildSectionHeader(context, Icons.shopping_cart, 'Pedido'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.outlineVariant),
              ),
              color: colors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderRow(
                      context,
                      Icons.inventory_2_outlined,
                      'Productos',
                      groupedCount: totalGroupedProducts,
                      amount: CurrencyFormatter.format(order.subtotal),
                    ),
                    const SizedBox(height: 8),
                    ...displayProducts.map((entry) {
                      final groupItems = entry.value;
                      final firstItem = groupItems.first;
                      final totalQty = groupItems.fold(
                        0.0,
                        (sum, item) => sum + item.quantity,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0, left: 24.0),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${totalQty.toInt()} ${firstItem.uom}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: firstItem.name,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (totalGroupedProducts > 3)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => onNavigateToTab(1), // Products Tab
                          icon: const Icon(Icons.exit_to_app, size: 14),
                          label: const Text(' > Ir a productos'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
                    _buildRowText(
                      'Sub-Total',
                      CurrencyFormatter.format(order.subtotal),
                      isBold: true,
                      icon: Icons.attach_money,
                    ),
                    const SizedBox(height: 8),
                    _buildRowText(
                      'IVA (${(order.subtotal > 0 ? (order.tax / order.subtotal) * 100 : 0.0).toStringAsFixed(0)}%)',
                      CurrencyFormatter.format(order.tax),
                      icon: Icons.percent,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on_outlined,
                              size: 18,
                              color: colors.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Total',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.format(order.total),
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Método de envío Section
            _buildSectionHeader(
              context,
              Icons.local_shipping,
              'Método de envío',
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.outlineVariant),
              ),
              color: colors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      context,
                      Icons.info_outline,
                      'Método',
                      order.shippingMethodLabel ?? 'No seleccionado',
                      isTextValue: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Método de pago Section
            _buildSectionHeader(context, Icons.payment, 'Método de pago'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.outlineVariant),
              ),
              color: colors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      context,
                      Icons.account_balance_wallet,
                      'Condición',
                      order.paymentMethod ?? 'Por definir',
                      isTextValue: true,
                    ),
                  ],
                ),
              ),
            ),

            // If invoice photo is available
            if (order.invoicePhotoUrl != null) ...[
              const SizedBox(height: 16),
              _buildSectionHeader(
                context,
                Icons.receipt_long_outlined,
                'Documento de Soporte',
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                color: colors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order.invoicePhotoUrl!,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, SupplierOrder order) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy - hh:mm a');
    final status = order.status;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.tag, size: 20, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Orden:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      //fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  color: colors.primary,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: order.orderNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ID de orden copiado al portapapeles'),
                      ),
                    );
                  },
                ),
              ],
            ),
            //const SizedBox(height: 0),
            Row(
              children: [
                Icon(
                  Symbols.conversion_path,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estatus:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(context, status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.update, size: 20, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Últ. mod:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(order.updatedAt.toLocal()),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, SupplierOrderStatus status) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(status.iconPath, width: 16, height: 16),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: TextStyle(
              color: status.statusColor(colors),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    TextStyle? valueStyle,
    Color? iconColor,
    bool isTextValue = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor ?? colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style:
                valueStyle ??
                TextStyle(
                  fontWeight: isTextValue ? FontWeight.normal : FontWeight.w600,
                  color: isTextValue
                      ? colors.onSurfaceVariant
                      : colors.onSurface,
                  fontSize: isTextValue ? 14 : 16,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    IconData icon,
    String title, {
    required int groupedCount,
    required String amount,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colors.onSurface),
            const SizedBox(width: 8),
            Text(
              '$title ($groupedCount)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRowText(
    String label,
    String value, {
    bool isBold = false,
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
            ] else
              const SizedBox(width: 24),
            Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
