import 'package:flutter/material.dart';
import 'package:d_una_app/features/supplier_orders/domain/utils/oc_credit_helper.dart';

class OCCreditSuggestionBanner extends StatelessWidget {
  final double totalAmount;

  const OCCreditSuggestionBanner({super.key, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    if (!OCCreditHelper.shouldShowSuggestion(totalAmount)) {
      return const SizedBox.shrink();
    }

    final shortfall = OCCreditHelper.calculateShortfallForNextCredit(totalAmount);
    final earned = OCCreditHelper.calculateEarnedCredits(totalAmount);

    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.stars_rounded, color: colors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Estás a solo \$${shortfall.toStringAsFixed(2)} de ganar otro crédito!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Con tu monto actual de \$${totalAmount.toStringAsFixed(2)} ganas $earned crédito(s). ¡Agrega otro producto para ganar ${earned + 1}!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
