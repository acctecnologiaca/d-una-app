import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/ad_banner_model.dart';
import '../../../../../shared/widgets/custom_button.dart';

class AdDetailBottomSheet extends StatelessWidget {
  final AdBanner banner;

  const AdDetailBottomSheet({super.key, required this.banner});

  /// Muestra el modal informativo del anuncio con texto completo e imagen opcional
  static Future<void> show(BuildContext context, AdBanner banner) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdDetailBottomSheet(banner: banner),
    );
  }

  /// Muestra el modal de advertencia y confirmación antes de abrir un enlace externo
  static Future<void> showExternalUrlWarning(
    BuildContext context,
    AdBanner banner,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExternalUrlWarningBottomSheet(banner: banner),
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

            // Imagen publicitaria opcional destacada (afiche del anuncio)
            if (banner.promoImageUrl != null &&
                banner.promoImageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  color: colors.surfaceContainerHighest,
                  child: Image.network(
                    banner.promoImageUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Anunciante / Marca con logo de la empresa opcional
            if (banner.advertiserName != null &&
                banner.advertiserName!.isNotEmpty) ...[
              Row(
                children: [
                  if (banner.imageUrl != null &&
                      banner.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        banner.imageUrl!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    banner.advertiserName!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // Título
            Text(
              banner.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Texto informativo / comunicado
            Text(
              banner.actionPayload ?? banner.subtitle ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),

            // Botón "Entendido" ajustado al texto y alineado a la derecha
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  text: 'Entendido',
                  isFullWidth: false,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExternalUrlWarningBottomSheet extends StatelessWidget {
  final AdBanner banner;

  const _ExternalUrlWarningBottomSheet({required this.banner});

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
            const SizedBox(height: 20),

            // Encabezado con icono
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    color: colors.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enlace externo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (banner.advertiserName != null &&
                          banner.advertiserName!.isNotEmpty)
                        Text(
                          banner.advertiserName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mensaje de advertencia
            Text(
              'Estás a punto de salir de D\'Una App para abrir el siguiente enlace web en tu navegador:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 12),

            // Caja con la URL de destino
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                banner.actionPayload ?? '',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),

            // Botones alineados a la derecha y ajustados al texto
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                CustomButton(
                  text: 'Ir a sitio web',
                  icon: Icons.open_in_new,
                  isFullWidth: false,
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (banner.actionPayload != null &&
                        banner.actionPayload!.isNotEmpty) {
                      launchUrl(
                        Uri.parse(banner.actionPayload!),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
