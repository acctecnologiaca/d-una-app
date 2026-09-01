import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../domain/models/service_report_model.dart';
import '../providers/view_report_provider.dart';
import '../../../data/models/service_report.dart';
import '../../../data/models/service_report_item_product.dart';
import '../../../data/models/service_report_item_service.dart';

class ViewReportSummaryTab extends ConsumerWidget {
  final String reportId;
  final Function(int) onNavigateToTab;

  const ViewReportSummaryTab({
    super.key,
    required this.reportId,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(viewReportProvider(reportId));

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (report) {
        final status = ServiceReportStatus.fromDbValue(report.status);
        final intervention = InterventionType.fromDbValue(
          report.interventionType,
        );

        // Calculations
        double productsSubtotal = 0;
        double productsCost = 0;
        final products = report.products ?? [];
        for (var p in products) {
          productsSubtotal += p.unitPrice * p.quantity;
          productsCost += p.costPrice * p.quantity;
        }

        double servicesSubtotal = 0;
        double servicesCost = 0;
        final services = report.services ?? [];
        for (var s in services) {
          servicesSubtotal += s.unitPrice * s.quantity;
          servicesCost += s.costPrice * s.quantity;
        }

        final totalSales = productsSubtotal + servicesSubtotal;
        final totalCosts = productsCost + servicesCost;
        final estimatedProfit = totalSales - totalCosts;

        final taxAmount = report.taxAmount;
        final finalTotal = report.total;
        final taxRateDisplay = totalSales > 0
            ? (taxAmount / totalSales) * 100
            : 0.0;

        // Group Products for display by index
        final groupedProducts = <int, List<ServiceReportItemProduct>>{};
        for (var product in products) {
          if (!groupedProducts.containsKey(product.groupIndex)) {
            groupedProducts[product.groupIndex] = [];
          }
          groupedProducts[product.groupIndex]!.add(product);
        }

        final sortedIndices = groupedProducts.keys.toList()..sort();
        final displayProducts = sortedIndices
            .take(3)
            .map(
              (idx) => MapEntry(
                groupedProducts[idx]!.first.name,
                groupedProducts[idx]!,
              ),
            )
            .toList();

        // Group Services for display by index
        final sortedServices = [...services]
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        final displayServices = sortedServices.take(3).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 0. Info Section (Status & Last Mod)
              _buildInfoCard(context, report, status),
              const SizedBox(height: 16),

              // 1. Cliente Section
              _buildSectionHeader(context, Icons.people, 'Cliente'),
              _buildClientCard(context, report.clientName, report.contactName),
              const SizedBox(height: 16),

              // 2. Informe
              _buildSectionHeader(
                context,
                Icons.assignment_outlined,
                'Informe',
              ),
              _buildTechnicalCard(context, report, intervention),
              const SizedBox(height: 16),

              // 3. Reporte Económico Section
              _buildSectionHeader(context, Icons.calculate, 'Costos'),
              _buildReportCard(
                context,
                groupedProducts.length,
                services.length,
                productsSubtotal,
                servicesSubtotal,
                totalSales,
                taxAmount,
                taxRateDisplay,
                finalTotal,
                displayProducts,
                displayServices,
              ),
              const SizedBox(height: 16),

              // 4. Rentabilidad Section
              _buildSectionHeader(context, Icons.bar_chart, 'Rentabilidad'),
              _buildUtilityCard(
                context,
                totalSales,
                totalCosts,
                estimatedProfit,
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    ServiceReport report,
    ServiceReportStatus status,
  ) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy - hh:mm a');

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
                Icon(Symbols.update, size: 20, color: colors.onSurfaceVariant),
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
                  dateFormat.format(report.updatedAt.toLocal()),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, ServiceReportStatus status) {
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

  Widget _buildTechnicalCard(
    BuildContext context,
    ServiceReport report,
    InterventionType intervention,
  ) {
    final colors = Theme.of(context).colorScheme;
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
              intervention.icon,
              'Tipo de servicio',
              intervention.label,
              isTextValue: true,
            ),
            if (report.categoryName != null &&
                report.categoryName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                Icons.category_outlined,
                'Categoría',
                report.categoryName!,
                isTextValue: true,
              ),
            ],
            ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                Icons.calendar_today_outlined,
                'Fecha de ejecución',
                DateFormat('dd/MM/yyyy').format(report.serviceDate.toLocal()),
                isTextValue: true,
              ),
            ],
            if (report.advisorName != null &&
                report.advisorName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                Icons.badge_outlined,
                'Técnico(s)',
                report.advisorName!,
                isTextValue: true,
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onNavigateToTab(0), // Informe Tab
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                label: const Text(
                  'Ir a informe',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(
    BuildContext context,
    String? clientName,
    String? contactName,
  ) {
    final colors = Theme.of(context).colorScheme;
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
              clientName ?? 'No seleccionado',
              isTextValue: true,
            ),
            if (contactName != null &&
                contactName.isNotEmpty &&
                contactName != clientName) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                Icons.person_outline,
                'Contacto',
                contactName,
                isTextValue: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    int totalGroupedProducts,
    int servicesCount,
    double productsSubtotal,
    double servicesSubtotal,
    double totalSales,
    double taxAmount,
    double taxRateDisplay,
    double finalTotal,
    List<MapEntry<String, List<ServiceReportItemProduct>>> displayProducts,
    List<ServiceReportItemService> displayServices,
  ) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            // Products
            if (totalGroupedProducts > 0) ...[
              _buildHeaderRow(
                context,
                Icons.inventory_2_outlined,
                'Productos',
                groupedCount: totalGroupedProducts,
                amount: CurrencyFormatter.format(productsSubtotal),
              ),
              const SizedBox(height: 8),
              ...displayProducts.map((entry) {
                final name = entry.key;
                final items = entry.value;
                double totalQty = 0;
                for (var item in items) {
                  totalQty += item.quantity;
                }
                final uomStr = items.first.uom;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0, left: 24.0),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${totalQty.toInt()} $uomStr: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: name,
                          style: TextStyle(color: colors.onSurfaceVariant),
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
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            // Services
            if (servicesCount > 0) ...[
              _buildHeaderRow(
                context,
                Icons.handyman_outlined,
                'Servicios',
                groupedCount: servicesCount,
                amount: CurrencyFormatter.format(servicesSubtotal),
              ),
              const SizedBox(height: 8),
              ...displayServices.map((service) {
                final String rateStr = service.rateSymbol;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0, left: 24.0),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${service.quantity.toInt()} $rateStr: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: service.name,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (servicesCount > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => onNavigateToTab(2), // Services Tab
                    icon: const Icon(Icons.arrow_forward_ios, size: 14),
                    label: const Text(
                      'Ir a servicios',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),

            // Totals
            _buildRowText(
              'Sub-Total',
              CurrencyFormatter.format(totalSales),
              isBold: true,
              icon: Icons.attach_money,
            ),
            const SizedBox(height: 8),
            _buildRowText(
              'IVA (${taxRateDisplay.toStringAsFixed(0)}%)',
              CurrencyFormatter.format(taxAmount),
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

  Widget _buildUtilityCard(
    BuildContext context,
    double sales,
    double costs,
    double profit,
  ) {
    final colors = Theme.of(context).colorScheme;
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
              Icons.sell_outlined,
              'Venta',
              CurrencyFormatter.format(sales),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              context,
              Icons.payments_outlined,
              'Costos',
              CurrencyFormatter.format(costs),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              context,
              Icons.trending_up,
              'Ganancia estimada',
              CurrencyFormatter.format(profit),
              valueStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.green,
              ),
              iconColor: Colors.green,
            ),
          ],
        ),
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
