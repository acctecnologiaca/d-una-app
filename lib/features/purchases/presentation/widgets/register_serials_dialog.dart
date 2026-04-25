import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_dialog.dart';

enum RegisterSerialsResult { now, later, never }

class RegisterSerialsDialog {
  static Future<RegisterSerialsResult?> show(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return CustomDialog.show<RegisterSerialsResult>(
      context: context,
      dialog: CustomDialog.vertical(
        title: '¿Registrar seriales?',
        contentText: 'Registra los seriales de los productos que adquiriste.',
        actions: [
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pop(RegisterSerialsResult.now),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Sí, registrar ahora',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(RegisterSerialsResult.later),
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Más tarde...',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(RegisterSerialsResult.never),
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Este producto no trae serial',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
