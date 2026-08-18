import 'package:flutter/material.dart';
import '../../../supplier_orders/domain/utils/oc_credit_helper.dart';

/// Card informativo que se muestra en el resumen de una compra cuando
/// su soporte digital ha sido rechazado y por ende los créditos han sido revocados.
class PurchaseCreditBannerCard extends StatelessWidget {
  final double totalAmount;
  final String? verificationStatus;

  const PurchaseCreditBannerCard({
    super.key,
    required this.totalAmount,
    this.verificationStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (verificationStatus != 'rejected') {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final earnedCredits = OCCreditHelper.calculateEarnedCredits(totalAmount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.replay_rounded, size: 20, color: colors.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Créditos:',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '-$earnedCredits',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Créditos revocados. Soporte rechazado por inconsistencia.',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: colors.outlineVariant.withValues(alpha: 0.5),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Estatus',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.error.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'Revocados',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.error,
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
