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
    // 1. Si el feature flag está deshabilitado por el programador, renderiza directo
    if (!NetworkConfig.isConnectivityGateEnabled) {
      return widget.child;
    }

    final networkState = ref.watch(networkStatusProvider);

    // 2. Escucha transiciones de Offline -> Online para refrescar datos proactivamente
    ref.listen<NetworkStatusState>(networkStatusProvider, (previous, next) {
      if (previous != null && !previous.isOnline && next.isOnline) {
        ReconnectionSyncService.syncAfterReconnection(ref);
      }
    });

    // 3. Renderizado con transición suave
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: !networkState.isOnline
              ? const Positioned.fill(
                  key: ValueKey('no-internet-overlay'),
                  child: NoInternetBlockingOverlay(),
                )
              : const SizedBox.shrink(key: ValueKey('online')),
        ),
      ],
    );
  }
}
