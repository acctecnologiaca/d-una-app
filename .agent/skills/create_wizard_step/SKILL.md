---
description: Create a new step for a wizard process using standardized UI components (WizardProgressBar, WizardButtonBar, CustomTextField, CustomDropdown).
---

# Create Wizard Step Skill

This skill guides the creation of a new screen that functions as a step within a multi-step Wizard process.
It enforces consistency by using `WizardProgressBar`, `WizardButtonBar`, and standardized input widgets.

## Standard Components

1.  **Scaffold & AppBar**:
    *   Standard `Scaffold`.
    *   `AppBar` with title and back button (if applicable).
    *   `WizardProgressBar` typically placed in `AppBar.bottom` or at the very top of `body`.

2.  **Navigation**:
    *   `WizardButtonBar` at the bottom of the content (or pinned to bottom via `Column` + `Spacer`).
    *   Left action: Cancel (optional).
    *   Right actions: Back (optional), Next/Finish (required).

3.  **Inputs**:
    *   `CustomTextField` for text inputs.
    *   `CustomDropdown` for selection inputs.
    *   `BarcodeScannerScreen` (via icon actions) if needed.

## Template Code

```dart
import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_dropdown.dart'; // If needed
import '../../../../shared/widgets/wizard_bottom_bar.dart';

class MyWizardStepScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  // Add other necessary callbacks or controllers

  const MyWizardStepScreen({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onCancel,
  });

  @override
  State<MyWizardStepScreen> createState() => _MyWizardStepScreenState();
}

class _MyWizardStepScreenState extends State<MyWizardStepScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

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
                  // Title
                  Text(
                    'Step Title Here',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 24,
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'Brief description or instruction for this step.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Inputs
                  CustomTextField(
                    label: 'Input Label',
                    controller: _controller,
                    validator: (val) => val != null && val.isEmpty ? 'Requerido' : null,
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
            labelNext: 'Siguiente', // or 'Finalizar' based on context
          ),
        ),
      ],
    );
  }
}
```

## Usage Rules

1.  **Layout**: Use a `Column` as the root widget.
    *   First child: `Expanded` containing `SingleChildScrollView` (for content).
    *   Second child: `Padding` (typically `bottom: 40`) containing `WizardButtonBar`.
2.  **Padding**: Use `const EdgeInsets.fromLTRB(16, 24, 16, 24)` for the `SingleChildScrollView` content.
3.  **State Management**: Pass Controllers or State objects from the parent "Wizard Orchestrator" widget if possible.
