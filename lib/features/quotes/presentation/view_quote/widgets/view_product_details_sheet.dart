import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../domain/models/product_origin.dart';
import '../../create_quote/widgets/quote_added_product_card.dart';
import '../../create_quote/providers/quote_validation_provider.dart';
import '../../../../../shared/widgets/status_badge.dart';
import '../../../../../shared/widgets/uom_status_badge.dart';

class ViewProductDetailsSheet extends StatelessWidget {
  final String productName;
  final String? brand;
  final String? model;
  final String uom;
  final String? uomIconName;
  final double averageCost;
  final double salePrice;
  final List<ProductOrigin> origins;

  // Header Card Data
  final double subtotal;
  final double totalQuantity;
  final double totalAvailableStock;
  final bool hasOwnInventory;
  final bool hasSupplierInventory;
  final bool isTemporal;
  final bool isExternalManagement;
  final List<QuoteValidationStatus> alerts;

  const ViewProductDetailsSheet({
    super.key,
    required this.productName,
    this.brand,
    this.model,
    required this.uom,
    this.uomIconName,
    required this.averageCost,
    required this.salePrice,
    required this.origins,
    required this.subtotal,
    required this.totalQuantity,
    required this.totalAvailableStock,
    required this.hasOwnInventory,
    required this.hasSupplierInventory,
    required this.isTemporal,
    required this.isExternalManagement,
    required this.alerts,
  });

  static Future<void> show(
    BuildContext context, {
    required String productName,
    String? brand,
    String? model,
    required String uom,
    String? uomIconName,
    required double averageCost,
    required double salePrice,
    required List<ProductOrigin> origins,
    required double subtotal,
    required double totalQuantity,
    required double totalAvailableStock,
    required bool hasOwnInventory,
    required bool hasSupplierInventory,
    required bool isTemporal,
    required bool isExternalManagement,
    required List<QuoteValidationStatus> alerts,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => ViewProductDetailsSheet(
        productName: productName,
        brand: brand,
        model: model,
        uom: uom,
        uomIconName: uomIconName,
        averageCost: averageCost,
        salePrice: salePrice,
        origins: origins,
        subtotal: subtotal,
        totalQuantity: totalQuantity,
        totalAvailableStock: totalAvailableStock,
        hasOwnInventory: hasOwnInventory,
        hasSupplierInventory: hasSupplierInventory,
        isTemporal: isTemporal,
        isExternalManagement: isExternalManagement,
        alerts: alerts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profit = salePrice - averageCost;
    //final profitMargin = averageCost > 0 ? (profit / averageCost) * 100 : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                height: 4,
                width: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row (Standard Action Sheet Style)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: QuoteAddedProductCard(
                      name: productName,
                      brand: brand,
                      model: model,
                      uom: uom,
                      uomIconName: uomIconName,
                      subtotal: subtotal,
                      totalQuantity: totalQuantity,
                      totalAvailableStock: totalAvailableStock,
                      hasOwnInventory: false,
                      hasSupplierInventory: false,
                      isTemporal: false,
                      isExternalManagement: false,
                      isReadOnly: true,
                      alerts: const [],
                      onDelete: () {},
                      onEditPrice: () {},
                      onEditSources: () {},
                      onQuantityChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),

            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 16),

            // Content with Padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suppliers Section
                  _buildSectionTitle(context, 'Proveedores', Symbols.warehouse),
                  const SizedBox(height: 16),
                  ...origins.map(
                    (origin) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildOriginCard(context, origin),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Financial Section
                  _buildSectionTitle(
                    context,
                    'Rentabilidad',
                    Symbols.bar_chart,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetric(
                          context,
                          label: 'Precio de Venta',
                          value: '${CurrencyFormatter.format(salePrice)}/$uom',
                          valueColor: colors.primary,
                        ),
                      ),
                      Expanded(
                        child: _buildMetric(
                          context,
                          label: 'Costo Promedio',
                          value:
                              '${CurrencyFormatter.format(averageCost)}/$uom',
                          valueColor: colors.error,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Profit Highlight
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.shade700.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Symbols.trending_up,
                            color: Colors.green.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ganancia Estimada',
                                style: textTheme.labelMedium?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${CurrencyFormatter.format(profit)}/$uom',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        /* Text(
                          '+${profitMargin.toStringAsFixed(1)}%',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),*/
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.outline),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.onSurface,
            // letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOriginCard(BuildContext context, ProductOrigin origin) {
    final colors = Theme.of(context).colorScheme;

    final (
      Widget icon,
      Color iconColor,
      String typeLabel,
      Color? bgColor,
    ) = switch (origin.type) {
      OriginType.own => (
        StatusBadge(
          backgroundColor: colors.primary,
          textColor: colors.onPrimary,
          borderRadius: 4.0,
          icon: Icon(Symbols.inventory_2, size: 15, color: colors.onPrimary),
        ),
        colors.primary,
        'Inventario propio',
        null,
      ),
      OriginType.affiliated => (
        StatusBadge(
          backgroundColor: colors.tertiaryContainer,
          textColor: colors.onTertiaryContainer,
          borderRadius: 4.0,
          icon: Icon(
            Symbols.warehouse,
            size: 16,
            color: colors.onTertiaryContainer,
          ),
        ),
        colors.onTertiaryContainer,
        'Proveedor afiliado',
        null,
      ),
      OriginType.external => (
        StatusBadge(
          backgroundColor: colors.onSurfaceVariant,
          textColor: colors.surface,
          borderRadius: 4.0,
          icon: Icon(Symbols.outbound, size: 16, color: colors.surface),
        ),
        colors.onSurfaceVariant,
        'Proveedor externo',
        null,
      ),
      OriginType.temporal => (
        StatusBadge(
          backgroundColor: colors.outline,
          textColor: colors.surface,
          borderRadius: 4.0,
          icon: Icon(Symbols.chronic, size: 16, color: colors.surface),
        ),
        colors.outline,
        'Producto temporal',
        null,
      ),
    };

    // If the label is different from the type label, show the specific name (Supplier/External)
    final bool showProviderName = origin.label != typeLabel;

    return _buildInfoCard(
      context,
      //title: typeLabel,
      value: showProviderName ? origin.label : typeLabel,
      icon: icon,
      iconColor: iconColor,
      backgroundColor: bgColor,
      trailing: UomStatusBadge(
        quantity: origin.quantity,
        uomAbbreviation: uom,
        uomIconName: uomIconName,
        maxStock: origin.availableStock,
        backgroundColor: colors.surface,
        textColor: origin.quantity > origin.availableStock
            ? colors.error
            : colors.onSurface,
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    String? title,
    required String value,
    required Widget icon,
    Color? backgroundColor,
    Color? iconColor,
    Widget? trailing,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                Text(
                  value,
                  maxLines: 1, // <--- Nueva línea
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }
}
