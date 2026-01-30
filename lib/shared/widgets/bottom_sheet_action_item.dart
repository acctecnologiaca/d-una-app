import 'package:flutter/material.dart';

class BottomSheetActionItem extends StatelessWidget {
  final dynamic icon; // Can be IconData or String (asset path)
  final String label;
  final VoidCallback onTap;

  const BottomSheetActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      leading: icon is IconData
          ? Icon(icon as IconData, color: colors.onSurface)
          : ImageIcon(
              AssetImage(icon as String),
              color: colors.onSurface,
              size: 24,
            ),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w500, color: colors.onSurface),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
