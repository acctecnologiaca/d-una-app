import 'package:flutter/material.dart';
import '../../../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../../../shared/widgets/wizard_bottom_bar.dart';
import '../../../../../data/models/category_model.dart';

class AddProductStep3 extends StatefulWidget {
  final Category? selectedCategory;
  final ValueChanged<Category?> onCategoryChanged;
  final List<Category> categories;
  final VoidCallback onAddCategory;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onCancel;

  const AddProductStep3({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.categories,
    required this.onAddCategory,
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
                      'Categoría del producto',
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
                    '¿En qué categoría incluirías al producto?',
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
                    onChanged: widget.onCategoryChanged,
                    itemLabelBuilder: (item) => item.name,
                    showAddOption: true,
                    addOptionValue: const Category(
                      id: 'ADD_NEW',
                      name: 'Agregar',
                      type: 'other',
                    ),
                    addOptionLabel: 'Agregar',
                    onAddPressed: widget.onAddCategory,
                    validator: (val) {
                      if (val == null || val.id == 'ADD_NEW') {
                        return 'Requerido';
                      }
                      return null;
                    },
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
                    widget.selectedCategory!.id != 'ADD_NEW'
                ? widget.onNext
                : null,
          ),
        ),
      ],
    );
  }
}
