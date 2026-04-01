import 'package:flutter/material.dart';

class SaveChangesDialog extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;

  const SaveChangesDialog({
    super.key,
    required this.onSave,
    required this.onContinue,
    required this.onDiscard,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required VoidCallback onSave,
    required VoidCallback onContinue,
    required VoidCallback onDiscard,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => SaveChangesDialog(
        onSave: onSave,
        onContinue: onContinue,
        onDiscard: onDiscard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colors.surfaceContainerHigh,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Guardar cambios?',
              style: textTheme.headlineSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Guarda los cambios realizados hasta\nahora',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
              child: const Text('Guardar y continuar luego'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onContinue,
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Continuar editando'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onDiscard,
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Descartar'),
            ),
          ],
        ),
      ),
    );
  }
}
