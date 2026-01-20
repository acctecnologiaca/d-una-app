import 'package:flutter/material.dart';

class ContactListTile extends StatelessWidget {
  final String name;
  final String role;
  final String initial;
  final bool isPrimary;
  final VoidCallback? onTap;
  final VoidCallback? onWhatsAppTap;
  final VoidCallback? onPhoneTap;

  const ContactListTile({
    super.key,
    required this.name,
    required this.role,
    required this.initial,
    this.isPrimary = false,
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
              backgroundColor: colors.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'P',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onWhatsAppTap ?? () {},
              icon: Image.asset(
                'assets/images/whatsapp_icon.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.chat_bubble_outline,
                    color: colors.onSurfaceVariant,
                  );
                },
              ),
              color: colors.onSurfaceVariant,
            ),
            IconButton(
              onPressed: onPhoneTap ?? () {},
              icon: const Icon(Icons.phone_outlined),
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
