import 'package:flutter/material.dart';
import '../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../../shared/widgets/wizard_bottom_bar.dart';

class AddProductStep2 extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController specsController;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final Future<void> Function()? onAiAutofill;

  const AddProductStep2({
    super.key,
    required this.nameController,
    required this.specsController,
    required this.onNext,
    required this.onBack,
    required this.onCancel,
    this.onAiAutofill,
  });

  @override
  State<AddProductStep2> createState() => _AddProductStep2State();
}

class _AddProductStep2State extends State<AddProductStep2> {
  final _formKey = GlobalKey<FormState>();
  bool _isConverting = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 64, // Adjust for padding
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Cómo se llama y cuáles son sus especificaciones?',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: 24,
                            color: colors.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Se conciso con el nombre, éste debe ser corto.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (widget.onAiAutofill != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            setState(() => _isConverting = true);
                            await widget.onAiAutofill!();
                            if (mounted) setState(() => _isConverting = false);
                          },
                          icon: _isConverting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome, size: 20),
                          label: Text(
                            _isConverting
                                ? 'Consultando...'
                                : 'Autocompletar con IA',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.primary,
                          ),
                        ),
                      ),

                    CustomTextField(
                      label: 'Nombre del producto*',
                      hintText: 'Ej: Tubo PVC 3/4"',
                      controller: widget.nameController,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Detalla las especificaciones técnicas del producto.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      label: 'Características',
                      controller: widget.specsController,
                      maxLines: 5,
                      minLines: 3,
                    ),

                    const SizedBox(height: 32),
                    const Spacer(),

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
