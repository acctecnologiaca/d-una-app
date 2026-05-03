import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/create_quote_provider.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../domain/models/quote_model.dart';
import '../../../data/models/quote.dart' as data;
import '../../../data/models/quote_item_product.dart';
import '../../../data/models/quote_item_service.dart';

class QuoteSummaryTab extends ConsumerWidget {
  final Function(int) onNavigateToTab;

  const QuoteSummaryTab({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createQuoteProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Check if empty
    if (state.products.isEmpty && state.services.isEmpty) {
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

    // Group Products for display by index
    final groupedProducts = <int, List<QuoteItemProduct>>{};
    for (var product in state.products) {
      if (!groupedProducts.containsKey(product.groupIndex)) {
        groupedProducts[product.groupIndex] = [];
      }
      groupedProducts[product.groupIndex]!.add(product);
    }

    final sortedIndices = groupedProducts.keys.toList()..sort();
    final displayProducts = sortedIndices
        .take(3)
        .map(
          (idx) =>
              MapEntry(groupedProducts[idx]!.first.name, groupedProducts[idx]!),
        )
        .toList();
    final totalGroupedProducts = sortedIndices.length;

    // Group Services for display by index
    final displayServices = [...state.services]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final finalDisplayServices = displayServices.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 0. Info Section (Status & Last Mod) - Only if editing existing quote
          if (state.quote != null) ...[
            _buildInfoCard(context, state.quote!),
            const SizedBox(height: 16),
          ],

          // 1. Utilidad Section
          _buildSectionHeader(context, Icons.bar_chart, 'Rentabilidad'),
          _buildUtilityCard(
            context,
            state.totalSales,
            state.totalCosts,
            state.estimatedProfit,
          ),
          const SizedBox(height: 16),

          // 2. Cliente Section
          _buildSectionHeader(context, Icons.people, 'Cliente'),
          _buildClientCard(context, state),
          const SizedBox(height: 16),

          // 3. Cotización Section
          _buildSectionHeader(context, Icons.calculate, 'Cotización'),
          _buildQuoteCard(
            context,
            state,
            state.productsSubtotal,
            state.servicesSubtotal,
            state.totalSales,
            state.taxAmount,
            taxRateDisplay,
            state.finalTotal,
            displayProducts,
            finalDisplayServices,
            totalGroupedProducts,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, data.Quote quote) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy - hh:mm a');
    final status = QuoteStatus.fromDbValue(quote.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                  dateFormat.format(quote.updatedAt.toLocal()),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, QuoteStatus status) {
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

  Widget _buildClientCard(BuildContext context, QuoteState state) {
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
              state.clientName ?? 'No seleccionado',
              isTextValue: true,
            ),
            if (state.contactName != null &&
                state.contactName!.isNotEmpty &&
                state.contactName != state.clientName) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                Icons.person_outline,
                'Contacto',
                state.contactName!,
                isTextValue: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(
    BuildContext context,
    QuoteState state,
    double productsSubtotal,
    double servicesSubtotal,
    double totalSales,
    double taxAmount,
    double taxRateDisplay,
    double finalTotal,
    List<MapEntry<String, List<QuoteItemProduct>>> displayProducts,
    List<QuoteItemService> displayServices,
    int totalGroupedProducts,
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
            if (totalGroupedProducts > 3)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onNavigateToTab(0), // Products Tab
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

            const SizedBox(height: 16),

            // Services
            _buildHeaderRow(
              context,
              Icons.handyman_outlined,
              'Servicios',
              groupedCount: state.services.length,
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
            if (state.services.length > 3)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onNavigateToTab(1), // Services Tab
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
                  ),
                ),
              ],
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
