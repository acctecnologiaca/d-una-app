---
description: Create a standardized Form screen featuring a Form widget, StandardAppBar, FormBottomBar, and custom inputs (CustomTextField, CustomStepper, CustomDropdown).
---

# Standardize Form Screen Skill

This skill guides the creation of a new screen that functions as a data entry
form. It enforces consistency across the app by utilizing the native Flutter
`Form` widget together with standardized UI components.

## Standard Components

1. **Scaffold & AppBar**:
   - Standard `Scaffold`.
   - `StandardAppBar` with a title and optional subtitle.

2. **Form Structure**:
   - `Form` widget with a `GlobalKey<FormState>` to handle built-in validation.
   - A `Column` layout where the main content is inside an
     `Expanded(child: SingleChildScrollView(...))` to ensure scrollability.
   - The action buttons placed outside the scrollable area at the bottom via
     `FormBottomBar`, wrapped in a `SafeArea` and `Padding`.

3. **Inputs**:
   - `CustomTextField` for text, numeric, and monetary inputs.
   - `CustomDropdown` for selection inputs (e.g., categories, brands).
   - `CustomStepper` for incremental numeric inputs (e.g., percentages,
     quantities).

## Template Code

```dart
import 'package:flutter/material.dart';
import '../../../../shared/widgets/standard_app_bar.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_dropdown.dart';
import '../../../../shared/widgets/custom_stepper.dart';
import '../../../../shared/widgets/form_bottom_bar.dart';
import 'package:go_router/go_router.dart';

class MyStandardFormScreen extends StatefulWidget {
  const MyStandardFormScreen({super.key});

  @override
  State<MyStandardFormScreen> createState() => _MyStandardFormScreenState();
}

class _MyStandardFormScreenState extends State<MyStandardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  
  String? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;
    
    // Process save logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulario válido y guardado')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StandardAppBar(
        title: 'Título del Formulario',
        subtitle: 'Subtítulo opcional',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'Nombre*',
                      controller: _nameController,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    CustomDropdown<String>(
                      label: 'Categoría',
                      value: _selectedCategory,
                      items: const ['Opción 1', 'Opción 2'],
                      onChanged: (val) {
                        setState(() => _selectedCategory = val);
                      },
                      itemLabelBuilder: (item) => item,
                    ),
                    const SizedBox(height: 24),
                    
                    CustomStepper(
                      controller: _quantityController,
                      label: 'Cantidad',
                      onIncrement: () {
                        // Increment logic
                      },
                      onDecrement: () {
                        // Decrement logic
                      },
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: EdgeInsets.only(
                        top: 16.0,
                        bottom: MediaQuery.of(context).padding.bottom > 0
                            ? MediaQuery.of(context).padding.bottom
                            : 40.0,
                      ),
                      child: FormBottomBar(
                        onCancel: () => context.pop(),
                        onSave: _saveForm,
                        saveLabel: 'Guardar',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Usage Rules

1. **Validation**: Always use `Form` and its associated `GlobalKey<FormState>`.
   Validate fields inside `validator` properties of custom inputs. Do not
   reinvent validation logic outside the `Form` widget if it can be avoided.
2. **Layout Separation**: Keep the form fields inside a `SingleChildScrollView`
   inside `body`, and place the `FormBottomBar` in `bottomNavigationBar` so it
   is always accessible and never hidden by the keyboard.
3. **Spacing**: Use `const SizedBox(height: 24)` between major form field blocks
   for consistency.
