import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';

class AddOrderProductSheet extends ConsumerStatefulWidget {
  const AddOrderProductSheet({super.key});

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const AddOrderProductSheet(),
    );
  }

  @override
  ConsumerState<AddOrderProductSheet> createState() => _AddOrderProductSheetState();
}

class _AddOrderProductSheetState extends ConsumerState<AddOrderProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _brandController = TextEditingController();
  final _uomController = TextEditingController(text: 'Ud');
  final _qtyController = TextEditingController(text: '1.0');
  final _priceController = TextEditingController(text: '0.00');

  String? _selectedProductId;

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _brandController.dispose();
    _uomController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Agregar Producto a la Orden',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Catalog product autocomplete/dropdown search
              productsAsync.when(
                data: (products) {
                  return CustomDropdown<Product>(
                    label: 'Buscar en catálogo (Autocompletar)',
                    value: null,
                    items: products,
                    searchable: true,
                    itemLabelBuilder: (p) => '${p.name} ${p.model != null ? "(${p.model})" : ""}',
                    onChanged: (p) {
                      if (p != null) {
                        setState(() {
                          _selectedProductId = p.id;
                          _nameController.text = p.name;
                          _modelController.text = p.model ?? '';
                          _brandController.text = p.brand?.name ?? '';
                          _uomController.text = p.uomModel?.symbol ?? 'Ud';
                        });
                      }
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const SizedBox.shrink(),
              ),
              const Divider(height: 32),

              // Name
              CustomTextField(
                label: 'Nombre del producto*',
                controller: _nameController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Model & Brand row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Modelo',
                      controller: _modelController,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Marca',
                      controller: _brandController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // UOM, Qty, Price row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: CustomTextField(
                      label: 'UOM',
                      controller: _uomController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: CustomTextField(
                      label: 'Cantidad*',
                      controller: _qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || double.tryParse(val) == null) return 'Inválido';
                        if (double.parse(val) <= 0) return '> 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Precio Unitario*',
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || double.tryParse(val) == null) return 'Inválido';
                        if (double.parse(val) < 0) return '>= 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Confirm button
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() == true) {
                    Navigator.of(context).pop({
                      'productId': _selectedProductId,
                      'name': _nameController.text.trim(),
                      'model': _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
                      'brand': _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
                      'uom': _uomController.text.trim(),
                      'quantity': double.parse(_qtyController.text),
                      'unitPrice': double.parse(_priceController.text),
                    });
                  }
                },
                child: const Text('Agregar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
