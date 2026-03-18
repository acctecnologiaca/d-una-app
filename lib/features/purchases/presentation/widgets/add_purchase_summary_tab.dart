import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';
import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';

class AddPurchaseSummaryTab extends ConsumerWidget {
  final Function(int) onNavigateToTab;

  const AddPurchaseSummaryTab({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPurchaseProvider);
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            context,
            title: 'Detalles del documento',
            onEdit: () => onNavigateToTab(0),
            child: Column(
              children: [
                _buildInfoRow('Proveedor', state.supplierName ?? 'No seleccionado'),
                _buildInfoRow('Documento', '${state.documentType} ${state.documentNumber ?? ""}'),
                _buildInfoRow('Fecha', state.date.toString().split(' ')[0]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            title: 'Productos (${state.products.length})',
            onEdit: () => onNavigateToTab(1),
            child: Column(
              children: [
                ...state.products.map((p) => _buildInfoRow(
                  p.name,
                  '${p.quantity} x ${CurrencyFormatter.format(p.unitPrice)}',
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: colors.primaryContainer.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTotalRow('Subtotal', state.subtotal, colors.onSurfaceVariant),
                  _buildTotalRow('I.V.A (0%)', state.tax, colors.onSurfaceVariant),
                  const Divider(height: 24),
                  _buildTotalRow('Total', state.total, colors.primary, isBold: true, fontSize: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: state.isLoading ? null : () async {
              final success = await ref.read(addPurchaseProvider.notifier).createPurchase();
              if (success && context.mounted) {
                context.pop(); // Close add screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Compra registrada exitosamente')),
                );
              } else if (state.error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${state.error}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: state.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Registrar Compra', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required Widget child, required VoidCallback onEdit}) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurfaceVariant)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, Color color, {bool isBold = false, double fontSize = 16}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color),
        ),
      ],
    );
  }
}
