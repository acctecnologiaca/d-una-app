import 'package:flutter/material.dart';

/// Un widget compartido que muestra una tarjeta informativa con el saldo de créditos
/// disponibles y el costo a consumir para una transacción específica.
class CreditBannerCard extends StatelessWidget {
  final int remainingCredits;
  final int cost;

  const CreditBannerCard({
    super.key,
    required this.remainingCredits,
    required this.cost,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasEnoughCredits = remainingCredits >= cost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.secondaryContainer.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: remainingCredits > 0
                  ? colors.secondaryContainer
                  : colors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stars_rounded,
              size: 18,
              color: remainingCredits > 0
                  ? colors.onSecondaryContainer
                  : colors.onErrorContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Créditos',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  remainingCredits > 0
                      ? '$remainingCredits disponibles'
                      : 'Agotados (0)',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: remainingCredits > 0
                        ? colors.onSecondaryContainer
                        : colors.error,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 28,
            width: 1,
            color: colors.outlineVariant,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A consumir',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hasEnoughCredits
                      ? colors.onSecondaryContainer.withValues(alpha: 0.12)
                      : colors.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasEnoughCredits
                        ? colors.onSecondaryContainer.withValues(alpha: 0.3)
                        : colors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$cost crédito${cost > 1 ? 's' : ''}',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasEnoughCredits
                        ? colors.onSecondaryContainer
                        : colors.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
