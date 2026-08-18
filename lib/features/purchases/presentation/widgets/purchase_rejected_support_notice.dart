import 'package:flutter/material.dart';
import '../../../supplier_orders/domain/utils/oc_credit_helper.dart';

/// Card informativo contextual que se muestra debajo del soporte digital de una compra
/// cuando dicho soporte ha sido rechazado por inconsistencias.
class PurchaseRejectedSupportNotice extends StatelessWidget {
  final double totalAmount;

  const PurchaseRejectedSupportNotice({
    super.key,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final earnedCredits = OCCreditHelper.calculateEarnedCredits(totalAmount);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 22,
              color: colors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Soporte rechazado',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'El documento de soporte cargado no corresponde a la orden de compra asociada y/o a los artículos registrados en esta compra.',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: colors.onSurface,
                    height: 1.4,
                  ),
                ),
                if (earnedCredits > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: colors.error,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Los $earnedCredits crédito${earnedCredits > 1 ? 's' : ''} generados por esta compra han sido revocados.',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
