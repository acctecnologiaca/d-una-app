import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductImageAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final IconData placeholderIcon;

  const ProductImageAvatar({
    super.key,
    this.imageUrl,
    this.size = 60.0,
    this.borderRadius = 8.0,
    this.placeholderIcon = Icons.inventory_2_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Icon(Icons.image, size: size * 0.5, color: colors.onSurfaceVariant),
              errorWidget: (context, url, error) =>
                  Icon(Icons.broken_image, size: size * 0.5, color: colors.onSurfaceVariant),
            )
          : Icon(
              placeholderIcon,
              size: size * 0.5,
              color: colors.onSurfaceVariant,
            ),
    );
  }
}
