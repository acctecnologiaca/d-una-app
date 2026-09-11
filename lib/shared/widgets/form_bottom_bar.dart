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

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
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
              CustomButton(
                text: saveLabel,
                type: ButtonType.primary,
                onPressed: isSaveEnabled ? onSave : null,
                isLoading: isLoading,
                isFullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
