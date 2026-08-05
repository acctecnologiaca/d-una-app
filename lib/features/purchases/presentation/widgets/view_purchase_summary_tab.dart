import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import '../providers/purchase_details_provider.dart';

class ViewPurchaseSummaryTab extends ConsumerWidget {
  final PurchaseDetailsData data;
  final Function(int) onNavigateToTab;

  const ViewPurchaseSummaryTab({
    super.key,
    required this.data,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final purchase = data.purchase;

    final subtotal = purchase.subtotal;
    // Assuming tax is calculated in purchase object or we can compute it from total - subtotal
    final taxAmount = purchase.tax;
    final finalTotal = purchase.total;
    final taxRate = subtotal > 0 ? (taxAmount / subtotal) * 100 : 0.0;

    // Display products (max 3)
    final displayProducts = data.items.take(3).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Proveedor Section
            _buildSectionHeader(context, Icons.warehouse, 'Proveedor'),
            _buildSupplierCard(
              context,
              colors,
              purchase.supplierName,
              data.supplierTaxId,
            ),
            const SizedBox(height: 16),

            // 2. Factura Section
            _buildSectionHeader(
              context,
              purchase.documentType == 'invoice'
                  ? Icons.receipt_long
                  : Icons.receipt,
              purchase.documentType == 'invoice'
                  ? 'Factura'
                  : 'Nota de entrega',
            ),
            _buildInvoiceCard(
              context,
              colors,
              Theme.of(context).textTheme,
              subtotal,
              taxAmount,
              finalTotal,
              displayProducts,
              data.items.length,
              taxRate,
            ),
            const SizedBox(height: 8),
            // Footer note
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Los montos y/o los productos reflejados acá, deben ser iguales a los del documento de compra.',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // 3. Orden de Compra Section (If linked)
            if (purchase.supplierOrderId != null &&
                purchase.supplierOrderId!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLinkedSupplierOrderSection(
                context,
                ref,
                purchase.supplierOrderId!,
              ),
            ],

            // 4. Documento de Soporte Section (If available)
            if (purchase.invoicePhotoUrl != null &&
                purchase.invoicePhotoUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader(
                context,
                Icons.description,
                'Soporte digital',
              ),
              _buildSupportDocumentCard(
                context,
                colors,
                purchase.invoicePhotoUrl!,
                purchase.documentNumber,
                purchase.documentType == 'invoice'
                    ? 'Factura'
                    : 'Nota de entrega',
              ),
            ],
          ],
        ),
      ),
      // FAB is handled by the parent screen (PurchaseDetailsScreen)
    );
  }

  Widget _buildLinkedSupplierOrderSection(
    BuildContext context,
    WidgetRef ref,
    String supplierOrderId,
  ) {
    final orderAsync = ref.watch(parentSupplierOrderProvider(supplierOrderId));

    return orderAsync.when(
      data: (order) {
        if (order == null) return const SizedBox.shrink();
        final colors = Theme.of(context).colorScheme;

        final rawOrderNumber = order.orderNumber.trim();
        final cleanOrderNumber = rawOrderNumber.startsWith('#')
            ? rawOrderNumber
            : '#$rawOrderNumber';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(
              context,
              Icons.shopping_cart,
              'Orden de compra',
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
                  'Orden de compra $cleanOrderNumber',
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
                  context.push('/supplier-orders/view/${order.id}');
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

  // ── Support Document Card ──────────────────────────────────
  bool _isPdfUrl(String url) {
    return url.toLowerCase().contains('.pdf');
  }

  Widget _buildSupportDocumentCard(
    BuildContext context,
    ColorScheme colors,
    String photoUrl,
    String docNumber,
    String docTypeLabel,
  ) {
    final isPdf = _isPdfUrl(photoUrl);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      color: colors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (isPdf) {
            _showFullscreenPdfViewer(
              context,
              photoUrl,
              docNumber,
              docTypeLabel,
            );
          } else {
            _showFullscreenImageViewer(
              context,
              photoUrl,
              docNumber,
              docTypeLabel,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isPdf
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
                            'Presione para ampliar la vista previa',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Symbols.zoom_in, color: colors.primary, size: 28),
                  ],
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 120,
                          color: colors.surfaceContainer,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 120,
                          color: colors.surfaceContainer,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
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
    );
  }

  void _showFullscreenImageViewer(
    BuildContext context,
    String imageUrl,
    String docNumber,
    String docTypeLabel,
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
                        '$docTypeLabel #$docNumber',
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
    String docNumber,
    String docTypeLabel,
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
                  '$docTypeLabel #$docNumber',
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

  // ── Section Header ─────────────────────────────────────────
  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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

  // ── Proveedor Card ─────────────────────────────────────────
  Widget _buildSupplierCard(
    BuildContext context,
    ColorScheme colors,
    String? supplierName,
    String? taxId,
  ) {
    return Card(
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
              Icons.domain,
              'Razón social',
              supplierName ?? 'No seleccionado',
              colors,
              isTextValue: true,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              context,
              Icons.badge_outlined,
              'RIF/NIF/RUT',
              taxId ?? 'N/A',
              colors,
              isTextValue: true,
            ),
          ],
        ),
      ),
    );
  }

  // ── Invoice Card ───────────────────────────────────────────
  Widget _buildInvoiceCard(
    BuildContext context,
    ColorScheme colors,
    TextTheme textTheme,
    double subtotal,
    double taxAmount,
    double finalTotal,
    List displayProducts,
    int totalItemsCount,
    double taxRate,
  ) {
    return Card(
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
            // Products header
            _buildHeaderRow(
              context,
              Icons.inventory_2_outlined,
              'Productos',
              colors,
              groupedCount: totalItemsCount,
              amount: CurrencyFormatter.format(subtotal),
            ),
            const SizedBox(height: 8),

            // Product lines (max 3)
            ...displayProducts.map((p) {
              final qty = p.quantity.toInt();
              final uom = p.uom;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0, left: 24.0),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$qty $uom: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: p.name,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // "Ver todos..." only if more than 3
            if (totalItemsCount > 0)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onNavigateToTab(1),
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

            // Sub-Total
            _buildRowText(
              'Sub-Total',
              CurrencyFormatter.format(subtotal),
              isBold: true,
              icon: Icons.attach_money,
            ),
            const SizedBox(height: 8),

            // IVA
            // We hide the rate % in view mode if we don't store it, or calculate roughly if needed
            _buildRowText(
              'IVA (${taxRate.toStringAsFixed(0)}%)', // Ahora muestra el % calculado
              CurrencyFormatter.format(taxAmount),
              icon: Icons.percent,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),

            // Total
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
                  CurrencyFormatter.format(finalTotal),
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
    );
  }

  // ── Helper UI Methods ──────────────────────────────────────

  Widget _buildSummaryRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ColorScheme colors, {
    TextStyle? valueStyle,
    Color? iconColor,
    bool isTextValue = false,
  }) {
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
    String title,
    ColorScheme colors, {
    required int groupedCount,
    required String amount,
  }) {
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
