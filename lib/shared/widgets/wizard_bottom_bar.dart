import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_button.dart';

class WizardButtonBar extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final String labelNext;
  final String labelFinish;
  final String labelBack;
  final String labelCancel; // Customizable labels
  final bool isLastStep;
  final bool isLoading;
  final bool isNextEnabled;

  const WizardButtonBar({
    super.key,
    this.onCancel,
    required this.onNext,
    this.onBack,
    this.labelNext = 'Siguiente',
    this.labelFinish = 'Finalizar',
    this.labelBack = 'Atrás',
    this.labelCancel = 'Cancelar',
    this.isLastStep = false,
    this.isLoading = false,
    this.isNextEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Cancel (Optional)
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                foregroundColor: colors
                    .primary, // Often Cancel is destructive/alert or just neutral
              ),
              child: Text(
                labelCancel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            )
          else
            const SizedBox.shrink(), // Placeholder to keep spacing if needed? No, spaceBetween handles it.
          // Right Side: Back + Next/Finish
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Back Button
              if (onBack != null) ...[
                TextButton(
                  onPressed: onBack,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    foregroundColor: colors.primary,
                  ),
                  child: Text(
                    labelBack,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Next / Finish Button
              SizedBox(
                // Constrain width or let it be flexible? form_bottom_bar uses Expanded.
                // For Wizard, usually strictly "Next" button.
                // Let's us CustomButton but maybe wrap in IntrinsicWidth or fixed width if short text.
                // But CustomButton expands to infinity width by default?
                // Looking at CustomButton code: yes, width: double.infinity.
                // So we must wrap it in a SizedBox with width or Flexible.
                width: 140,
                child: CustomButton(
                  text: isLastStep ? labelFinish : labelNext,
                  type: ButtonType.primary,
                  onPressed: isNextEnabled ? onNext : null,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
