import 'package:flutter/material.dart';
import '../../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../../shared/widgets/wizard_bottom_bar.dart';

class AddProductStep3 extends StatefulWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onCancel;

  const AddProductStep3({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onNext,
    required this.onBack,
    required this.onCancel,
  });

  @override
  State<AddProductStep3> createState() => _AddProductStep3State();
}

class _AddProductStep3State extends State<AddProductStep3> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _categories = [
    'Cámaras de seguridad',
    'Alarmas',
    'Materiales eléctricos',
    'Controles de acceso y asistencia',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  constraints.maxHeight - 64, // Adjust for padding/safe area
            ),
            child: IntrinsicHeight(
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

                    CustomDropdown<String>(
                      label: 'Categoría',
                      value: widget.selectedCategory,
                      items: _categories,
                      onChanged: widget.onCategoryChanged,
                      itemLabelBuilder: (item) => item,
                      showAddOption: true,
                      addOptionValue: '___ADD___',
                      addOptionLabel: 'Agregar',
                      onAddPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Agregar nueva categoría: Pendiente de implementación',
                            ),
                          ),
                        );
                      },
                      validator: (val) {
                        if (val == null || val == '___ADD___') {
                          return 'Requerido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),
                    const Spacer(),

                    WizardButtonBar(
                      onCancel: widget.onCancel,
                      onBack: widget.onBack,
                      onNext:
                          widget.selectedCategory != null &&
                              widget.selectedCategory != '___ADD___'
                          ? widget.onNext
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
