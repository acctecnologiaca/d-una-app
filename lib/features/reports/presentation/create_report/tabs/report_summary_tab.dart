import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/create_report_provider.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../domain/models/service_report_model.dart';
import '../../../data/models/service_report.dart';

class ReportSummaryTab extends ConsumerWidget {
  final Function(int) onNavigateToTab;

  const ReportSummaryTab({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createReportProvider);
    final colors = Theme.of(context).colorScheme;

    if (state.products.isEmpty && state.services.isEmpty && state.clientId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin datos que mostrar',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final taxRateDisplay = state.globalTaxRate > 1
        ? state.globalTaxRate
        : state.globalTaxRate * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 0. Info Section (si se está editando)
          if (state.report != null) ...[
            _buildInfoCard(context, state.report!),
            const SizedBox(height: 16),
          ],

          // 1. Ficha Técnica Section
          _buildSectionHeader(context, Icons.assignment_outlined, 'Ficha Técnica'),
          _buildReportSummaryCard(context, state),
          const SizedBox(height: 16),

          // 2. Cliente Section
          _buildSectionHeader(context, Icons.people_outline, 'Cliente'),
          _buildClientCard(context, state),
          const SizedBox(height: 16),

          // 3. Resumen Económico
          _buildSectionHeader(context, Icons.calculate_outlined, 'Liquidación y Cobro'),
          _buildFinancialCard(
            context,
            state,
            taxRateDisplay,
          ),
          const SizedBox(height: 16),

          // 4. Tarjeta Confidencial del Técnico
          _buildConfidentialProfitCard(context, state),
          const SizedBox(height: 16),

          // 5. Checklist de Completitud
          _buildChecklistCard(context, state),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ServiceReport report) {
    final colors = Theme.of(context).colorScheme;
    final status = ServiceReportStatus.fromDbValue(report.status);

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
              'Emisión: ${DateFormat('dd/MM/yyyy').format(report.serviceDate)}',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSummaryCard(
      BuildContext context, ServiceReportCreateState state) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onNavigateToTab(0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(state.interventionType.icon,
                      size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    state.interventionType.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                      fontSize: 13,
                    ),
                  ),
                  if (state.categoryName != null) ...[
                    Text(' • ', style: TextStyle(color: colors.outline)),
                    Text(
                      state.categoryName!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.edit_outlined, size: 16, color: colors.outline),
                ],
              ),
              const Divider(height: 20),
              if (state.requestDescription.isNotEmpty) ...[
                Text(
                  'Solicitud:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  state.requestDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],
              if (state.workDescription.isNotEmpty) ...[
                Text(
                  'Diagnóstico y Trabajo:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  state.workDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ] else ...[
                Text(
                  '⚠️ Sin diagnóstico / trabajo especificado',
                  style: TextStyle(fontSize: 12, color: colors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, ServiceReportCreateState state) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onNavigateToTab(1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                child: Icon(Icons.person, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.clientName ?? 'Seleccionar Cliente',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (state.contactName != null)
                      Text(
                        'Contacto: ${state.contactName}',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialCard(
    BuildContext context,
    ServiceReportCreateState state,
    double taxRateDisplay,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAmountRow(
              'Mano de Obra (${state.services.length} servicios)',
              CurrencyFormatter.format(state.servicesSubtotal),
              onTap: () => onNavigateToTab(2),
            ),
            const SizedBox(height: 8),
            _buildAmountRow(
              'Materiales/Repuestos (${state.products.length} ítems)',
              CurrencyFormatter.format(state.productsSubtotal),
              onTap: () => onNavigateToTab(3),
            ),
            const Divider(height: 20),
            _buildAmountRow(
              'Subtotal',
              CurrencyFormatter.format(state.totalSales),
            ),
            const SizedBox(height: 8),
            _buildAmountRow(
              'IVA (${taxRateDisplay.toStringAsFixed(0)}%)',
              CurrencyFormatter.format(state.taxAmount),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL A COBRAR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  CurrencyFormatter.format(state.finalTotal),
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

  Widget _buildAmountRow(String label, String amount, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildConfidentialProfitCard(
      BuildContext context, ServiceReportCreateState state) {
    final colors = Theme.of(context).colorScheme;
    final profitMarginPercent = state.totalSales > 0
        ? (state.estimatedProfit / state.totalSales) * 100
        : 0.0;

    return Card(
      elevation: 0,
      color: colors.secondaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: colors.onSecondaryContainer),
                const SizedBox(width: 6),
                Text(
                  'Vista Confidencial del Técnico',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Costos Propios:',
                      style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                    ),
                    Text(
                      CurrencyFormatter.format(state.totalCosts),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Utilidad Neta Estimada:',
                      style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                    ),
                    Text(
                      '${CurrencyFormatter.format(state.estimatedProfit)} (${profitMarginPercent.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: state.estimatedProfit >= 0 ? Colors.green.shade700 : colors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard(
      BuildContext context, ServiceReportCreateState state) {
    final colors = Theme.of(context).colorScheme;

    final hasClient = state.clientId != null;
    final hasCategory = state.categoryId != null;
    final hasAdvisor = state.advisorId != null;
    final hasWork = state.workDescription.trim().isNotEmpty;
    final hasItems = state.products.isNotEmpty || state.services.isNotEmpty;
    final hasConditions = state.conditions.isNotEmpty;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verificación para Finalizar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            _buildChecklistItem('Cliente asignado', hasClient, () => onNavigateToTab(1)),
            _buildChecklistItem('Categoría técnica seleccionada', hasCategory, () => onNavigateToTab(0)),
            _buildChecklistItem('Técnico responsable asignado', hasAdvisor, () => onNavigateToTab(0)),
            _buildChecklistItem('Diagnóstico y trabajo detallado', hasWork, () => onNavigateToTab(0)),
            _buildChecklistItem('Mano de obra o repuestos agregados', hasItems, () => onNavigateToTab(2)),
            _buildChecklistItem('Condiciones y garantías incluidas', hasConditions, () => onNavigateToTab(4)),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isCompleted, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: isCompleted ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted ? null : Colors.grey.shade600,
                  decoration: isCompleted ? null : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
