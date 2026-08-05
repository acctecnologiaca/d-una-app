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
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/supplier_orders/domain/utils/oc_credit_helper.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';

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
        ? matchedSupplier.name
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
            _buildInfoCard(context, ref, order),
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
            _buildSectionHeader(context, Icons.article, 'Pedido'),
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
                    if (totalGroupedProducts > 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => onNavigateToTab(1), // Products Tab
                          icon: const Icon(Icons.arrow_forward_ios, size: 14),
                          label: const Text(
                            'Ir a productos',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
              'Condiciones de envío',
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
            _buildSectionHeader(context, Icons.payment, 'Condiciones de pago'),
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
                      'Método',
                      order.paymentMethod ?? 'Por definir',
                      isTextValue: true,
                    ),
                  ],
                ),
              ),
            ),

            if (order.status == SupplierOrderStatus.merged) ...[
              _buildParentOrderSection(context, ref, order),
            ] else ...[
              _buildMergedChildOrdersSection(context, ref, order),
            ],
            _buildLinkedPurchaseSection(context, ref, order),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    WidgetRef ref,
    SupplierOrder order,
  ) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy - hh:mm a');
    final status = order.status;

    final linkedPurchaseAsync = ref.watch(linkedPurchaseProvider(order.id));
    final linkedPurchase = linkedPurchaseAsync.valueOrNull;
    final verificationStatus =
        linkedPurchase?['verification_status'] as String? ??
        order.verificationStatus;

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
            if (order.status != SupplierOrderStatus.merged) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.star_border_outlined,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Créditos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (context) {
                      final earned = OCCreditHelper.calculateEarnedCredits(
                        order.total,
                      );
                      final isRejected = verificationStatus == 'rejected';
                      final isCreditsGranted =
                          (order.status == SupplierOrderStatus.approved ||
                              order.status == SupplierOrderStatus.finalized) &&
                          !isRejected;

                      final String creditsDisplay;
                      final Color creditsColor;
                      final String tooltipMessage;

                      if (isRejected) {
                        creditsDisplay = '$earned (revocados)';
                        creditsColor = colors.error;
                        tooltipMessage =
                            'Créditos revocados por inconsistencia entre la orden y el soporte cargado al registrar la compra';
                      } else if (isCreditsGranted) {
                        creditsDisplay = '$earned (aprobados)';
                        creditsColor = const Color(0xFF388E3C);
                        tooltipMessage =
                            'El proveedor ha aprobado la orden de compra';
                      } else {
                        creditsDisplay = '0 ($earned pendientes)';
                        creditsColor = colors.secondary;
                        tooltipMessage =
                            'Acreditados una vez el proveedor apruebe la orden de compra';
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            creditsDisplay,
                            style: TextStyle(
                              fontSize: 16,
                              color: creditsColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Tooltip(
                            message: tooltipMessage,
                            triggerMode: TooltipTriggerMode.tap,
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
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

  Widget _buildParentOrderSection(
    BuildContext context,
    WidgetRef ref,
    SupplierOrder order,
  ) {
    if (order.status != SupplierOrderStatus.merged ||
        order.parentOrderId == null) {
      return const SizedBox.shrink();
    }

    final parentOrderAsync = ref.watch(
      parentSupplierOrderProvider(order.parentOrderId),
    );

    return parentOrderAsync.when(
      data: (parentOrder) {
        if (parentOrder == null) return const SizedBox.shrink();
        final colors = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildSectionHeader(
              context,
              Icons.shopping_cart,
              'Orden Principal',
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.outlineVariant),
              ),
              color: colors.surface,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Text(
                  '${parentOrder.orderNumber} (${parentOrder.supplierName})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colors.onSurface,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: parentOrder.status.label,
                      child: Image.asset(
                        parentOrder.status.iconPath,
                        width: 18,
                        height: 18,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.merge_type_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                  ],
                ),
                onTap: () {
                  context.push('/supplier-orders/view/${parentOrder.id}');
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildMergedChildOrdersSection(
    BuildContext context,
    WidgetRef ref,
    SupplierOrder order,
  ) {
    final mergedOrdersAsync = ref.watch(mergedChildOrdersProvider(order.id));
    return mergedOrdersAsync.when(
      data: (orders) {
        if (orders.isEmpty) return const SizedBox.shrink();
        final colors = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildSectionHeader(
              context,
              Icons.merge_type_rounded,
              'Órdenes consolidadas',
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.outlineVariant),
              ),
              color: colors.surface,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final childOrder = orders[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      '${childOrder.orderNumber} (${childOrder.supplierName})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colors.onSurface,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: childOrder.status.label,
                          child: Image.asset(
                            childOrder.status.iconPath,
                            width: 18,
                            height: 18,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.merge_type_rounded, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onTap: () {
                      context.push('/supplier-orders/view/${childOrder.id}');
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildLinkedPurchaseSection(
    BuildContext context,
    WidgetRef ref,
    SupplierOrder order,
  ) {
    final linkedPurchaseAsync = ref.watch(linkedPurchaseProvider(order.id));

    return linkedPurchaseAsync.when(
      data: (purchaseData) {
        if (purchaseData == null) return const SizedBox.shrink();
        final colors = Theme.of(context).colorScheme;

        final rawDocNumber =
            (purchaseData['document_number'] as String?)?.trim() ??
            order.orderNumber;
        final cleanDocNumber = rawDocNumber.startsWith('#')
            ? rawDocNumber
            : '#$rawDocNumber';
        final docType = purchaseData['document_type'] == 'invoice'
            ? 'Factura'
            : 'Nota de entrega';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildSectionHeader(
              context,
              Icons.receipt_long_outlined,
              'Registro de compra',
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.outlineVariant),
              ),
              color: colors.surface,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                title: Text(
                  '$docType $cleanDocNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colors.onSurface,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colors.onSurfaceVariant,
                ),
                onTap: () {
                  context.push('/my-purchases/view/${purchaseData['id']}');
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
