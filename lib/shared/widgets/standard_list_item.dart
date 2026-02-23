import 'package:flutter/material.dart';

class StandardListItem extends StatelessWidget {
  final Widget? leading;
  final Widget? overline; // New: Top subtitle (simpler/smaller)
  final String title;
  final Widget? subtitle;
  final Widget? trailing; // Usually column with price + badges
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const StandardListItem({
    super.key,
    this.leading,
    this.overline,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Vertically center leading/trailing
          children: [
            // Safe Leading
            if (leading != null) ...[leading!, const SizedBox(width: 16)],

            // Middle Content (Text)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment
                    .center, // Center text vertically if leading is tall
                children: [
                  if (overline != null) ...[
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      child: overline!,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 13, // Standardized subtitle size
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),

            // Trailing Content (Price, Badges, Actions)
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
