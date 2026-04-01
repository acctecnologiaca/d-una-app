import 'package:flutter/material.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';
import '../providers/purchase_details_provider.dart';

class ViewPurchaseSummaryTab extends StatelessWidget {
  final PurchaseDetailsData data;
  final Function(int) onNavigateToTab;

  const ViewPurchaseSummaryTab({
    super.key,
    required this.data,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
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
            _buildSectionHeader(context, Icons.groups_outlined, 'Proveedor'),
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
                  ? Icons.receipt_long_outlined
                  : Icons.receipt_outlined,
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
            const SizedBox(height: 16),

            // Footer note
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Los montos finales acá reflejados, deben ser iguales a los del documento de compra.',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      // FAB is handled by the parent screen (PurchaseDetailsScreen)
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
            if (totalItemsCount > 3)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onNavigateToTab(1),
                  icon: const Icon(Icons.arrow_forward_ios, size: 14),
                  label: const Text('Ver todos...'),
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
