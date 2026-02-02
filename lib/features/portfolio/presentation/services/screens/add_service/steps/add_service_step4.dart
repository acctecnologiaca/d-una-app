import 'package:flutter/material.dart';
import '../../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../../../shared/widgets/wizard_bottom_bar.dart';

class AddServiceStep4 extends StatefulWidget {
  final bool hasWarranty;
  final ValueChanged<bool> onWarrantyChanged;
  final TextEditingController timeController;
  final String? selectedPeriod;
  final ValueChanged<String?> onPeriodChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onCancel;

  const AddServiceStep4({
    super.key,
    required this.hasWarranty,
    required this.onWarrantyChanged,
    required this.timeController,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onNext,
    required this.onBack,
    required this.onCancel,
  });

  @override
  State<AddServiceStep4> createState() => _AddServiceStep4State();
}

class _AddServiceStep4State extends State<AddServiceStep4> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _periodOptions = ['Días', 'Semanas', 'Meses', 'Años'];

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
                  Text(
                    '¿Ofreces garantía por este servicio?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 24,
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '¿Cuánto tiempo de garantía le ofrecerás a tus clientes?',
                    style: TextStyle(fontSize: 16, color: colors.onSurface),
                  ),
                  const SizedBox(height: 24),

                  // Toggle Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'No ofrezco garantía para este servicio',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      Switch(
                        value: !widget.hasWarranty,
                        onChanged: (val) {
                          widget.onWarrantyChanged(!val);
                        },
                      ),
                    ],
                  ),

                  // Warranty Fields (Visible only if warranty is enabled)
                  if (widget.hasWarranty) ...[
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            label: 'Cantidad*',
                            hintText: '15',
                            controller: widget.timeController,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (!widget.hasWarranty) return null;
                              if (val == null || val.trim().isEmpty)
                                return 'Requerido';
                              if (int.tryParse(val) == null) return 'Inválido';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: CustomDropdown<String>(
                            label: 'Período',
                            value: widget.selectedPeriod,
                            items: _periodOptions,
                            onChanged: widget.onPeriodChanged,
                            itemLabelBuilder: (item) => item,
                            validator: (val) {
                              if (!widget.hasWarranty) return null;
                              return val == null ? 'Requerido' : null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
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
              if (widget.hasWarranty) {
                if (_formKey.currentState!.validate()) {
                  widget.onNext();
                }
              } else {
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
