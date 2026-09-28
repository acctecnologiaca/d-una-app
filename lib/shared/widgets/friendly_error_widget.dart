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
    final networkState = ref.watch(networkStatusProvider);
    final isOffline = !networkState.isOnline;
    final isConnErr = ErrorHandler.isConnectionError(error);

    // Auto-recuperación: al recuperar internet (Offline -> Online), ejecutar reintento automático
    ref.listen<NetworkStatusState>(networkStatusProvider, (previous, next) {
      if (previous != null && !previous.isOnline && next.isOnline) {
        onRetry?.call();
      }
    });

    // Si se detecta un error de red pero la app aún figura online, disparar comprobación inmediata
    if (isConnErr && !isOffline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(networkStatusProvider.notifier).notifyNetworkFailure();
      });
    }

    // Solo silenciar si la app está efectivamente offline (ConnectivityGate cubre la pantalla).
    // Si la app está online, se debe mostrar el mensaje y el botón de reintentar.
    if (isOffline) {
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
