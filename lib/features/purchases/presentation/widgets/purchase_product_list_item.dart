import 'package:d_una_app/core/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/features/portfolio/data/models/uom_model.dart';
import 'package:d_una_app/shared/widgets/product_image_avatar.dart';
import 'package:d_una_app/shared/widgets/status_badge.dart';
import 'package:d_una_app/shared/widgets/dynamic_material_symbol.dart';

class PurchaseProductListItem extends StatelessWidget {
  final String brand;
  final String name;
  final String model;
  final Uom? uom;
  final String? imageUrl;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onDisabledTap;

  const PurchaseProductListItem({
    super.key,
    required this.brand,
    required this.name,
    required this.model,
    required this.uom,
    this.imageUrl,
    required this.onTap,
    this.enabled = true,
    this.onDisabledTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: StandardListItem(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        onTap: enabled ? onTap : onDisabledTap,
        leading: ProductImageAvatar(imageUrl: imageUrl),
        overline: Text(brand.toTitleCase),
        title: name,
        subtitle: Text(model),
        trailing: StatusBadge(
          backgroundColor: enabled
              ? colors.secondaryContainer
              : colors.outlineVariant,
          textColor: enabled
              ? colors.onSecondaryContainer
              : colors.onSurfaceVariant,
          text: uom?.symbol ?? 'ud.',
          icon: DynamicMaterialSymbol(
            symbolName: uom?.iconName,
            size: 16,
            color: enabled
                ? colors.onSecondaryContainer
                : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
