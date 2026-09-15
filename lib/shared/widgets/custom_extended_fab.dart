import 'package:flutter/material.dart';

class CustomExtendedFab extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? trailingIcon;
  final String? trailingTooltip;

  const CustomExtendedFab({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.isEnabled = true,
    this.backgroundColor,
    this.foregroundColor,
    this.trailingIcon,
    this.trailingTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final effectiveForeground = isEnabled
        ? (foregroundColor ?? colors.onPrimaryContainer)
        : colors.onSurface.withValues(alpha: 0.38);

    Widget labelWidget = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );

    if (trailingIcon != null) {
      Widget trailingWidget = Icon(
        trailingIcon,
        size: 18,
        color: effectiveForeground,
      );
      if (trailingTooltip != null && trailingTooltip!.isNotEmpty) {
        trailingWidget = Tooltip(
          message: trailingTooltip!,
          child: trailingWidget,
        );
      }

      labelWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          labelWidget,
          const SizedBox(width: 8),
          trailingWidget,
        ],
      );
    }

    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(icon),
      label: labelWidget,
      backgroundColor: isEnabled
          ? (backgroundColor ?? colors.primaryContainer)
          : colors.surfaceContainerHighest,
      foregroundColor: effectiveForeground,
      elevation: isEnabled ? 4 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
