import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../domain/models/service_report_model.dart';
import '../providers/view_report_provider.dart';
import '../../../data/models/service_report.dart';

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
        final colors = Theme.of(context).colorScheme;
        final status = ServiceReportStatus.fromDbValue(report.status);
        final intervention =
            InterventionType.fromDbValue(report.interventionType);
        final dateFormat = DateFormat('dd/MM/yyyy');

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 0. Info Section (Status & Date)
              _buildInfoCard(context, report, status, dateFormat),
              const SizedBox(height: 16),

              // 1. Technical Details Section
              _buildSectionHeader(
                context,
                Icons.assignment_outlined,
                'Detalle del servicio',
                onEditTap: () => onNavigateToTab(0),
              ),
              _buildTechnicalCard(context, report, intervention),
              const SizedBox(height: 16),

              // 2. Products Section
              if (report.products != null && report.products!.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  Icons.inventory_2_outlined,
                  'Materiales y repuestos (${report.products!.length})',
                  onEditTap: () => onNavigateToTab(1),
                ),
                _buildProductsCard(context, report),
                const SizedBox(height: 16),
              ],

              // 3. Labor / Services Section
              if (report.services != null && report.services!.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  Icons.handyman_outlined,
                  'Servicios (${report.services!.length})',
                  onEditTap: () => onNavigateToTab(2),
                ),
                _buildServicesCard(context, report),
                const SizedBox(height: 16),
              ],

              // 4. Client Section
              _buildSectionHeader(
                context,
                Icons.people_outline,
                'Cliente',
                onEditTap: () => onNavigateToTab(3),
              ),
              _buildClientCard(context, report.clientName, report.contactName),
              const SizedBox(height: 16),

              // 5. Conditions Section
              if (report.conditions != null &&
                  report.conditions!.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  Icons.description_outlined,
                  'Condiciones (${report.conditions!.length})',
                  onEditTap: () => onNavigateToTab(4),
                ),
                _buildConditionsCard(context, report),
                const SizedBox(height: 16),
              ],

              // 6. Financial Totals
              _buildSectionHeader(
                context,
                Icons.monetization_on_outlined,
                'Totales financieros',
              ),
              _buildFinancialSummaryCard(context, report, colors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onEditTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (onEditTap != null)
            InkWell(
              onTap: onEditTap,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Ver',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    ServiceReport report,
    ServiceReportStatus status,
    DateFormat dateFormat,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: status.statusColor(colors).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(status.iconPath, width: 16, height: 16),
                  const SizedBox(width: 6),
                  Text(
                    status.label,
                    style: TextStyle(
                      color: status.statusColor(colors),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              'Fecha: ${dateFormat.format(report.serviceDate)}',
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(intervention.icon, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  intervention.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                if (report.categoryName != null) ...[
                  Text(' • ', style: TextStyle(color: colors.outlineVariant)),
                  Text(
                    report.categoryName!,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            if (report.advisorName != null) ...[
              const SizedBox(height: 8),
              Text(
                '👨‍🔧 Técnico: ${report.advisorName}',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (report.workDescription != null &&
                report.workDescription!.isNotEmpty) ...[
              const Divider(height: 16),
              Text(
                'Diagnóstico / Trabajo:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                report.workDescription!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clientName ?? 'Cliente General',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (contactName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Contacto: $contactName',
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServicesCard(BuildContext context, ServiceReport report) {
    final colors = Theme.of(context).colorScheme;
    final services = report.services!;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: services.take(3).map((s) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${s.quantity} ${s.rateSymbol} - ${s.name}',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(s.totalPrice),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductsCard(BuildContext context, ServiceReport report) {
    final colors = Theme.of(context).colorScheme;
    final products = report.products!;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: products.take(3).map((p) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${p.quantity} ${p.uom} - ${p.name}',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(p.totalPrice),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildConditionsCard(BuildContext context, ServiceReport report) {
    final colors = Theme.of(context).colorScheme;
    final conditions = report.conditions!;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: conditions.take(2).map((c) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      c.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard(
    BuildContext context,
    ServiceReport report,
    ColorScheme colors,
  ) {
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(
                  CurrencyFormatter.format(report.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IVA:'),
                Text(
                  CurrencyFormatter.format(report.taxAmount),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  CurrencyFormatter.format(report.total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
}
