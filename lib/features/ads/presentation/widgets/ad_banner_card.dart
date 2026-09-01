import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/ad_banner_model.dart';
import '../providers/ads_provider.dart';
import 'ad_detail_bottom_sheet.dart';
import '../../../portfolio/domain/models/aggregated_product.dart';
import '../../../portfolio/presentation/suppliers_directory/screens/supplier_search_screen.dart';
import '../../../portfolio/presentation/suppliers_directory/screens/product_suppliers_screen.dart';

class AdBannerCard extends ConsumerWidget {
  final AdBanner banner;
  final String screenContext;
  final String? searchQuery;

  const AdBannerCard({
    super.key,
    required this.banner,
    required this.screenContext,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0.0),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context, ref),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Logo / Imagen Cuadrada
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          (banner.imageUrl != null &&
                              banner.imageUrl!.isNotEmpty)
                          ? Image.network(
                              banner.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.storefront_outlined,
                                    color: colors.outline,
                                    size: 28,
                                  ),
                            )
                          : Icon(
                              Icons.storefront_outlined,
                              color: colors.outline,
                              size: 28,
                            ),
                    ),
                    const SizedBox(width: 14),

                    // 2. Contenido Central: Advertiser + Título + Subtítulo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (banner.advertiserName != null &&
                              banner.advertiserName!.isNotEmpty) ...[
                            Text(
                              banner.advertiserName!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            banner.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (banner.subtitle != null &&
                              banner.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              banner.subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.onSurfaceVariant,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 3. Columna Derecha: Botón Cerrar (✕) + Badge PUBLICIDAD
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón de Cerrar (✕)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            ref
                                .read(dismissedBannerIdsProvider.notifier)
                                .update((state) => {...state, banner.id});
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Badge PUBLICIDAD alineado al borde derecho
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.tertiaryContainer.withValues(
                              alpha: 0.7,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PUBLICIDAD',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: colors.onTertiaryContainer,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    // 1. Analytics de Click (Fire and Forget)
    ref
        .read(adsRepositoryProvider)
        .recordClick(
          bannerId: banner.id,
          screenContext: screenContext,
          searchQuery: searchQuery,
        );

    // 2. Ejecutar Acción según action_type
    switch (banner.actionType) {
      case AdActionType.externalUrl:
        if (banner.actionPayload != null && banner.actionPayload!.isNotEmpty) {
          launchUrl(
            Uri.parse(banner.actionPayload!),
            mode: LaunchMode.externalApplication,
          );
        }
        break;

      case AdActionType.internalSupplier:
        final supplierId = banner.actionPayload ?? banner.supplierId;
        if (supplierId != null && supplierId.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  SupplierSearchScreen(initialSupplierId: supplierId),
            ),
          );
        }
        break;

      case AdActionType.internalProduct:
        if (banner.actionPayload != null) {
          try {
            final data = jsonDecode(banner.actionPayload!);
            final product = AggregatedProduct(
              name: data['name'] ?? '',
              brand: data['brand'] ?? '',
              model: data['model'] ?? '',
              category: data['category'] ?? 'General',
              minPrice: (data['min_price'] as num?)?.toDouble() ?? 0.0,
              totalQuantity: (data['total_quantity'] as num?)?.toInt() ?? 0,
              supplierCount: (data['supplier_count'] as num?)?.toInt() ?? 1,
              uom: data['uom'] ?? 'ud.',
            );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductSuppliersScreen(product: product),
              ),
            );
          } catch (_) {}
        }
        break;

      case AdActionType.bottomSheet:
        AdDetailBottomSheet.show(context, banner);
        break;

      case AdActionType.none:
        break;
    }
  }
}
