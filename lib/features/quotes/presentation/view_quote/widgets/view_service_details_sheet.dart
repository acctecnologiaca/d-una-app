import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../create_quote/widgets/quote_added_service_card.dart';

class ViewServiceDetailsSheet extends StatelessWidget {
  final String serviceName;
  final String? category;
  final double salePrice;
  final String rateSuffix;
  final String? executionTimeLabel;
  final bool isExternal;
  final double? externalCost;
  final double quantity;
  final String? rateIconName;
  final bool isTemporal;
  final String? warrantyDisplay;

  const ViewServiceDetailsSheet({
    super.key,
    required this.serviceName,
    this.category,
    required this.salePrice,
    required this.rateSuffix,
    this.executionTimeLabel,
    this.isExternal = false,
    this.externalCost,
    required this.quantity,
    this.rateIconName,
    this.isTemporal = false,
    this.warrantyDisplay,
  });

  static Future<void> show(
    BuildContext context, {
    required String serviceName,
    String? category,
    required double salePrice,
    required String rateSuffix,
    String? executionTimeLabel,
    bool isExternal = false,
    double? externalCost,
    required double quantity,
    String? rateIconName,
    bool isTemporal = false,
    String? warrantyDisplay,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => ViewServiceDetailsSheet(
        serviceName: serviceName,
        category: category,
        salePrice: salePrice,
        rateSuffix: rateSuffix,
        executionTimeLabel: executionTimeLabel,
        isExternal: isExternal,
        externalCost: externalCost,
        quantity: quantity,
        rateIconName: rateIconName,
        isTemporal: isTemporal,
        warrantyDisplay: warrantyDisplay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
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
                    child: QuoteAddedServiceCard(
                      name: serviceName,
                      category: category,
                      subtotal: salePrice,
                      quantity: quantity,
                      rateSuffix: rateSuffix,
                      executionTimeLabel: executionTimeLabel,
                      rateIconName: rateIconName,
                      isTemporal: isTemporal,
                      isReadOnly: true,
                      onDelete: () {},
                      onEditSaleDetails: () {},
                      onQuantityChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),

            const Divider(indent: 16, endIndent: 16),
            const SizedBox(height: 16),

            // Contenido con Padding estándar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Operational Details
                  _buildSectionTitle(
                    context,
                    'Detalles Operativos',
                    Symbols.settings_suggest,
                  ),
                  const SizedBox(height: 16),

                  _buildInfoCard(
                    context,
                    title: 'Tipo de Gestión',
                    value: isExternal
                        ? 'Servicio Tercerizado'
                        : 'Gestión Propia',
                    icon: Icon(
                      Symbols.settings_accessibility,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),

                  if (executionTimeLabel != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      title: 'Tiempo de Ejecución',
                      value: executionTimeLabel!,
                      icon: Icon(
                        Icons.timer_outlined,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],

                  if (warrantyDisplay != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      title: 'Garantía',
                      value: warrantyDisplay!,
                      icon: Icon(
                        Icons.verified_user_outlined,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Profit Section
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
                          value:
                              '${CurrencyFormatter.format(salePrice)} $rateSuffix',
                          valueColor: colors.primary,
                        ),
                      ),
                      if (isExternal && externalCost != null)
                        Expanded(
                          child: _buildMetric(
                            context,
                            label: 'Costo Proveedor',
                            value: CurrencyFormatter.format(externalCost!),
                            valueColor: colors.error,
                          ),
                        ),
                    ],
                  ),

                  if (isExternal && externalCost != null) ...[
                    const SizedBox(height: 24),
                    // Profit Highlight Box
                    Container(
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
                              color: Colors.green.shade700.withValues(
                                alpha: 0.1,
                              ),
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
                                  CurrencyFormatter.format(
                                    salePrice - externalCost!,
                                  ),
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                Text(
                  value,
                  maxLines: 1,
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
