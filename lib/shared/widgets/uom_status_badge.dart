import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dynamic_material_symbol.dart';
import 'status_badge.dart';

/// A standardized badge for displaying UOM quantity and abbreviation.
///
/// Uses [StatusBadge] internally with a [DynamicMaterialSymbol] for the icon.
/// Centralizes the formatting logic to ensure consistency across all cards.
class UomStatusBadge extends StatelessWidget {
  /// The quantity to display (e.g., 5, 10.5, ∞).
  final double quantity;

  /// The UOM abbreviation from the `symbol` column (e.g., "Kg", "ud.", "ML").
  final String uomAbbreviation;

  /// The Material Symbol icon name from the `icon_name` column (e.g., "fluid_balance").
  final String? uomIconName;

  /// Optional: the maximum stock to show as `quantity/maxStock`.
  final double? maxStock;

  /// Override colors if needed (defaults to `secondaryContainer`).
  final Color? backgroundColor;
  final Color? textColor;

  /// Whether to show the quantity part. Defaults to `true`.
  final bool showQuantity;

  const UomStatusBadge({
    super.key,
    required this.quantity,
    required this.uomAbbreviation,
    this.uomIconName,
    this.maxStock,
    this.backgroundColor,
    this.textColor,
    this.showQuantity = true,
  });

  static String formatQuantity(double value) {
    if (value == double.infinity || value >= 999999.0) return '∞';
    return value.truncateToDouble() == value
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // When quantity is zero and we're showing quantity, display "Sin stock"
    final bool isOutOfStock = showQuantity && quantity <= 0;

    final bgColor = backgroundColor ??
        (isOutOfStock ? colors.errorContainer : colors.secondaryContainer);
    final fgColor = textColor ??
        (isOutOfStock ? colors.onErrorContainer : colors.onSecondaryContainer);

    // Build the text: "Sin stock", "5 Kg", "5/10 Kg", or just "Kg"
    final String badgeText;
    if (isOutOfStock) {
      badgeText = 'Sin stock';
    } else if (!showQuantity) {
      badgeText = uomAbbreviation;
    } else {
      final qtyText = formatQuantity(quantity);
      if (maxStock != null) {
        final maxText = formatQuantity(maxStock!);
        badgeText = '$qtyText/$maxText $uomAbbreviation';
      } else {
        badgeText = '$qtyText $uomAbbreviation';
      }
    }

    // Resolve the icon (fallback to package_2)
    final Widget iconWidget =
        (uomIconName != null && uomIconName!.isNotEmpty)
            ? DynamicMaterialSymbol(
                symbolName: uomIconName!,
                size: 14,
                color: fgColor,
              )
            : Icon(Symbols.package_2, size: 14, color: fgColor);

    return StatusBadge(
      backgroundColor: bgColor,
      textColor: fgColor,
      text: badgeText,
      icon: iconWidget,
    );
  }
}
