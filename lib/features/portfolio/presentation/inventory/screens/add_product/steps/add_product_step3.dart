import 'package:flutter/material.dart';
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
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: WizardButtonBar(
            onCancel: widget.onCancel,
            onBack: widget.onBack,
            onNext:
                widget.selectedCategory != null &&
                    widget.selectedCategory!.id != 'ADD_NEW' &&
                    widget.selectedUom != null
                ? widget.onNext
                : null,
          ),
        ),
      ],
    );
  }
}
