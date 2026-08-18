import 'package:flutter/material.dart';
import '../../domain/models/supplier_order_status.dart';
import '../../domain/utils/oc_credit_helper.dart';

class SupplierOrderCreditBannerCard extends StatelessWidget {
  final double orderTotal;
  final SupplierOrderStatus status;
  final String? verificationStatus;
  final bool isCreateOrEdit;
  final bool isLoading;

  const SupplierOrderCreditBannerCard({
    super.key,
    required this.orderTotal,
    required this.status,
    this.verificationStatus,
    this.isCreateOrEdit = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.outlineVariant.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 180,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
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
                Container(
                  width: 36,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 60,
                  height: 18,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final earnedCredits = OCCreditHelper.calculateEarnedCredits(orderTotal);
    final isRejected = verificationStatus == 'rejected';
    final isCreditsGranted =
        !isCreateOrEdit &&
        (status == SupplierOrderStatus.approved ||
            status == SupplierOrderStatus.finalized) &&
        !isRejected;
    final isCancelled =
        !isCreateOrEdit && status == SupplierOrderStatus.cancelled;

    final Color cardBg;
    final Color cardBorder;
    final Color iconBg;
    final IconData iconData;
    final Color iconColor;

    final String title;
    final String valueText;
    final Color valueColor;
    final String subtext;

    final String chipText;
    final Color chipBg;
    final Color chipBorder;
    final Color chipTextColor;

    if (isCreateOrEdit) {
      cardBg = colors.secondaryContainer.withValues(alpha: 0.25);
      cardBorder = colors.secondaryContainer.withValues(alpha: 0.6);
      iconBg = colors.secondaryContainer;
      iconData = Icons.stars_rounded;
      iconColor = colors.onSecondaryContainer;

      title = 'Créditos:';
      valueText = '+$earnedCredits';
      valueColor = colors.onSecondaryContainer;
      subtext = 'Acreditados tras aprobación del proveedor';

      chipText = 'Pendientes';
      chipBg = colors.onSecondaryContainer.withValues(alpha: 0.12);
      chipBorder = colors.onSecondaryContainer.withValues(alpha: 0.3);
      chipTextColor = colors.onSecondaryContainer;
    } else if (isCancelled) {
      cardBg = colors.surfaceContainerHighest.withValues(alpha: 0.4);
      cardBorder = colors.outlineVariant;
      iconBg = colors.outlineVariant;
      iconData = Icons.block_rounded;
      iconColor = colors.onSurfaceVariant;

      title = 'Créditos:';
      valueText = '0';
      valueColor = colors.onSurfaceVariant;
      subtext = 'La orden de compra ha sido cancelada';

      chipText = 'Cancelada';
      chipBg = colors.onSurfaceVariant.withValues(alpha: 0.12);
      chipBorder = colors.onSurfaceVariant.withValues(alpha: 0.3);
      chipTextColor = colors.onSurfaceVariant;
    } else if (isRejected) {
      cardBg = colors.errorContainer.withValues(alpha: 0.25);
      cardBorder = colors.error.withValues(alpha: 0.4);
      iconBg = colors.errorContainer;
      iconData = Icons.replay_rounded;
      iconColor = colors.error;

      title = 'Créditos:';
      valueText = '-$earnedCredits';
      valueColor = colors.error;
      subtext = 'Créditos revocados por inconsistencia en el soporte';

      chipText = 'Revocados';
      chipBg = colors.errorContainer;
      chipBorder = colors.error.withValues(alpha: 0.5);
      chipTextColor = colors.error;
    } else if (isCreditsGranted) {
      const emeraldColor = Color(0xFF2E7D32);
      cardBg = emeraldColor.withValues(alpha: 0.1);
      cardBorder = emeraldColor.withValues(alpha: 0.4);
      iconBg = emeraldColor.withValues(alpha: 0.2);
      iconData = Icons.add_circle_rounded;
      iconColor = emeraldColor;

      title = 'Créditos:';
      valueText = '+$earnedCredits';
      valueColor = emeraldColor;
      subtext = 'El proveedor ha aprobado la orden de compra';

      chipText = 'Aprobados';
      chipBg = emeraldColor.withValues(alpha: 0.15);
      chipBorder = emeraldColor.withValues(alpha: 0.4);
      chipTextColor = emeraldColor;
    } else {
      cardBg = colors.secondaryContainer.withValues(alpha: 0.25);
      cardBorder = colors.secondaryContainer.withValues(alpha: 0.6);
      iconBg = colors.secondaryContainer;
      iconData = Icons.hourglass_top_rounded;
      iconColor = colors.onSecondaryContainer;

      title = 'Créditos:';
      valueText = '+$earnedCredits';
      valueColor = colors.onSecondaryContainer;
      subtext = 'Acreditados tras aprobación del proveedor';

      chipText = 'Pendientes';
      chipBg = colors.onSecondaryContainer.withValues(alpha: 0.12);
      chipBorder = colors.onSecondaryContainer.withValues(alpha: 0.3);
      chipTextColor = colors.onSecondaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(iconData, size: 20, color: iconColor),
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
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      valueText,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
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
            color: colors.outlineVariant,
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
                  color: chipBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: chipBorder),
                ),
                child: Text(
                  chipText,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: chipTextColor,
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
