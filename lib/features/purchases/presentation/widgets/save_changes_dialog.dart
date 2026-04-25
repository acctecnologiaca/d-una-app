import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_dialog.dart';

class SaveChangesDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    required VoidCallback onSave,
    required VoidCallback onContinue,
    required VoidCallback onDiscard,
  }) {
    final colors = Theme.of(context).colorScheme;

    return CustomDialog.show<T>(
      context: context,
      dialog: CustomDialog.vertical(
        title: '¿Guardar cambios?',
        contentText: 'Guarda los cambios realizados hasta ahora',
        actions: [
          OutlinedButton(
            onPressed: onSave,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Guardar y continuar luego',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: onContinue,
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Continuar editando',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: onDiscard,
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Descartar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
