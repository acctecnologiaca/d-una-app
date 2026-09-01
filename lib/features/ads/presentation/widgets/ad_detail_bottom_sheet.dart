import 'package:flutter/material.dart';
import '../../domain/models/ad_banner_model.dart';
import '../../../../../shared/widgets/custom_button.dart';

class AdDetailBottomSheet extends StatelessWidget {
  final AdBanner banner;

  const AdDetailBottomSheet({super.key, required this.banner});

  static Future<void> show(BuildContext context, AdBanner banner) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdDetailBottomSheet(banner: banner),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Banner Image
            if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  banner.imageUrl!,
                  height: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
              const SizedBox(height: 16),

            // Título
            Text(
              banner.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Subtítulo / Payload text
            Text(
              banner.actionPayload ?? banner.subtitle ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 24),

            // Botón de Cierre o Acción
            CustomButton(
              text: 'Entendido',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
