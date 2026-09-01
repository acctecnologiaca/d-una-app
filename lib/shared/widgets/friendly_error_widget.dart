import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/error_handler.dart';
import '../../core/providers/network_status_provider.dart';

class FriendlyErrorWidget extends ConsumerWidget {
  final dynamic error;
  final VoidCallback? onRetry;

  const FriendlyErrorWidget({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = !ref.watch(networkStatusProvider).isOnline;

    // Si la app está offline o el error corresponde a problemas de conexión/realtime/socket,
    // el bloqueo global modal (ConnectivityGate) es el único responsable de la UI.
    // Silenciamos este widget para no renderizar mensajes degradados en cada pantalla.
    if (isOffline || ErrorHandler.isConnectionError(error)) {
      return const SizedBox.shrink();
    }

    final friendlyMessage = ErrorHandler.getFriendlyMessage(error);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              friendlyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
