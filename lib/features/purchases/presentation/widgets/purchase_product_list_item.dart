import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/features/portfolio/data/models/uom_model.dart';
import 'package:d_una_app/shared/widgets/dynamic_material_symbol.dart';

class PurchaseProductListItem extends StatelessWidget {
  final String brand;
  final String name;
  final String model;
  final Uom? uom;
  final String? imageUrl;
  final VoidCallback onTap;

  const PurchaseProductListItem({
    super.key,
    required this.brand,
    required this.name,
    required this.model,
    required this.uom,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StandardListItem(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
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
      subtitle: Text(model),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DynamicMaterialSymbol(
              symbolName: uom?.symbolName,
              size: 16,
              color: colors.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              uom?.symbol ?? 'ud.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
