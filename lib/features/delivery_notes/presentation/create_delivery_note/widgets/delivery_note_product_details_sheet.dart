import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/shared/widgets/custom_stepper.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/features/delivery_notes/domain/models/delivery_note_item_model.dart';

class DeliveryNoteProductDetailsSheet extends ConsumerStatefulWidget {
  final Product product;
  final DeliveryNoteItemModel? existingItem;

  const DeliveryNoteProductDetailsSheet({
    super.key,
    required this.product,
    this.existingItem,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required Product product,
    DeliveryNoteItemModel? existingItem,
  }) {
    final sheetKey = GlobalKey<_DeliveryNoteProductDetailsSheetState>();

    return CustomActionSheet.show<Map<String, dynamic>>(
      context: context,
      title: 'Detalles del producto',
      isContentScrollable: true,
      content: DeliveryNoteProductDetailsSheet(
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
  ConsumerState<DeliveryNoteProductDetailsSheet> createState() =>
      _DeliveryNoteProductDetailsSheetState();
}

class _DeliveryNoteProductDetailsSheetState
    extends ConsumerState<DeliveryNoteProductDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _warrantyQtyController = TextEditingController(text: '12');

  bool _noWarranty = false;
  String _warrantyPeriod = 'Meses';
  bool _noSerials = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _warrantyQtyController.text = (item.warrantyTime ?? 1).toString();
      _noWarranty = item.warrantyTime == null || item.warrantyTime == 0;

      if (item.warrantyUnit == 'days') {
        _warrantyPeriod = 'Días';
      } else if (item.warrantyUnit == 'months') {
        _warrantyPeriod = 'Meses';
      } else if (item.warrantyUnit == 'years') {
        _warrantyPeriod = 'Años';
      }

      _noSerials = !item.requiresSerials;
    } else {
      _noWarranty = !widget.product.hasWarranty;
      _noSerials = !widget.product.requiresSerials;
    }
  }

  @override
  void dispose() {
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

    final wQty = _noWarranty
        ? 0
        : (int.tryParse(_warrantyQtyController.text) ?? 0);
    final wPeriod = _noWarranty ? 'Días' : _warrantyPeriod;

    final bool finalUsesSerials = !_noSerials;
    bool needsToAskSerials = false;

    if (finalUsesSerials &&
        (widget.existingItem == null ||
            !widget.existingItem!.requiresSerials)) {
      needsToAskSerials = true;
    }

    if (mounted) {
      context.pop({
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
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
