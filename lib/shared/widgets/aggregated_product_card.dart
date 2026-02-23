import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
// Removed model dependency to make this a truly shared widget
import '../../core/utils/string_extensions.dart';
import '../utils/currency_formatter.dart';
import 'standard_list_item.dart';

class AggregatedProductCard extends StatelessWidget {
  final String name;
  final String brand;
  final String model;
  final double minPrice;
  final num totalQuantity;
  final int supplierCount;
  final String uom;
  final bool showPriceAndStock;
  final bool isLocked;

  final dynamic onTap;

  const AggregatedProductCard({
    super.key,
    required this.name,
    required this.brand,
    required this.model,
    required this.minPrice,
    required this.totalQuantity,
    required this.supplierCount,
    required this.uom,
    required this.onTap,
    this.showPriceAndStock = true,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StandardListItem(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      onTap: onTap,
      overline: Text(brand.toTitleCase),
      title: name.toTitleCase,
      subtitle: (model.isNotEmpty) ? Text(model.toUpperCase()) : null,
      trailing: showPriceAndStock
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Price
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLocked) ...[
                      Icon(
                        Symbols.lock,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (isLocked)
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Text(
                          CurrencyFormatter.format(minPrice),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                      )
                    else
                      Text(
                        CurrencyFormatter.format(minPrice),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Stats Row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Supplier Count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Symbols.warehouse,
                            size: 14,
                            color: colors.onTertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$supplierCount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quantity
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Symbols.package_2,
                            size: 14,
                            color: colors.onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalQuantity $uom',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : null,
    );
  }
}
