import 'package:flutter/material.dart';

class WizardProgressBar extends StatelessWidget implements PreferredSizeWidget {
  final int totalSteps;
  final int currentStep;

  const WizardProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Size get preferredSize => const Size.fromHeight(4.0);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          flex: currentStep,
          child: Container(color: colors.primary, height: 4),
        ),
        Expanded(
          flex: totalSteps - currentStep,
          child: Container(color: colors.secondaryContainer, height: 4),
        ),
      ],
    );
  }
}
