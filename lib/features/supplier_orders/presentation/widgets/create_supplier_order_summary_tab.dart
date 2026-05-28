import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../providers/create_supplier_order_provider.dart';

class CreateSupplierOrderSummaryTab extends ConsumerWidget {
  final Function(int) onNavigateToTab;

  const CreateSupplierOrderSummaryTab({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createSupplierOrderProvider);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Summary Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles de la Orden',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow('Proveedor:', state.supplierName ?? 'No seleccionado'),
                        _buildInfoRow('Sucursal:', state.branchName ?? 'Ninguna'),
                        _buildInfoRow('Método de Envío:', state.shippingMethodLabel ?? 'No seleccionado'),
                        _buildInfoRow('Colaborador Receptor:', state.receiverName ?? 'No seleccionado'),
                        _buildInfoRow('Condiciones:', state.paymentMethod ?? 'Por definir'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Totals Breakdown Card
                Card(
                  color: colors.primaryContainer.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildTotalRow(context, 'Subtotal:', CurrencyFormatter.format(state.subtotal)),
                        const SizedBox(height: 8),
                        _buildTotalRow(context, 'IVA (0%):', CurrencyFormatter.format(state.tax)),
                        const Divider(height: 24),
                        _buildTotalRow(
                          context,
                          'Total:',
                          CurrencyFormatter.format(state.total),
                          isBold: true,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.error!,
                    style: TextStyle(color: colors.error, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5))),
          ),
          child: FilledButton(
            onPressed: state.isLoading
                ? null
                : () async {
                    final success = await ref.read(createSupplierOrderProvider.notifier).saveOrder();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Orden de compra guardada exitosamente')),
                      );
                      context.pop();
                    }
                  },
            child: state.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Confirmar y Guardar Orden'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, String value, {bool isBold = false, Color? color}) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
          fontSize: isBold ? 18 : 15,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
