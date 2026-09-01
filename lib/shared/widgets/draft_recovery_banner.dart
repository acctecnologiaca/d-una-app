import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DraftRecoveryBanner extends StatelessWidget {
  final DateTime savedAt;
  final VoidCallback onDiscard;
  final VoidCallback? onDismiss;

  const DraftRecoveryBanner({
    super.key,
    required this.savedAt,
    required this.onDiscard,
    this.onDismiss,
  });

  String _formatSavedTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'hace unos momentos';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours} h';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: colors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            color: colors.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Borrador restaurado automáticamente',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Guardado ${_formatSavedTime(savedAt)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onDiscard,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: colors.error,
            ),
            child: const Text(
              'Descartar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.close, size: 16, color: colors.onPrimaryContainer),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDismiss,
            ),
          ],
        ],
      ),
    );
  }
}
