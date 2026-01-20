import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/form_bottom_bar.dart';

class ContactForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController roleController;
  final TextEditingController departmentController;
  final String selectedPhoneCode;
  final ValueChanged<String?> onPhoneCodeChanged;
  final bool isPrimary;
  final ValueChanged<bool> onIsPrimaryChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String saveLabel;
  final bool isPrimaryReadOnly;
  final bool isLoading;
  final bool isSaveEnabled;

  const ContactForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.roleController,
    required this.departmentController,
    required this.selectedPhoneCode,
    required this.onPhoneCodeChanged,
    required this.isPrimary,
    required this.onIsPrimaryChanged,
    required this.onSave,
    required this.onCancel,
    this.saveLabel = 'Guardar',
    this.isPrimaryReadOnly = false,
    this.isLoading = false,
    this.isSaveEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final phoneCodes = ['0412', '0414', '0424', '0416'];

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            label: 'Nombre y apellido*',
            controller: nameController,
            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),

          // Phone Row
          Row(
            children: [
              SizedBox(
                width: 100,
                child: CustomDropdown<String>(
                  value: selectedPhoneCode,
                  label: 'Cod.',
                  items: phoneCodes,
                  itemLabelBuilder: (item) => item,
                  onChanged: onPhoneCodeChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Teléfono*',
                  controller: phoneController,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Requerido' : null,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          CustomTextField(
            label: 'Correo electrónico*',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val != null && val.isNotEmpty) {
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                );
                if (!emailRegex.hasMatch(val)) {
                  return 'Correo electrónico inválido';
                }
              }
              if (val == null || val.isEmpty) return 'Requerido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(label: 'Cargo', controller: roleController),
          const SizedBox(height: 16),

          CustomTextField(
            label: 'Departamento',
            controller: departmentController,
          ),

          const SizedBox(height: 24),

          // Primary Switch
          Row(
            children: [
              Expanded(
                child: Text(
                  'Establecer como contacto principal',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: isPrimary,
                  onChanged: isPrimaryReadOnly
                      ? null
                      : (val) => onIsPrimaryChanged(val),
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),

          FormBottomBar(
            onCancel: onCancel,
            onSave: onSave,
            isLoading: isLoading,
            saveLabel: saveLabel,
            isSaveEnabled: isSaveEnabled,
          ),
        ],
      ),
    );
  }
}
