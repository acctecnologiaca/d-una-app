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
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:d_una_app/features/supplier_orders/domain/utils/oc_credit_helper.dart';

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

            // If invoice photo/pdf is available
            if (order.invoicePhotoUrl != null &&
                order.invoicePhotoUrl!.isNotEmpty) ...[
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    if (_isPdfUrl(order.invoicePhotoUrl!)) {
                      _showFullscreenPdfViewer(
                        context,
                        order.invoicePhotoUrl!,
                        order.orderNumber,
                      );
                    } else {
                      _showFullscreenImageViewer(
                        context,
                        order.invoicePhotoUrl!,
                        order.orderNumber,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isPdfUrl(order.invoicePhotoUrl!)
                        ? Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.picture_as_pdf_outlined,
                                  size: 32,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Comprobante PDF',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Presione para ampliar la vista previa',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Symbols.zoom_in,
                                color: colors.primary,
                                size: 28,
                              ),
                            ],
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  order.invoicePhotoUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 120,
                                        color: colors.surfaceContainer,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 40,
                                              color: colors.onSurfaceVariant,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Error al cargar imagen',
                                              style: TextStyle(
                                                color: colors.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Symbols.zoom_in,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ampliar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                    final isApproved = order.verificationStatus == 'approved';
                    final isRejected = order.verificationStatus == 'rejected';
                    final creditsDisplay = isApproved
                        ? '$earned'
                        : isRejected
                        ? '- $earned'
                        : '$earned';
                    final creditsColor = isApproved
                        ? Color(0xFF388E3C)
                        : isRejected
                        ? colors.error
                        : colors.secondary;

                    return Text(
                      creditsDisplay,
                      style: TextStyle(
                        fontSize: 16,
                        color: creditsColor,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
            if (order.status == SupplierOrderStatus.finalized) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Soporte:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildVerificationBadge(context, order.verificationStatus),
                ],
              ),
            ],
            order.status == SupplierOrderStatus.finalized
                ? const SizedBox(height: 12)
                : const SizedBox(height: 20),
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

  Widget _buildVerificationBadge(
    BuildContext context,
    String verificationStatus,
  ) {
    final colors = Theme.of(context).colorScheme;
    String label = 'En revisión';
    Color statusColor = colors.secondary;
    IconData icon = Icons.hourglass_empty_rounded;

    if (verificationStatus == 'approved') {
      label = 'Aprobado';
      statusColor = Color(0xFF388E3C);
      icon = Icons.check_circle_outline_rounded;
    } else if (verificationStatus == 'rejected') {
      label = 'Rechazado';
      statusColor = colors.error;
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent, //statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: statusColor,
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

  bool _isPdfUrl(String url) {
    final cleanUrl = url.split('?').first.toLowerCase();
    return cleanUrl.endsWith('.pdf');
  }

  void _showFullscreenImageViewer(
    BuildContext context,
    String imageUrl,
    String orderNumber,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text(
                        'Error al cargar la imagen',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Soporte #$orderNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullscreenPdfViewer(
    BuildContext context,
    String pdfUrl,
    String orderNumber,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          backgroundColor: colors.surface,
          child: Column(
            children: [
              AppBar(
                title: Text(
                  'Soporte (#$orderNumber)',
                  style: TextStyle(color: colors.onSurface),
                ),
                automaticallyImplyLeading: false,
                backgroundColor: colors.surface,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: colors.onSurface,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: PdfPreview(
                  build: (format) async {
                    final response = await http.get(Uri.parse(pdfUrl));
                    if (response.statusCode == 200) {
                      return response.bodyBytes;
                    }
                    throw Exception(
                      'Error al descargar el PDF (${response.statusCode})',
                    );
                  },
                  allowPrinting: false,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  scrollViewDecoration: BoxDecoration(
                    color: colors.surfaceContainer,
                  ),
                  loadingWidget: const Center(
                    child: CircularProgressIndicator(),
                  ),
                  onError: (context, error) => const Center(
                    child: Text('Error al cargar la vista previa del PDF'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
