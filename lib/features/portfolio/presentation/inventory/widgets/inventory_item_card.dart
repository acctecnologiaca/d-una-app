import 'package:flutter/material.dart';
import '../../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/standard_list_item.dart';
import '../../../../../shared/widgets/product_image_avatar.dart';
import '../../../../../shared/widgets/uom_status_badge.dart';

class InventoryItemCard extends StatelessWidget {
  final String brand;
  final String name;
  final String model;
  final double price;
  final double stock;
  final String? unit;
  final String? uomIconName;
  final String? imageUrl;
  final VoidCallback onTap;

  const InventoryItemCard({
    super.key,
    required this.brand,
    required this.name,
    required this.model,
    required this.price,
    required this.stock,
    this.unit,
    this.uomIconName,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StandardListItem(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      onTap: onTap,
      leading: ProductImageAvatar(imageUrl: imageUrl),
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
          UomStatusBadge(
            quantity: stock,
            uomAbbreviation: unit ?? 'ud.',
            uomIconName: uomIconName,
          ),
        ],
      ),
    );
  }
}
