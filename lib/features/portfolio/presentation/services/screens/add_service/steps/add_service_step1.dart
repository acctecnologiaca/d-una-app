import 'package:flutter/material.dart';
import '../../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../../../shared/widgets/wizard_bottom_bar.dart';

class AddServiceStep1 extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final VoidCallback onNext;
  final VoidCallback onCancel;

  const AddServiceStep1({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.onNext,
    required this.onCancel,
  });

  @override
  State<AddServiceStep1> createState() => _AddServiceStep1State();
}

class _AddServiceStep1State extends State<AddServiceStep1> {
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
                  // Title
                  Text(
                    '¿Cómo se llama y de qué trata el servicio?',
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
                    'Se conciso con el nombre, éste debe ser corto.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name Input
                  CustomTextField(
                    label: 'Nombre del servicio*',
                    hintText: 'Ej: Instalación de cámara de seguridad',
                    controller: widget.nameController,
                    validator: (val) =>
                        val != null && val.trim().isEmpty ? 'Requerido' : null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),

                  // Description Instruction
                  Text(
                    'Describe brevemente de que trata el servicio.',
                    style: TextStyle(fontSize: 16, color: colors.onSurface),
                  ),
                  const SizedBox(height: 16),

                  // Description Input
                  CustomTextField(
                    label: 'Descripción breve',
                    controller: widget.descriptionController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
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
            // Hidden Back button for Step 1 as per design (Usually "Cancel" is enough, or Back closes)
            // The design shows "Atrás" so we should include it if needed, but for Step 1 "Back" usually means Cancel or Exit.
            // Design image shows "Cancel", "Atrás", "Siguiente".
            // Since it's step 1, "Atrás" might go back to the list. "Cancel" also goes back.
            // Let's implement onBack as onCancel for Step 1 or hide it if logic dictates.
            // In the image, "Atrás" is visible. I will map it to onCancel for now or leave it empty if the widget supports hiding it.
            // WizardButtonBar usually has optional onBack.
            onBack: widget.onCancel,
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
