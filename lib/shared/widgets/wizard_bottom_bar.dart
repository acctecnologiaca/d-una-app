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
              // Left Side: Cancel (Optional)
              if (onCancel != null)
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    foregroundColor: colors.primary,
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
                const SizedBox.shrink(),
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
        ),
      ),
    );
  }
}
