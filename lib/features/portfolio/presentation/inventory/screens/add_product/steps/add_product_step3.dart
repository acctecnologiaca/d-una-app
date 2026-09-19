import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../../../shared/widgets/wizard_bottom_bar.dart';
import '../../../../../data/models/category_model.dart';
import '../../../../../data/models/uom_model.dart';

class AddProductStep3 extends StatefulWidget {
  final Category? selectedCategory;
  final ValueChanged<Category?> onCategoryChanged;
  final List<Category> categories;
  final VoidCallback onAddCategory;

  final Uom? selectedUom;
  final ValueChanged<Uom?> onUomChanged;
  final List<Uom> uoms;
  final VoidCallback onAddUom;

  final bool requiresSerials;
  final ValueChanged<bool> onRequiresSerialsChanged;
  final bool hasWarranty;
  final ValueChanged<bool> onHasWarrantyChanged;

  final bool hasInitialStock;
  final ValueChanged<bool> onHasInitialStockChanged;
  final TextEditingController initialQuantityController;
  final TextEditingController initialCostController;

  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onCancel;

  const AddProductStep3({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.categories,
    required this.onAddCategory,
    required this.selectedUom,
    required this.onUomChanged,
    required this.uoms,
    required this.onAddUom,
    required this.requiresSerials,
    required this.onRequiresSerialsChanged,
    required this.hasWarranty,
    required this.onHasWarrantyChanged,
    required this.hasInitialStock,
    required this.onHasInitialStockChanged,
    required this.initialQuantityController,
    required this.initialCostController,
    required this.onNext,
    required this.onBack,
    required this.onCancel,
  });

  @override
  State<AddProductStep3> createState() => _AddProductStep3State();
}

class _AddProductStep3State extends State<AddProductStep3> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Detalles adicionales',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: 24,
                            color: colors.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Categoría y unidad de medida del producto.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 24),

                  CustomDropdown<Category>(
                    label: 'Categoría',
                    value: widget.selectedCategory,
                    items: widget.categories,
                    searchable: true,
                    onChanged: widget.onCategoryChanged,
                    itemLabelBuilder: (item) => item.name,
                    showAddOption: true,
                    addOptionValue: const Category(
                      id: 'ADD_NEW',
                      name: 'Agregar',
                      type: 'other',
                    ),
                    addOptionLabel: 'Agregar categoría',
                    onAddPressed: widget.onAddCategory,
                    validator: (val) {
                      if (val == null || val.id == 'ADD_NEW') {
                        return 'Requerido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  CustomDropdown<Uom>(
                    label: 'Unidad de Medida',
                    value: widget.selectedUom,
                    searchable: true,
                    items: widget.uoms,
                    onChanged: (val) {
                      if (val != null && val.id != 'ADD_NEW') {
                        widget.onUomChanged(val);
                      }
                    },
                    itemLabelBuilder: (item) => '${item.name} (${item.symbol})',
                    showAddOption: true,
                    addOptionValue: const Uom(
                      id: 'ADD_NEW',
                      name: 'Agregar',
                      symbol: '',
                    ),
                    addOptionLabel: 'Agregar unidad de medida',
                    onAddPressed: widget.onAddUom,
                    validator: (val) {
                      if (val == null || val.id == 'ADD_NEW') {
                        return 'Requerido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Switch para seriales
                  SwitchListTile(
                    title: const Text(
                      'Solicitar serial por defecto',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Activa por defecto la petición de números de serie al ingresar o vender el producto.',
                    ),
                    value: widget.requiresSerials,
                    onChanged: widget.onRequiresSerialsChanged,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: colors.primary,
                  ),

                  const SizedBox(height: 12),

                  // Switch para garantía
                  SwitchListTile(
                    title: const Text(
                      'Solicitar tiempo de garantía por defecto',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Sugiere por defecto la configuración de plazos de garantía para este producto.',
                    ),
                    value: widget.hasWarranty,
                    onChanged: widget.onHasWarrantyChanged,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: colors.primary,
                  ),

                  const Divider(height: 32),

                  // Switch para existencia física en anaquel
                  SwitchListTile(
                    title: const Text(
                      'Existencia física en anaquel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Declarar inventario inicial para este producto',
                    ),
                    secondary: Icon(Symbols.shelves, color: colors.primary),
                    value: widget.hasInitialStock,
                    onChanged: widget.onHasInitialStockChanged,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: colors.primary,
                  ),

                  if (widget.hasInitialStock) ...[
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Cantidad inicial en stock*',
                      controller: widget.initialQuantityController,
                      prefixIcon: const Icon(Symbols.tag),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      helperText: 'Unidades físicas contadas en almacén',
                      validator: (val) {
                        if (!widget.hasInitialStock) return null;
                        if (val == null || val.trim().isEmpty) {
                          return 'La cantidad es obligatoria';
                        }
                        final n = double.tryParse(val.replaceAll(',', '.'));
                        if (n == null || n <= 0) {
                          return 'Ingresa una cantidad mayor a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Costo unitario del producto*',
                      controller: widget.initialCostController,
                      prefixIcon: const Icon(Icons.attach_money),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      helperText:
                          'Costo estimado de adquisición por unidad en USD',
                      validator: (val) {
                        if (!widget.hasInitialStock) return null;
                        if (val == null || val.trim().isEmpty) {
                          return 'El costo unitario es obligatorio';
                        }
                        final n = double.tryParse(val.replaceAll(',', '.'));
                        if (n == null || n < 0) {
                          return 'Ingresa un costo válido';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        WizardButtonBar(
          onCancel: widget.onCancel,
          onBack: widget.onBack,
          onNext:
              widget.selectedCategory != null &&
                      widget.selectedCategory!.id != 'ADD_NEW' &&
                      widget.selectedUom != null
                  ? () {
                      if (_formKey.currentState!.validate()) {
                        widget.onNext();
                      }
                    }
                  : null,
        ),
      ],
    );
  }
}
