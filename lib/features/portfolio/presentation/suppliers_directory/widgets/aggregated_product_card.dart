import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../domain/models/aggregated_product.dart';
import '../../../../../core/utils/string_extensions.dart';

class AggregatedProductCard extends StatelessWidget {
  final AggregatedProduct product;
  final bool showPriceAndStock;
  final bool isLocked;

  final dynamic onTap;

  const AggregatedProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showPriceAndStock = true,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ... Image Placeholder removed ...

            // Middle: Brand, Name, Model
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.toTitleCase,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.name.toTitleCase,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      if (isLocked) ...[
                        // Removed lock icon from here as per request
                      ],
                    ],
                  ),
                  if (product.model.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.model.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right: Price, Suppliers, Quantity
            if (showPriceAndStock)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Price
                  // isLocked: Always show price as per user request
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
                            _formatCurrency(product.minPrice),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        )
                      else
                        Text(
                          _formatCurrency(product.minPrice),
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
                              '${product.supplierCount}',
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
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // Pill shape for stock
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
                              '${product.totalQuantity} ${product.uom}',
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
              ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    // Simple formatter matching the style
    final intPart = amount.floor();
    final decPart = ((amount - intPart) * 100).round();
    return '\$$intPart,${decPart.toString().padLeft(2, '0')}';
  }
}
