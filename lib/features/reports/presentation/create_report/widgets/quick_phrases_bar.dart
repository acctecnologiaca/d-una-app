import 'package:flutter/material.dart';

class QuickPhrasesBar extends StatelessWidget {
  final List<String> phrases;
  final ValueChanged<String> onPhraseSelected;
  final EdgeInsetsGeometry? padding;

  const QuickPhrasesBar({
    super.key,
    required this.phrases,
    required this.onPhraseSelected,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (phrases.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: phrases.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final phrase = phrases[index];
          return ActionChip(
            avatar: Icon(
              Icons.add_circle_outline,
              size: 16,
              color: colors.primary,
            ),
            label: Text(
              phrase,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
            backgroundColor: colors.surface,
            side: BorderSide(color: colors.outline.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            onPressed: () => onPhraseSelected(phrase),
          );
        },
      ),
    );
  }
}
