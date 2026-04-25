import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../providers/view_quote_provider.dart';
import '../../../data/models/quote_item_product.dart';
import '../../../data/models/quote_item_service.dart';

class ViewQuoteSummaryTab extends ConsumerWidget {
  final String quoteId;
  final Function(int) onNavigateToTab;

  const ViewQuoteSummaryTab({
    super.key,
    required this.quoteId,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(viewQuoteProvider(quoteId));

    if (state.isLoading && state.quote == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final quote = state.quote;
    if (quote == null) {
      return const Center(child: Text('No hay datos que mostrar'));
    }

    // Calculations
    double productsSubtotal = 0;
    double productsCost = 0;
    for (var p in state.products) {
      productsSubtotal += p.unitPrice * p.quantity;
      productsCost += p.costPrice * p.quantity;
    }

    double servicesSubtotal = 0;
    double servicesCost = 0;
    for (var s in state.services) {
      servicesSubtotal += s.unitPrice * s.quantity;
      servicesCost += s.costPrice * s.quantity;
    }

    final totalSales = productsSubtotal + servicesSubtotal;
    final totalCosts = productsCost + servicesCost;
    final estimatedProfit = totalSales - totalCosts;

    // Use tax amount from quote or calculate it
    final taxAmount = quote.taxAmount;
    final finalTotal = quote.total;
    // Calculate percentage for display
    final taxRateDisplay = totalSales > 0
        ? (taxAmount / totalSales) * 100
        : 0.0;

    // Group Products for display
    final groupedProducts = <String, List<QuoteItemProduct>>{};
    for (var product in state.products) {
      if (!groupedProducts.containsKey(product.name)) {
        groupedProducts[product.name] = [];
      }
      groupedProducts[product.name]!.add(product);
    }
    final displayProducts = groupedProducts.entries.take(3).toList();

    // Services
    final displayServices = state.services.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Utilidad Section
          _buildSectionHeader(context, Icons.bar_chart, 'Utilidad'),
          _buildUtilityCard(context, totalSales, totalCosts, estimatedProfit),
          const SizedBox(height: 16),

          // 2. Cliente Section
          _buildSectionHeader(context, Icons.people, 'Cliente'),
          _buildClientCard(context, quote.clientName, quote.contactName),
          const SizedBox(height: 16),

          // 3. Cotización Section
          _buildSectionHeader(context, Icons.calculate, 'Cotización'),
          _buildQuoteCard(
            context,
            state.products.length,
            state.services.length,
            productsSubtotal,
            servicesSubtotal,
            totalSales,
            taxAmount,
            taxRateDisplay,
            finalTotal,
            displayProducts,
            displayServices,
          ),
          const SizedBox(height: 40),
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
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildClientCard(
    BuildContext context,
    String? clientName,
    String? contactName,
  ) {
    final colors = Theme.of(context).colorScheme;
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
            _buildSummaryRow(
              context,
              Icons.domain,
              'Razón social',
              clientName ?? 'No especificado',
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

  Widget _buildQuoteCard(
    BuildContext context,
    int productsCount,
    int servicesCount,
    double productsSubtotal,
    double servicesSubtotal,
    double totalSales,
    double taxAmount,
    double taxRateDisplay,
    double finalTotal,
    List<MapEntry<String, List<QuoteItemProduct>>> displayProducts,
    List<QuoteItemService> displayServices,
  ) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Products
            _buildHeaderRow(
              context,
              Icons.inventory_2_outlined,
              'Productos',
              groupedCount: productsCount,
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
            if (productsCount > 3)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onNavigateToTab(0),
                  icon: const Icon(Icons.arrow_forward_ios, size: 14),
                  label: const Text('Ver todos...'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Services
            _buildHeaderRow(
              context,
              Icons.handyman_outlined,
              'Servicios',
              groupedCount: servicesCount,
              amount: CurrencyFormatter.format(servicesSubtotal),
            ),
            const SizedBox(height: 8),
            ...displayServices.map((service) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0, left: 24.0),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            '${service.quantity.toInt()} ${service.rateSymbol}: ',
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
            if (servicesCount > 3)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onNavigateToTab(1),
                  icon: const Icon(Icons.arrow_forward_ios, size: 14),
                  label: const Text('Ver todos...'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
