import 'package:flutter/material.dart';

/// Un bloque de tarjeta plegable con soporte para acordeón, ícono principal,
/// título, badge de completitud (check verde) y subtítulo dinámico resumen.
class CollapsibleCardBlock extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool isComplete;
  final bool initiallyExpanded;
  final ExpansibleController? controller;
  final ValueChanged<bool>? onExpansionChanged;
  final List<Widget> children;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry margin;

  const CollapsibleCardBlock({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.isComplete = false,
    this.initiallyExpanded = false,
    this.controller,
    this.onExpansionChanged,
    required this.children,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.margin = const EdgeInsets.only(bottom: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: margin,
      child: Card(
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            controller: controller,
            initiallyExpanded: initiallyExpanded,
            onExpansionChanged: onExpansionChanged,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: contentPadding,
            shape: const Border(),
            collapsedShape: const Border(),
            leading: leading,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isComplete) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),
                ],
              ],
            ),
            subtitle: subtitle != null && subtitle!.trim().isNotEmpty
                ? Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            children: children,
          ),
        ),
      ),
    );
  }
}
