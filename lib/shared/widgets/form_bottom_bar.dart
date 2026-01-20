import 'package:flutter/material.dart';
import 'custom_button.dart';

class FormBottomBar extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final String saveLabel;
  final String cancelLabel;
  final bool isLoading;
  final bool isSaveEnabled;

  const FormBottomBar({
    super.key,
    required this.onCancel,
    this.onSave,
    this.saveLabel = 'Guardar',
    this.cancelLabel = 'Cancelar',
    this.isLoading = false,
    this.isSaveEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onCancel,
            child: Text(
              cancelLabel,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const Spacer(),
        Expanded(
          child: CustomButton(
            text: saveLabel,
            type: ButtonType.primary,
            onPressed: isSaveEnabled ? onSave : null,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}
