import 'package:d_una_app/core/utils/string_extensions.dart';
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
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/shared/widgets/product_image_avatar.dart';
import 'package:d_una_app/shared/widgets/uom_status_badge.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/register_serials_dialog.dart';

class AddPurchaseProductDetailsSheet extends ConsumerStatefulWidget {
  final Product product;
  final PurchaseItemProduct? existingItem;

  const AddPurchaseProductDetailsSheet({
    super.key,
    required this.product,
    this.existingItem,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required Product product,
    PurchaseItemProduct? existingItem,
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
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _quantityController.text = item.quantity.toInt().toString();
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
    }
    _selectedUom = widget.product.uomModel;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _warrantyQtyController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    final current = double.tryParse(_quantityController.text) ?? 0;
    setState(() {
      _quantityController.text = (current + 1).toStringAsFixed(0);
    });
  }

  void _decrementQuantity() {
    final current = double.tryParse(_quantityController.text) ?? 1;
    if (current > 1) {
      setState(() {
        _quantityController.text = (current - 1).toStringAsFixed(0);
      });
    }
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

    final qty = double.tryParse(_quantityController.text) ?? 1;
    final cost = CurrencyFormatter.parse(_costController.text) ?? 0;
    final wQty = _noWarranty
        ? 0
        : (int.tryParse(_warrantyQtyController.text) ?? 0);
    final wPeriod = _noWarranty ? 'Días' : _warrantyPeriod;

    bool finalUsesSerials = !_noSerials;
    bool registerSerialsNow = false;

    if (finalUsesSerials &&
        (widget.existingItem == null ||
            !widget.existingItem!.requiresSerials)) {
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
        'register_serials_now': registerSerialsNow,
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
          // Header Section (using StandardListItem)
          StandardListItem(
            padding: EdgeInsets.zero,
            leading: ProductImageAvatar(imageUrl: widget.product.imageUrl),
            overline: Text(
              widget.product.brand?.name.toTitleCase ?? 'Sin marca',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            title: widget.product.name,
            subtitle: Text(widget.product.model ?? 'Sin modelo'),
            trailing: UomStatusBadge(
              quantity: 0,
              uomAbbreviation: widget.product.uomModel?.symbol ?? 'ud.',
              uomIconName: widget.product.uomModel?.iconName,
              showQuantity: false,
            ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: CustomStepper(
                  label: 'Cantidad*',
                  controller: _quantityController,
                  onIncrement: _incrementQuantity,
                  onDecrement: _decrementQuantity,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Opacity(
                  opacity: 0.5,
                  child: CustomTextField(
                    label: 'Medida',
                    readOnly: true,
                    controller: TextEditingController(
                      text:
                          '${widget.product.uomModel?.name.toTitleCase ?? ''} (${widget.product.uomModel?.symbol ?? ''})',
                    ),
                  ),
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
            label: 'Costo unitario*',
            controller: _costController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: '\$   ',
            helperText: 'Sin impuesto',
            inputFormatters: [CurrencyInputFormatter()],
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
