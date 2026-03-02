import 'package:flutter/material.dart';

class CustomExtendedFab extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomExtendedFab({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.isEnabled = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: isEnabled
          ? (backgroundColor ?? colors.primaryContainer)
          : colors.surfaceContainerHighest,
      foregroundColor: isEnabled
          ? (foregroundColor ?? colors.onPrimaryContainer)
          : colors.onSurface.withValues(alpha: 0.38),
      elevation: isEnabled ? 4 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
