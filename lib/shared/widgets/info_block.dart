import 'package:flutter/material.dart';

class InfoBlock extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final Widget content;
  final Widget? action;

  const InfoBlock({
    super.key,
    this.icon,
    this.iconWidget,
    required this.label,
    required this.content,
    this.action,
  }) : assert(icon != null || iconWidget != null, 'Either icon or iconWidget must be provided');

  // Convenience constructor when content is just text
  factory InfoBlock.text({
    Key? key,
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required String value,
    Widget? action,
  }) {
    return InfoBlock(
      key: key,
      icon: icon,
      iconWidget: iconWidget,
      label: label,
      content: Builder(
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;
          final colors = Theme.of(context).colorScheme;
          return Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.normal,
            ),
          );
        },
      ),
      action: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Vertically centered
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: iconWidget ??
                Icon(
                  icon!,
                  size: 32,
                  color: colors.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(width: 16), // 16px gap
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Optimize vertical space
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4), // 4px gap
              content,
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action!],
      ],
    );
  }
}
