import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
// Removed model dependency to make this a truly shared widget

import '../utils/currency_formatter.dart';
import 'standard_list_item.dart';
import 'status_badge.dart';
import 'uom_status_badge.dart';

class AggregatedProductCard extends StatelessWidget {
  final String name;
  final String brand;
  final String model;
  final double minPrice;
  final num totalQuantity;
  final int supplierCount;
  final String uom;
  final String? uomIconName;
  final String description;
  final String? imageUrl;
  final bool showPriceAndStock;
  final bool isLocked;
  final bool isAlreadyAdded;

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
    this.uomIconName,
    required this.onTap,
    this.description = '',
    this.imageUrl,
    this.showPriceAndStock = true,
    this.isLocked = false,
    this.isAlreadyAdded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Opacity(
      opacity: isAlreadyAdded ? 0.5 : 1.0,
      child: StandardListItem(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        onTap: onTap,
        leading: (imageUrl != null && imageUrl!.isNotEmpty)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    color: colors.surfaceContainerHighest,
                    child: Icon(Symbols.image, color: colors.onSurfaceVariant),
                  ),
                ),
              )
            : null,
        overline: Text(brand),
        title: name,
        subtitle: (model.isNotEmpty) ? Text(model) : null,
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
                      StatusBadge(
                        backgroundColor: colors.tertiaryContainer,
                        textColor: colors.onTertiaryContainer,
                        text: '$supplierCount',
                        borderRadius: 4.0,
                        icon: Icon(
                          Symbols.warehouse,
                          size: 14,
                          color: colors.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quantity
                      UomStatusBadge(
                        quantity: totalQuantity.toDouble(),
                        uomAbbreviation: uom,
                        uomIconName: uomIconName,
                      ),
                    ],
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
