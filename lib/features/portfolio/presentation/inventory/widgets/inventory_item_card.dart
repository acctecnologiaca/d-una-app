import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/standard_list_item.dart';

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

    return StandardListItem(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      onTap: onTap,
      leading: Container(
        width: 60,
        height: 60,
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
      overline: Text(brand),
      title: name,
      subtitle: Text(model), // Already styled by StandardListItem
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.format(price),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(unitIcon, size: 16, color: colors.onSecondaryContainer),
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
        return Symbols.package_2;
    }
  }
}
