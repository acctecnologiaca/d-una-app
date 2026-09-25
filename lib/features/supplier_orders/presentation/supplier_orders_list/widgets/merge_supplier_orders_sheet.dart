import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';
import '../../../domain/models/supplier_order.dart';
import '../../../domain/utils/oc_credit_helper.dart';
import '../../../domain/utils/supplier_order_merge_validator.dart';

class MergeSupplierOrdersConfig {
  final String primaryOrderId;
  final String? targetBranchId;
  final String? targetPaymentMethod;

  const MergeSupplierOrdersConfig({
    required this.primaryOrderId,
    this.targetBranchId,
    this.targetPaymentMethod,
  });
}

class MergeSupplierOrdersSheet extends StatefulWidget {
  final List<SupplierOrder> selectedOrders;

  const MergeSupplierOrdersSheet({super.key, required this.selectedOrders});

  static Future<MergeSupplierOrdersConfig?> show({
    required BuildContext context,
    required List<SupplierOrder> selectedOrders,
  }) async {
    return showModalBottomSheet<MergeSupplierOrdersConfig>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) =>
          MergeSupplierOrdersSheet(selectedOrders: selectedOrders),
    );
  }

  @override
  State<MergeSupplierOrdersSheet> createState() =>
      _MergeSupplierOrdersSheetState();
}

class _MergeSupplierOrdersSheetState extends State<MergeSupplierOrdersSheet> {
  late String _selectedPrimaryOrderId;
  String? _selectedBranchId;
  String? _selectedPaymentMethod;
  late final SupplierOrderMergeValidationResult _validation;
  late final List<SupplierOrder> _sortedOrders;

  @override
  void initState() {
    super.initState();
    _validation = SupplierOrderMergeValidator.validate(widget.selectedOrders);
    _sortedOrders = List<SupplierOrder>.from(widget.selectedOrders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _selectedPrimaryOrderId = _sortedOrders.first.id;
    _updateDefaultsForPrimary(_selectedPrimaryOrderId);
  }

  void _updateDefaultsForPrimary(String primaryId) {
    final primary = widget.selectedOrders.firstWhere(
      (o) => o.id == primaryId,
      orElse: () => _sortedOrders.first,
    );
    _selectedBranchId = primary.supplierBranchId;
    _selectedPaymentMethod = primary.paymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final supplierName = widget.selectedOrders.first.supplierName;
    final combinedTotal = widget.selectedOrders.fold<double>(
      0.0,
      (sum, o) => sum + o.total,
    );

    final projectedCredits = OCCreditHelper.calculateEarnedCredits(
      combinedTotal,
    );
    final reachesCap = projectedCredits >= OCCreditHelper.maxCreditsPerOrder;

    // Obtener opciones de sucursales disponibles
    final Map<String, String> branchOptions = {};
    for (final o in widget.selectedOrders) {
      if (o.supplierBranchId != null && o.supplierBranchId!.isNotEmpty) {
        branchOptions[o.supplierBranchId!] =
            o.branchName ?? 'Sucursal ${o.supplierBranchId!.substring(0, 6)}';
      }
    }

    // Obtener opciones de métodos de pago disponibles
    final Set<String> paymentOptions = {};
    for (final o in widget.selectedOrders) {
      if (o.paymentMethod != null && o.paymentMethod!.trim().isNotEmpty) {
        paymentOptions.add(o.paymentMethod!.trim());
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
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

              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      icon: const Icon(Icons.close),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consolidar órdenes de compra',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Symbols.warehouse,
                                size: 16,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  supplierName,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(indent: 16, endIndent: 16),
              const SizedBox(height: 16),

              // Main Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title: Órdenes a Consolidar
                    _buildSectionTitle(
                      context,
                      'Selecciona la Orden Principal',
                      Symbols.shopping_cart,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toca la orden que conservará su número. Las demás se integrarán a esta:',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Orders List con selección interactiva de Principal
                    ..._sortedOrders.map((order) {
                      final isPrimary = order.id == _selectedPrimaryOrderId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPrimaryOrderId = order.id;
                              _updateDefaultsForPrimary(order.id);
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isPrimary
                                  ? colors.primaryContainer.withValues(
                                      alpha: 0.25,
                                    )
                                  : colors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isPrimary
                                    ? colors.primary
                                    : colors.outlineVariant.withValues(
                                        alpha: 0.5,
                                      ),
                                width: isPrimary ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isPrimary
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: isPrimary
                                          ? colors.primary
                                          : colors.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      order.orderNumber,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isPrimary
                                            ? colors.primary
                                            : colors.onSurface,
                                      ),
                                    ),
                                    if (isPrimary) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'Principal',
                                          style: textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colors.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  CurrencyFormatter.format(order.total),
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Resolución de conflicto de Sucursal (si aplica)
                    if (_validation.hasBranchConflict &&
                        branchOptions.length > 1) ...[
                      const SizedBox(height: 16),
                      _buildSectionTitle(
                        context,
                        'Sucursal de Destino',
                        Symbols.store,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: branchOptions.containsKey(_selectedBranchId)
                                ? _selectedBranchId
                                : branchOptions.keys.first,
                            items: branchOptions.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  style: textTheme.bodyMedium,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedBranchId = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ],

                    // Resolución de conflicto de Método de Pago (si aplica)
                    if (_validation.hasPaymentMethodConflict &&
                        paymentOptions.length > 1) ...[
                      const SizedBox(height: 16),
                      _buildSectionTitle(
                        context,
                        'Método de Pago Consolidado',
                        Symbols.payments,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value:
                                paymentOptions.contains(_selectedPaymentMethod)
                                ? _selectedPaymentMethod
                                : paymentOptions.first,
                            items: paymentOptions.map((pm) {
                              return DropdownMenuItem<String>(
                                value: pm,
                                child: Text(pm, style: textTheme.bodyMedium),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedPaymentMethod = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Section Title: Resumen Financiero
                    _buildSectionTitle(
                      context,
                      'Resumen Financiero',
                      Symbols.account_balance_wallet,
                    ),
                    const SizedBox(height: 12),

                    // Highlight Financial Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Symbols.account_balance_wallet,
                              color: colors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Consolidado',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(combinedTotal),
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Proyección de Créditos del Sistema
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Symbols.stars, color: colors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recompensa de la plataforma:',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reachesCap
                                      ? '$projectedCredits créditos ganados al finalizar (Tope máx. 15 alcanzado)'
                                      : '$projectedCredits créditos ganados al finalizar (1 por cada \$10 USD)',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Button: Right-aligned FilledButton without icon
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            MergeSupplierOrdersConfig(
                              primaryOrderId: _selectedPrimaryOrderId,
                              targetBranchId: _selectedBranchId,
                              targetPaymentMethod: _selectedPaymentMethod,
                            ),
                          );
                        },
                        child: const Text('Consolidar'),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
