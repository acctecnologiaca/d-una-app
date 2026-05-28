import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../domain/models/supplier_order.dart';
import '../../domain/models/supplier_order_status.dart';
import '../providers/supplier_orders_providers.dart';

class ViewSupplierOrderSummaryTab extends ConsumerStatefulWidget {
  final SupplierOrder order;
  final Function(int) onNavigateToTab;

  const ViewSupplierOrderSummaryTab({
    super.key,
    required this.order,
    required this.onNavigateToTab,
  });

  @override
  ConsumerState<ViewSupplierOrderSummaryTab> createState() => _ViewSupplierOrderSummaryTabState();
}

class _ViewSupplierOrderSummaryTabState extends ConsumerState<ViewSupplierOrderSummaryTab> {
  bool _isLoading = false;

  Future<void> _finalizeOrder() async {
    final colors = Theme.of(context).colorScheme;

    // 1. Pick Photo from Camera
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return; // cancelled
    final photoFile = File(pickedFile.path);

    if (!mounted) return;

    // 2. Select Document Type Sheet
    final docType = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Seleccione Tipo de Documento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Factura'),
                onTap: () => Navigator.of(context).pop('invoice'),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_outlined),
                title: const Text('Nota de entrega'),
                onTap: () => Navigator.of(context).pop('delivery_note'),
              ),
            ],
          ),
        );
      },
    );

    if (docType == null || !mounted) return;

    // 3. Confirm Purchase Record
    final createPurchaseRecord = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.confirmation(
        icon: Symbols.inventory_2,
        iconColor: colors.primary,
        title: 'Registrar en Inventario',
        contentText: '¿Desea registrar los productos de la orden en el inventario propio? Esto generará un Registro de Compra automáticamente.',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('No, solo finalizar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Sí, registrar compra'),
          ),
        ],
      ),
    );

    if (createPurchaseRecord == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(supplierOrdersRepositoryProvider);
      await repo.finalizeSupplierOrder(
        orderId: widget.order.id,
        photoFile: photoFile,
        documentType: docType,
        createPurchaseRecord: createPurchaseRecord,
      );

      // Invalidate and refresh
      ref.invalidate(paginatedSupplierOrdersProvider);
      ref.invalidate(supplierOrderDetailProvider(widget.order.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden finalizada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al finalizar orden: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final showFinalizeButton = widget.order.status != SupplierOrderStatus.finalized &&
        widget.order.status != SupplierOrderStatus.cancelled;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Supplier card summary
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  color: colors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen del Proveedor',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Proveedor:', style: TextStyle(color: colors.onSurfaceVariant)),
                            Text(widget.order.supplierName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (widget.order.branchName != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Sucursal:', style: TextStyle(color: colors.onSurfaceVariant)),
                              Text(widget.order.branchName!, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Totals summary
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  color: colors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal', style: TextStyle(color: colors.onSurfaceVariant)),
                            Text(CurrencyFormatter.format(widget.order.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('IVA (0%)', style: TextStyle(color: colors.onSurfaceVariant)),
                            Text(CurrencyFormatter.format(widget.order.tax), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              CurrencyFormatter.format(widget.order.total),
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // If invoice photo is available
                if (widget.order.invoicePhotoUrl != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Documento de Soporte',
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.order.invoicePhotoUrl!,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom Action button to finalize
        if (showFinalizeButton)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _finalizeOrder,
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isLoading ? 'Procesando...' : 'Finalizar Orden de Compra'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
      ],
    );
  }
}
