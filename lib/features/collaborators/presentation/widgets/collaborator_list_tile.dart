import 'package:flutter/material.dart';

class CollaboratorListTile extends StatelessWidget {
  final String name;
  final String role;
  final String initial;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onWhatsAppTap;
  final VoidCallback? onPhoneTap;

  const CollaboratorListTile({
    super.key,
    required this.name,
    required this.role,
    required this.initial,
    this.isActive = true,
    this.onTap,
    this.onWhatsAppTap,
    this.onPhoneTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isActive
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              child: Text(
                initial,
                style: TextStyle(
                  color: isActive
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant.withValues(alpha: 0.38),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? colors.onSurface
                          : colors.onSurface.withValues(alpha: 0.38),
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isActive
                          ? colors.onSurfaceVariant
                          : colors.onSurfaceVariant.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: isActive ? onWhatsAppTap : null,
              icon: Opacity(
                opacity: isActive ? 1.0 : 0.38,
                child: Image.asset(
                  'assets/icons/whatsapp_icon.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.chat_bubble_outline,
                      color: isActive
                          ? colors.onSurfaceVariant
                          : colors.onSurfaceVariant.withValues(alpha: 0.38),
                    );
                  },
                ),
              ),
              color: isActive
                  ? colors.onSurfaceVariant
                  : colors.onSurfaceVariant.withValues(alpha: 0.38),
            ),
            IconButton(
              onPressed: isActive ? onPhoneTap : null,
              icon: Icon(
                Icons.phone_outlined,
                color: isActive
                    ? colors.onSurfaceVariant
                    : colors.onSurfaceVariant.withValues(alpha: 0.38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
