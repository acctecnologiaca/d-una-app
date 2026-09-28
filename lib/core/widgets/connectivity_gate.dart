import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/network_config.dart';
import '../providers/network_status_provider.dart';
import '../services/reconnection_sync_service.dart';
import '../../shared/widgets/no_internet_blocking_overlay.dart';

class ConnectivityGate extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivityGate({super.key, required this.child});

  @override
  ConsumerState<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends ConsumerState<ConnectivityGate> {
  @override
  Widget build(BuildContext context) {
    // Si el flag está deshabilitado, renderiza directo sin overlay
    if (!NetworkConfig.isConnectivityGateEnabled) {
      return widget.child;
    }

    final networkState = ref.watch(networkStatusProvider);

    // Escucha transiciones de Offline -> Online para refrescar datos proactivamente
    ref.listen<NetworkStatusState>(networkStatusProvider, (previous, next) {
      if (previous != null && !previous.isOnline && next.isOnline) {
        ReconnectionSyncService.syncAfterReconnection(ref);
      }
    });

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Árbol principal de la aplicación
        widget.child,

        // 2. Capa de bloqueo modal estructurada correctamente
        Positioned.fill(
          child: IgnorePointer(
            ignoring: networkState.isOnline,
            child: AnimatedSwitcher(
              duration: NetworkConfig.fadeDuration,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: !networkState.isOnline
                  ? const NoInternetBlockingOverlay(
                      key: ValueKey('no-internet-overlay'),
                    )
                  : const SizedBox.shrink(key: ValueKey('online')),
            ),
          ),
        ),
      ],
    );
  }
}

