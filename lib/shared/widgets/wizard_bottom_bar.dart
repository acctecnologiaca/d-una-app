import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_button.dart';

class WizardButtonBar extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final String labelNext;
  final bool isLastStep;
  final bool isLoading;
  final bool isNextEnabled;

  const WizardButtonBar({
    super.key,
    required this.onCancel,
    this.onNext,
    this.onBack,
    this.labelNext = 'Siguiente',
    this.isLastStep = false,
    this.isLoading = false,
    this.isNextEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Cancel Button (Always visible on left?)
        // In some designs "Cancel" is replaced by "Back" if not step 1?
        // User said: Step 1: Cancel, Next. Intermediate: Cancel, Back, Next.
        // So Cancel is always there.
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),

        const Spacer(),

        // Back Button (If provided)
        if (onBack != null) ...[
          TextButton(
            onPressed: onBack,
            child: Text(
              'Atrás',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],

        // Next/Finish Button
        SizedBox(
          width: 120, // Fixed width as seen in previous files
          child: CustomButton(
            text: isLastStep ? 'Finalizar' : labelNext,
            type: ButtonType.primary,
            onPressed: isNextEnabled ? onNext : null,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}
