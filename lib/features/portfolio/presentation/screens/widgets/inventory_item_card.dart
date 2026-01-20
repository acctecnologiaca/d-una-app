import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:cached_network_image/cached_network_image.dart';

class InventoryItemCard extends StatelessWidget {
  final String brand;
  final String name;
  final String model;
  final double price;
  final int stock;
  final String? unit;
  final String? imageUrl;
  final VoidCallback onTap;

  const InventoryItemCard({
    super.key,
    required this.brand,
    required this.name,
    required this.model,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Unit Badge Logic
    final displayUnit = unit ?? 'ud.';
    final unitIcon = _getUnitIcon(displayUnit);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Icon(Icons.image, size: 30),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, size: 30),
                    )
                  : Icon(
                      Icons.inventory_2_outlined,
                      size: 30,
                      color: colors.onSurfaceVariant,
                    ),
            ),

            // Left Content (Details)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant, // Grey
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600, // Medium/Bold
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    model,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant, // Lighter Grey
                    ),
                  ),
                ],
              ),
            ),

            // Right Content (Unit Badge & Price)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(price),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        unitIcon,
                        size: 16,
                        color: colors.onSecondaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$stock $displayUnit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
      ),
    );
  }

  IconData _getUnitIcon(String unit) {
    switch (unit.toLowerCase()) {
      case 'm':
        return Symbols.straighten;
      case 'm²':
      case 'm2':
        return Symbols.square_foot;
      case 'kg':
        return Symbols.weight; // or scale
      case 'g':
        return Symbols.grain; // or diamond
      case 'l':
        return Symbols.water_drop;
      case 'gal':
        return Symbols.local_drink;
      case 'caja':
        return Symbols.package_2;
      case 'set':
        return Symbols.layers;
      case 'ud.':
      default:
        return Symbols.inventory_2;
    }
  }

  String formatCurrency(double amount) {
    // Simple formatter, should use NumberFormat in real app
    // Assuming USD for now based on screenshot ($150,00)
    final intPart = amount.floor();
    final decPart = ((amount - intPart) * 100).round();
    return '\$$intPart,${decPart.toString().padLeft(2, '0')}';
  }
}
