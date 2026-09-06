import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import '../../../domain/models/delivery_note_item_model.dart';

class EditDeliveryNoteItemDialog extends StatefulWidget {
  final DeliveryNoteItemModel? initialItem;
  final ValueChanged<DeliveryNoteItemModel> onSave;

  const EditDeliveryNoteItemDialog({
    super.key,
    this.initialItem,
    required this.onSave,
  });

  @override
  State<EditDeliveryNoteItemDialog> createState() =>
      _EditDeliveryNoteItemDialogState();
}

class _EditDeliveryNoteItemDialogState extends State<EditDeliveryNoteItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _uomController;
  late final TextEditingController _warrantyTimeController;

  bool _requiresSerials = false;
  String _sourceType = 'own';
  String _warrantyUnit = 'months';

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _modelController = TextEditingController(text: item?.model ?? '');
    _quantityController =
        TextEditingController(text: (item?.quantity ?? 1.0).toString());
    _priceController =
        TextEditingController(text: (item?.unitPrice ?? 0.0).toString());
    _uomController = TextEditingController(text: item?.uom ?? 'Ud');
    _warrantyTimeController = TextEditingController(
      text: item?.warrantyTime != null ? item!.warrantyTime.toString() : '',
    );
    _requiresSerials = item?.requiresSerials ?? false;
    _sourceType = item?.sourceType ?? 'own';
    _warrantyUnit = item?.warrantyUnit ?? 'months';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _uomController.dispose();
    _warrantyTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(
        widget.initialItem == null ? 'Agregar producto' : 'Editar producto',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Nombre del producto *',
                hintText: 'Ej. Disco Duro SSD 1TB',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _brandController,
                      label: 'Marca',
                      hintText: 'Ej. Kingston',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      controller: _modelController,
                      label: 'Modelo',
                      hintText: 'Ej. NV2',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _quantityController,
                      label: 'Cantidad *',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      controller: _uomController,
                      label: 'Unidad (UOM)',
                      hintText: 'Ud',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _priceController,
                label: 'Precio unitario USD *',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _warrantyTimeController,
                      label: 'Tiempo garantía',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _warrantyUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'days', child: Text('Días')),
                        DropdownMenuItem(value: 'months', child: Text('Meses')),
                        DropdownMenuItem(value: 'years', child: Text('Años')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _warrantyUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _requiresSerials,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: colors.primary,
                title: const Text(
                  'Requiere seriales',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Solicitar número de serial para cada unidad entregada',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (val) {
                  setState(() => _requiresSerials = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            final qty = double.tryParse(_quantityController.text.trim()) ?? 1.0;
            final price =
                double.tryParse(_priceController.text.trim()) ?? 0.0;
            final warrantyTime =
                int.tryParse(_warrantyTimeController.text.trim());

            final item = DeliveryNoteItemModel(
              id: widget.initialItem?.id ?? '',
              deliveryNoteId: widget.initialItem?.deliveryNoteId ?? '',
              productId: widget.initialItem?.productId,
              name: name,
              brand: _brandController.text.trim().isEmpty
                  ? null
                  : _brandController.text.trim(),
              model: _modelController.text.trim().isEmpty
                  ? null
                  : _modelController.text.trim(),
              uom: _uomController.text.trim().isEmpty
                  ? 'Ud'
                  : _uomController.text.trim(),
              quantity: qty,
              unitPrice: price,
              totalPrice: qty * price,
              warrantyTime: warrantyTime,
              warrantyUnit: _warrantyUnit,
              sourceType: _sourceType,
              requiresSerials: _requiresSerials,
              isDropshipping: widget.initialItem?.isDropshipping ?? false,
              serials: widget.initialItem?.serials ?? const [],
            );

            widget.onSave(item);
            Navigator.of(context).pop();
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
