import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? customTitle;
  final String? subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Color? backgroundColor;

  const StandardAppBar({
    super.key,
    required this.title,
    this.customTitle,
    this.subtitle,
    this.actions,
    this.bottom,
    this.centerTitle = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: backgroundColor ?? colors.surface,
      elevation: 0,
      centerTitle: centerTitle,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.onSurface),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: centerTitle
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          customTitle ??
              Text(
                title,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: actions?.map((action) {
        // Ensure icon buttons in actions also use onSurface color if they are IconButtons
        // This is a bit tricky to enforce wrapper-side without cloning,
        // but usually the caller handles it or we wrap it in a Theme.
        // For now, raw actions.
        return action;
      }).toList(),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
