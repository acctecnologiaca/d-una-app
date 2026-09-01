import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/features/portfolio/data/models/uom_model.dart';
import 'package:d_una_app/features/purchases/data/models/purchase_item_product.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/shared/widgets/custom_stepper.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';

class AddPurchaseProductDetailsSheet extends ConsumerStatefulWidget {
  final Product product;
  final PurchaseItemProduct? existingItem;
  final bool isLinkedToOrder;
  final double? initialQuantity;

  const AddPurchaseProductDetailsSheet({
    super.key,
    required this.product,
    this.existingItem,
    this.isLinkedToOrder = false,
    this.initialQuantity,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required Product product,
    PurchaseItemProduct? existingItem,
    bool isLinkedToOrder = false,
    double? initialQuantity,
  }) {
    final sheetKey = GlobalKey<_AddPurchaseProductDetailsSheetState>();

    return CustomActionSheet.show<Map<String, dynamic>>(
      context: context,
      title: 'Detalles de compra',
      isContentScrollable: true,
      content: AddPurchaseProductDetailsSheet(
        key: sheetKey,
        product: product,
        existingItem: existingItem,
        isLinkedToOrder: isLinkedToOrder,
        initialQuantity: initialQuantity,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomButton(
                text: 'Confirmar',
                isFullWidth: false,
                onPressed: () => sheetKey.currentState?.onConfirm(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  ConsumerState<AddPurchaseProductDetailsSheet> createState() =>
      _AddPurchaseProductDetailsSheetState();
}

class _AddPurchaseProductDetailsSheetState
    extends ConsumerState<AddPurchaseProductDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _warrantyQtyController = TextEditingController(text: '12');

  Uom? _selectedUom;
  bool _noWarranty = false;
  String _warrantyPeriod = 'Meses';
  bool _noSerials = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _costController.text = CurrencyFormatter.format(item.unitPrice);
      _warrantyQtyController.text = (item.warrantyTime ?? 1).toString();
      _noWarranty = item.warrantyTime == null || item.warrantyTime == 0;

      // Map back unit
      if (item.warrantyUnit == 'days') {
        _warrantyPeriod = 'Días';
      } else if (item.warrantyUnit == 'months') {
        _warrantyPeriod = 'Meses';
      } else if (item.warrantyUnit == 'years') {
        _warrantyPeriod = 'Años';
      }

      _noSerials = !item.requiresSerials;
    } else {
      if (widget.product.averageCost > 0) {
        _costController.text =
            CurrencyFormatter.format(widget.product.averageCost);
      }
      // Default to inverted values from product catalog settings
      _noWarranty = !widget.product.hasWarranty;
      _noSerials = !widget.product.requiresSerials;
    }
    _selectedUom = widget.product.uomModel;
  }

  @override
  void dispose() {
    _costController.dispose();
    _warrantyQtyController.dispose();
    super.dispose();
  }

  void _incrementWarranty() {
    final current = int.tryParse(_warrantyQtyController.text) ?? 0;
    setState(() {
      _warrantyQtyController.text = (current + 1).toString();
    });
  }

  void _decrementWarranty() {
    final current = int.tryParse(_warrantyQtyController.text) ?? 1;
    if (current > 1) {
      setState(() {
        _warrantyQtyController.text = (current - 1).toString();
      });
    }
  }

  Future<void> onConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    final qty =
        widget.initialQuantity ?? (widget.existingItem?.quantity ?? 1.0);
    final cost = CurrencyFormatter.parse(_costController.text) ?? 0;
    final wQty = _noWarranty
        ? 0
        : (int.tryParse(_warrantyQtyController.text) ?? 0);
    final wPeriod = _noWarranty ? 'Días' : _warrantyPeriod;

    bool finalUsesSerials = !_noSerials;
    bool needsToAskSerials = false;

    if (finalUsesSerials &&
        (widget.existingItem == null ||
            !widget.existingItem!.requiresSerials)) {
      needsToAskSerials = true;
    }

    if (mounted) {
      context.pop({
        'product': widget.product,
        'quantity': qty,
        'uom': _selectedUom,
        'cost_price': cost,
        'has_warranty': !_noWarranty,
        'warranty_duration': wQty,
        'warranty_period': wPeriod,
        'uses_serials': finalUsesSerials,
        'needs_to_ask_serials': needsToAskSerials,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            label: 'Costo unitario*',
            controller: _costController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: '\$   ',
            helperText: 'Sin impuesto',
            inputFormatters: [CurrencyInputFormatter()],
            enabled: !widget.isLinkedToOrder,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El costo es obligatorio';
              }
              final price = CurrencyFormatter.parse(value);
              if (price == null || price <= 0) {
                return 'Ingresa un costo válido';
              }
              return null;
            },
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: CustomStepper(
                    label: 'Cantidad*',
                    controller: _warrantyQtyController,
                    onIncrement: _incrementWarranty,
                    onDecrement: _decrementWarranty,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
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
        ],
      ),
    );
  }
}
