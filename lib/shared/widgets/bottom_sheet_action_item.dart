import 'package:flutter/material.dart';

class BottomSheetActionItem extends StatelessWidget {
  final dynamic icon; // Can be IconData or String (asset path)
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  const BottomSheetActionItem({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = enabled
        ? colors.onSurface
        : colors.onSurfaceVariant.withValues(alpha: 0.5);
    final iconColor = enabled
        ? colors.onSurface
        : colors.onSurfaceVariant.withValues(alpha: 0.5);

    final itemWidget = ListTile(
      leading: icon is IconData
          ? Icon(icon as IconData, color: iconColor)
          : ImageIcon(AssetImage(icon as String), color: iconColor, size: 24),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: enabled
                    ? colors.onSurfaceVariant
                    : colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            )
          : null,
      onTap: enabled ? onTap : null,
      enabled: enabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );

    if (subtitle != null) {
      return Tooltip(
        message: subtitle!,
        child: itemWidget,
      );
    }

    return itemWidget;
  }
}
