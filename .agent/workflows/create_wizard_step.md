---
description: Create a new step for a wizard process (e.g. Add Product)
---

Follow these steps to create a new wizard step.

1.  **Create the Step Widget File**
    -   Create a new file in the `steps/` directory (e.g., `add_product_step3.dart`).
    -   Use the following template to ensure proper layout and avoid overflow issues.

    ```dart
    import 'package:flutter/material.dart';
    import '../../../../../../shared/widgets/custom_text_field.dart';
    import '../../../../../../shared/widgets/wizard_bottom_bar.dart';
    // Import other necessary widgets

    class AddProductStepX extends StatefulWidget {
      // Add necessary controllers and callbacks
      final TextEditingController someController;
      final VoidCallback onNext;
      final VoidCallback onBack;
      final VoidCallback onCancel;

      const AddProductStepX({
        super.key,
        required this.someController,
        required this.onNext,
        required this.onBack,
        required this.onCancel,
      });

      @override
      State<AddProductStepX> createState() => _AddProductStepXState();
    }

    class _AddProductStepXState extends State<AddProductStepX> {
      final _formKey = GlobalKey<FormState>();

      @override
      Widget build(BuildContext context) {
        final colors = Theme.of(context).colorScheme;

        // CRITICAL: Use LayoutBuilder + SingleChildScrollView + ConstrainedBox to handle keyboard overflow
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 64, // Adjust for padding/safe area
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'Title of the Step',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w400,
                                fontSize: 24,
                                color: colors.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        // Input Fields (Use CustomTextField)
                        CustomTextField(
                          label: 'Label',
                          controller: widget.someController,
                          // validator...
                        ),
                        
                        const SizedBox(height: 24),

                        // Spacer to push buttons to bottom
                        const SizedBox(height: 32), // enforce minimum spacing
                        const Spacer(),

                        // Bottom Buttons
                        WizardButtonBar(
                          onCancel: widget.onCancel,
                          onBack: widget.onBack,
                          onNext: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onNext();
                            }
                          },
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
    ```

2.  **Integrate into Parent Screen**
    -   Open the parent screen file (e.g., `add_product_screen.dart`).
    -   **Add Controllers**: Define `TextEditingController`s for the new fields in the State class and dispose of them in `dispose()`.
    -   **Import Step**: Import the new step file.
    -   **Update IndexedStack**: Replace the placeholder (e.g., `Center(child: Text('Paso X'))`) with the new `AddProductStepX` widget, passing the controllers and callbacks.

3.  **Verify**
    -   Run the app and test the step.
    -   Verify that opening the keyboard does NOT cause an overflow error.
    -   Verify that the "Siguiente" button validates the form.
