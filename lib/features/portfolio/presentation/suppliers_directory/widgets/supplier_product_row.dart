import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/standard_list_item.dart';

class SupplierProductRow extends StatelessWidget {
  final String supplierName;
  final String? locationName;
  final double price;
  final int stock;
  final String uom;
  final bool isWholesale;
  final bool isLocked; // Fully restricted (Start with this)
  final bool isPartial; // Access allowed but price hidden/blurred
  final VoidCallback? onTap;

  const SupplierProductRow({
    super.key,
    required this.supplierName,
    this.locationName,
    required this.price,
    required this.stock,
    this.uom = 'ud.', // Default unit
    required this.isWholesale,
    this.isLocked = false,
    this.isPartial = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Visual State Logic
    final contentOpacity = isLocked ? 0.5 : 1.0;

    // Trade Type Styling
    final badgeColor = isWholesale ? Colors.blue.shade50 : Colors.green.shade50;
    final badgeTextColor = isWholesale
        ? Colors.blue.shade700
        : Colors.green.shade700;
    final badgeText = isWholesale ? 'MAYORISTA' : 'MINORISTA';

    // Stock Styling
    final hasStock = stock > 0;
    final stockColor = hasStock
        ? colors.onSecondaryContainer
        : colors.onErrorContainer;
    final stockBgColor = hasStock
        ? colors.secondaryContainer
        : colors.errorContainer;
    final stockText = hasStock ? '$stock $uom' : 'Sin stock';

    return Opacity(
      opacity: contentOpacity,
      child: StandardListItem(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        onTap: onTap,
        overline: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: badgeTextColor,
            ),
          ),
        ),
        title: supplierName,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (locationName != null && locationName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    locationName!,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Price Logic
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLocked) ...[
                  Icon(Symbols.lock, size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                ],

                // Price Display (Normal or Blurred)
                if (isLocked || isPartial)
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Text(
                      CurrencyFormatter.format(price),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                else
                  Text(
                    CurrencyFormatter.format(price),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Stock Validations
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: stockBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.package_2, size: 14, color: stockColor),
                  const SizedBox(width: 4),
                  Text(
                    stockText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: stockColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
