import 'package:flutter/material.dart';

class EmptyListState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? searchQuery;

  const EmptyListState({
    super.key,
    required this.icon,
    required this.message,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final displayMessage = (searchQuery != null && searchQuery!.isNotEmpty)
        ? 'No se encontraron resultados.'
        : message;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            displayMessage,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
