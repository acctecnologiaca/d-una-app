import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/features/portfolio/data/models/uom_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/register_serials_dialog.dart';

class AddPurchaseProductDetailsSheet extends ConsumerStatefulWidget {
  final Product product;

  const AddPurchaseProductDetailsSheet({super.key, required this.product});

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required Product product,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddPurchaseProductDetailsSheet(product: product),
      ),
    );
  }

  @override
  ConsumerState<AddPurchaseProductDetailsSheet> createState() =>
      _AddPurchaseProductDetailsSheetState();
}

class _AddPurchaseProductDetailsSheetState
    extends ConsumerState<AddPurchaseProductDetailsSheet> {
  final _quantityController = TextEditingController(text: '1');
  final _costController = TextEditingController();
  final _warrantyQtyController = TextEditingController(text: '1');

  Uom? _selectedUom;
  bool _noWarranty = false;
  String _warrantyPeriod = 'Años';
  bool _noSerials = false;

  @override
  void initState() {
    super.initState();
    _selectedUom = widget.product.uomModel;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _warrantyQtyController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    final qty = double.tryParse(_quantityController.text) ?? 1;
    final cost =
        double.tryParse(_costController.text.replaceAll(',', '.')) ?? 0;
    final wQty = int.tryParse(_warrantyQtyController.text) ?? 0;

    bool finalUsesSerials = !_noSerials;
    bool registerSerialsNow = false;

    if (finalUsesSerials) {
      final result = await RegisterSerialsDialog.show(context);

      if (result == null) {
        return; // User dismissed
      }

      switch (result) {
        case RegisterSerialsResult.now:
          registerSerialsNow = true;
          break;
        case RegisterSerialsResult.later:
          registerSerialsNow = false;
          break;
        case RegisterSerialsResult.never:
          finalUsesSerials = false;
          registerSerialsNow = false;
          break;
      }
    }

    if (context.mounted) {
      context.pop({
        'product': widget.product,
        'quantity': qty,
        'uom': _selectedUom,
        'cost_price': cost,
        'has_warranty': !_noWarranty,
        'warranty_duration': wQty,
        'warranty_period': _warrantyPeriod,
        'uses_serials': finalUsesSerials,
        'register_serials_now': registerSerialsNow,
      });
    }
  }

  void _showAddUomDialog() {
    // Scaffold UI or navigate to create UOM if supported.
    // For now we simulate or call a dialog. The requirement is just an active "add" button on the dropdown.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función para agregar medida en desarrollo'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final uomsAsync = ref.watch(uomsProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: colors.onSurface),
                  onPressed: () => context.pop(),
                  alignment: Alignment.topLeft,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.brand?.name ?? 'Sin marca',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.product.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.product.model ?? 'Sin modelo',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Cantidad Comprada Title
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cantidad comprada',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quantity and UOM Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: CustomTextField(
                    label: 'Cantidad',
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: uomsAsync.when(
                    data: (uoms) => CustomDropdown<Uom>(
                      value: _selectedUom,
                      items: uoms,
                      label: 'Medida',
                      itemLabelBuilder: (u) => u.name,
                      showAddOption: true,
                      addOptionValue: const Uom(
                        id: 'add',
                        name: 'add',
                        symbol: '',
                      ), // Dummy value
                      addOptionLabel: 'Agregar',
                      onAddPressed: _showAddUomDialog,
                      searchable: true,
                      onChanged: (val) {
                        if (val != null && val.id != 'add') {
                          setState(() {
                            _selectedUom = val;
                          });
                        }
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => const Text('Error loading UOMs'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Precio de Compra Title
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Precio de compra',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cost per unit
            CustomTextField(
              label: 'Costo por unidad',
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixText: '\$   ',
              helperText: 'Sin impuesto',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d*')),
              ],
            ),
            const SizedBox(height: 24),

            // Garantía Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Este producto no tiene garantía',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _noWarranty,
                  onChanged: (val) {
                    setState(() {
                      _noWarranty = val;
                    });
                  },
                ),
              ],
            ),

            if (!_noWarranty) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: CustomTextField(
                      label: 'Cantidad',
                      controller: _warrantyQtyController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: CustomDropdown<String>(
                      value: _warrantyPeriod,
                      items: const ['Días', 'Meses', 'Años'],
                      label: 'Período',
                      itemLabelBuilder: (p) => p,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _warrantyPeriod = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Serials Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Este producto no usa seriales',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _noSerials,
                  onChanged: (val) {
                    setState(() {
                      _noSerials = val;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Action Buttons
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 150,
                child: CustomButton(
                  text: 'Confirmar',
                  onPressed: _onConfirm,
                  isFullWidth: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
