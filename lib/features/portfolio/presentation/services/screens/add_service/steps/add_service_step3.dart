import 'package:flutter/material.dart';
import '../../../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../../../shared/widgets/wizard_bottom_bar.dart';
import '../../../../../data/models/category_model.dart';

class AddServiceStep3 extends StatefulWidget {
  final Category? selectedCategory;
  final List<Category> categories;
  final ValueChanged<Category?> onCategoryChanged;
  final VoidCallback onAddCategory;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onCancel;

  const AddServiceStep3({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    required this.onAddCategory,
    required this.onNext,
    required this.onBack,
    required this.onCancel,
  });

  @override
  State<AddServiceStep3> createState() => _AddServiceStep3State();
}

class _AddServiceStep3State extends State<AddServiceStep3> {
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'Categoría del servicio',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 24,
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Subtitle
                  Text(
                    '¿En que categoría incluirías al servicio?',
                    style: TextStyle(fontSize: 16, color: colors.onSurface),
                  ),
                  const SizedBox(height: 12),

                  // Category Dropdown
                  CustomDropdown<Category>(
                    label: 'Categoría',
                    value: widget.selectedCategory,
                    items: widget.categories,
                    onChanged: widget.onCategoryChanged,
                    itemLabelBuilder: (item) => item.name,
                    validator: (val) => (val == null || val.id == 'ADD_NEW')
                        ? 'Requerido'
                        : null,
                    showAddOption: true,
                    addOptionLabel: 'Agregar',
                    addOptionValue: const Category(
                      id: 'ADD_NEW',
                      name: 'Agregar',
                      type: 'other',
                    ),
                    onAddPressed: widget.onAddCategory,
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
            onNext: () {
              if (_formKey.currentState!.validate()) {
                widget.onNext();
              }
            },
            labelNext: 'Siguiente',
          ),
        ),
      ],
    );
  }
}
