import 'package:flutter/material.dart';

class QuickPhrasesBar extends StatelessWidget {
  final List<String> phrases;
  final ValueChanged<String> onPhraseSelected;

  const QuickPhrasesBar({
    super.key,
    required this.phrases,
    required this.onPhraseSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (phrases.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: phrases.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final phrase = phrases[index];
          return ActionChip(
            avatar: Icon(
              Icons.add_circle_outline,
              size: 14,
              color: colors.primary,
            ),
            label: Text(
              phrase,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurface,
              ),
            ),
            backgroundColor:
                colors.surfaceContainerHighest.withValues(alpha: 0.6),
            side:
                BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onPressed: () => onPhraseSelected(phrase),
          );
        },
      ),
    );
  }
}
