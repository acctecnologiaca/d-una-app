import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../domain/models/supplier_order_item.dart';
import '../providers/create_supplier_order_provider.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import 'package:d_una_app/features/supplier_orders/domain/models/supplier_order_status.dart';
import 'package:d_una_app/features/supplier_orders/presentation/widgets/supplier_order_credit_banner_card.dart';

class CreateSupplierOrderSummaryTab extends ConsumerWidget {
  final Function(int) onNavigateToTab;
  final bool editMode;

  const CreateSupplierOrderSummaryTab({
    super.key,
    required this.onNavigateToTab,
    this.editMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createSupplierOrderProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Obtener proveedores y resolver nombre formateado
    final suppliers = ref.watch(suppliersProvider).valueOrNull ?? [];
    Supplier? matchedSupplier;
    if (state.supplierId != null) {
      for (final s in suppliers) {
        if (s.id == state.supplierId) {
          matchedSupplier = s;
          break;
        }
      }
    }
    final supplierDisplayName = matchedSupplier != null
        ? matchedSupplier.name
        : (state.supplierName ?? 'No seleccionado');

    // Check if empty
    if (state.items.isEmpty && state.supplierId == null) {
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

    // Group items by product key: "${item.name}|${item.brand ?? ''}|${item.model ?? ''}"
    final Map<String, List<SupplierOrderItem>> groups = {};
    for (final item in state.items) {
      final key = "${item.name}|${item.brand ?? ''}|${item.model ?? ''}";
      groups.putIfAbsent(key, () => []).add(item);
    }

    final sortedKeys = groups.keys.toList()..sort();
    final totalGroupedProducts = sortedKeys.length;

    // Only display top 3 products
    final displayProducts = sortedKeys
        .take(3)
        .map((key) => MapEntry(key, groups[key]!))
        .toList();

    return Scaffold(
      backgroundColor: colors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (matchedSupplier != null &&
                matchedSupplier.minimumPurchaseAmount > 0 &&
                state.subtotal < matchedSupplier.minimumPurchaseAmount) ...[
              Card(
                color: colors.errorContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colors.error),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colors.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El subtotal de esta orden (${CurrencyFormatter.format(state.subtotal)} USD) no alcanza el monto mínimo de compra exigido por el proveedor (${CurrencyFormatter.format(matchedSupplier.minimumPurchaseAmount)} USD).\n\n'
                          'Faltan ${CurrencyFormatter.format(matchedSupplier.minimumPurchaseAmount - state.subtotal)} USD.',
                          style: TextStyle(
                            color: colors.onErrorContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Indicador de créditos generados por esta OC
            SupplierOrderCreditBannerCard(
              orderTotal: state.total,
              status: SupplierOrderStatus.draft,
              isCreateOrEdit: true,
            ),
            const SizedBox(height: 16),
            // 1. Proveedor Section
            _buildSectionHeader(context, Icons.warehouse, 'Proveedor'),
            Card(
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
                      Icons.business,
                      'Nombre',
                      supplierDisplayName,
                      isTextValue: true,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      context,
                      Icons.location_on,
                      'Sucursal',
                      state.branchName ?? 'Ninguna',
                      isTextValue: true,
                    ),
                  ],
                ),
              ),
            ),

            // 4. Pedido Section
            _buildSectionHeader(context, Icons.shopping_cart, 'Pedido'),
            Card(
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
                    _buildHeaderRow(
                      context,
                      Icons.inventory_2_outlined,
                      'Productos',
                      groupedCount: totalGroupedProducts,
                      amount: CurrencyFormatter.format(state.subtotal),
                    ),
                    const SizedBox(height: 8),
                    ...displayProducts.map((entry) {
                      final groupItems = entry.value;
                      final firstItem = groupItems.first;
                      final totalQty = groupItems.fold(
                        0.0,
                        (sum, item) => sum + item.quantity,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0, left: 24.0),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${totalQty.toInt()} ${firstItem.uom}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: firstItem.name,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
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
                          onPressed: () => onNavigateToTab(1), // Products Tab
                          icon: const Icon(Icons.exit_to_app, size: 14),
                          label: const Text(' > Ir a productos'),
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
                    _buildRowText(
                      'Sub-Total',
                      CurrencyFormatter.format(state.subtotal),
                      isBold: true,
                      icon: Icons.attach_money,
                    ),
                    const SizedBox(height: 8),
                    _buildRowText(
                      'IVA (${state.taxRate.toStringAsFixed(0)}%)',
                      CurrencyFormatter.format(state.tax),
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
                          CurrencyFormatter.format(state.total),
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
            ),
            const SizedBox(height: 16),

            // 2. Método de envío Section
            _buildSectionHeader(
              context,
              Icons.local_shipping,
              'Método de envío',
            ),
            Card(
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
                      Icons.info_outline,
                      'Método',
                      state.shippingMethodLabel ?? 'No seleccionado',
                      isTextValue: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Método de pago Section
            _buildSectionHeader(context, Icons.payment, 'Método de pago'),
            Card(
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
                      Icons.account_balance_wallet,
                      'Condición',
                      state.paymentMethod ?? 'Por definir',
                      isTextValue: true,
                    ),
                  ],
                ),
              ),
            ),

            if (state.error != null) ...[
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final branchesAsync = state.supplierId != null
              ? ref.watch(supplierBranchesProvider(state.supplierId!))
              : null;
          final branches = branchesAsync?.valueOrNull ?? [];
          final hasBranches = branches.isNotEmpty;
          final isDetailsValid = state.isDetailsValid(hasBranches: hasBranches);
          final canSave = !state.isLoading &&
              state.items.isNotEmpty &&
              isDetailsValid &&
              (!editMode || state.isDirty);

          return Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: CustomExtendedFab(
              label: state.isLoading ? 'Guardando...' : 'Guardar',
              icon: state.isLoading ? Icons.hourglass_empty : Icons.save_outlined,
              isEnabled: canSave,
              onPressed: () async {
                if (!isDetailsValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor complete todos los campos obligatorios.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                final createdOrderId = await ref
                    .read(createSupplierOrderProvider.notifier)
                    .saveOrder();
                if (!context.mounted) return;
                if (createdOrderId != null) {
                  _showPostSaveOptions(context, ref, createdOrderId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error ?? 'Error al guardar la orden'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _showPostSaveOptions(
    BuildContext context,
    WidgetRef ref,
    String createdOrderId,
  ) {
    CustomActionSheet.show(
      context: context,
      title: 'Orden de compra guardada',
      actions: [
        BottomSheetActionItem(
          icon: Icons.send_outlined,
          label: 'Enviar ahora',
          onTap: () {
            Navigator.pop(context); // Close action sheet
            ref.invalidate(createSupplierOrderProvider);
            context.pushReplacement(
              '/supplier-orders/view/$createdOrderId?triggerSend=true',
            );
          },
        ),
        BottomSheetActionItem(
          icon: Icons.history_outlined,
          label: 'Enviar más tarde',
          onTap: () {
            Navigator.pop(context); // Close action sheet
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Orden de compra guardada exitosamente'),
              ),
            );
            ref.invalidate(createSupplierOrderProvider);
            context.pop(); // Back to list
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
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
