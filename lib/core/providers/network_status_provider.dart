import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/network_config.dart';
import '../services/network_connectivity_service.dart';

@immutable
class NetworkStatusState {
  final bool isOnline;
  final bool isChecking;
  final bool hasCheckedOnce;
  final DateTime? lastCheckedAt;

  const NetworkStatusState({
    this.isOnline = true,
    this.isChecking = false,
    this.hasCheckedOnce = false,
    this.lastCheckedAt,
  });

  NetworkStatusState copyWith({
    bool? isOnline,
    bool? isChecking,
    bool? hasCheckedOnce,
    DateTime? lastCheckedAt,
  }) {
    return NetworkStatusState(
      isOnline: isOnline ?? this.isOnline,
      isChecking: isChecking ?? this.isChecking,
      hasCheckedOnce: hasCheckedOnce ?? this.hasCheckedOnce,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkStatusState &&
        other.isOnline == isOnline &&
        other.isChecking == isChecking &&
        other.hasCheckedOnce == hasCheckedOnce &&
        other.lastCheckedAt == lastCheckedAt;
  }

  @override
  int get hashCode => Object.hash(
        isOnline,
        isChecking,
        hasCheckedOnce,
        lastCheckedAt,
      );
}

class NetworkStatusNotifier extends StateNotifier<NetworkStatusState> {
  final NetworkConnectivityService _service;
  StreamSubscription<bool>? _subscription;
  Timer? _debounceTimer;
  Timer? _offlinePollingTimer;

  NetworkStatusNotifier(this._service) : super(const NetworkStatusState()) {
    _init();
  }

  Future<void> _init() async {
    if (!NetworkConfig.isConnectivityGateEnabled) {
      state = state.copyWith(isOnline: true, hasCheckedOnce: true);
      return;
    }

    // Comprobación inicial silenciosa
    _service.checkRealInternetConnection().then((hasConnection) {
      if (mounted) {
        state = state.copyWith(
          isOnline: hasConnection,
          hasCheckedOnce: true,
          lastCheckedAt: DateTime.now(),
        );
      }
    });

    // Escucha reactiva de cambios de red
    _subscription = _service.onConnectionStatusChanged.listen((hasConnection) {
      if (!mounted) return;

      if (!hasConnection) {
        // Iniciar ventana de debounce para evitar falsos positivos ante micro-cortes
        _debounceTimer?.cancel();
        _debounceTimer = Timer(NetworkConfig.debounceDuration, () async {
          if (!mounted) return;
          final stillNoConnection =
              !(await _service.checkRealInternetConnection());
          if (mounted && stillNoConnection) {
            state = state.copyWith(
              isOnline: false,
              isChecking: false,
              hasCheckedOnce: true,
              lastCheckedAt: DateTime.now(),
            );
            // Activar polling de auto-recuperación
            _startOfflinePolling();
          }
        });
      } else {
        // Si la conexión volvió, cancelar debounce y polling, desbloquear inmediatamente
        _debounceTimer?.cancel();
        _stopOfflinePolling();
        state = state.copyWith(
          isOnline: true,
          isChecking: false,
          hasCheckedOnce: true,
          lastCheckedAt: DateTime.now(),
        );
      }
    });
  }

  /// Inicia un timer periódico que verifica la reconexión mientras el dispositivo está offline.
  /// Se cancela automáticamente al detectar que la conexión volvió.
  void _startOfflinePolling() {
    _stopOfflinePolling(); // Evitar timers duplicados
    debugPrint('NetworkStatus: Iniciando polling de reconexión offline...');
    _offlinePollingTimer = Timer.periodic(
      NetworkConfig.offlinePollingInterval,
      (_) async {
        if (!mounted) {
          _stopOfflinePolling();
          return;
        }
        final hasConnection = await _service.checkRealInternetConnection();
        if (hasConnection && mounted) {
          debugPrint('NetworkStatus: Polling detectó reconexión.');
          _stopOfflinePolling();
          state = state.copyWith(
            isOnline: true,
            isChecking: false,
            hasCheckedOnce: true,
            lastCheckedAt: DateTime.now(),
          );
        }
      },
    );
  }

  /// Detiene el timer de polling de reconexión.
  void _stopOfflinePolling() {
    _offlinePollingTimer?.cancel();
    _offlinePollingTimer = null;
  }

  /// Fuerza una verificación inmediata del estado de la red.
  /// Útil para invocar cuando la app vuelve de segundo plano (AppLifecycleState.resumed).
  Future<void> checkImmediately() async {
    if (!mounted || !NetworkConfig.isConnectivityGateEnabled) return;
    final hasConnection = await _service.checkRealInternetConnection();
    if (mounted) {
      final wasOffline = !state.isOnline;
      state = state.copyWith(
        isOnline: hasConnection,
        hasCheckedOnce: true,
        lastCheckedAt: DateTime.now(),
      );
      if (hasConnection && wasOffline) {
        _stopOfflinePolling();
      } else if (!hasConnection && wasOffline) {
        _startOfflinePolling();
      }
    }
  }

  /// Permite que interceptores HTTP o manejadores de error notifiquen un fallo de red,
  /// disparando una verificación inmediata del estado real de internet.
  Future<void> notifyNetworkFailure() async {
    if (!mounted || !NetworkConfig.isConnectivityGateEnabled) return;
    debugPrint(
      'NetworkStatus: Notificación de fallo de red recibida. Verificando...',
    );
    await checkImmediately();
  }

  /// Permite forzar un reintento manual inmediato (por ejemplo desde el botón en pantalla)
  Future<bool> retryManualConnection() async {
    if (state.isChecking) return state.isOnline;

    state = state.copyWith(isChecking: true);
    final isConnected = await _service.checkRealInternetConnection();

    if (mounted) {
      if (isConnected) _stopOfflinePolling();
      state = state.copyWith(
        isOnline: isConnected,
        isChecking: false,
        lastCheckedAt: DateTime.now(),
      );
    }

    return isConnected;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _offlinePollingTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

final networkConnectivityServiceProvider =
    Provider<NetworkConnectivityService>((ref) {
  return NetworkConnectivityService();
});

final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkStatusState>((ref) {
  final service = ref.watch(networkConnectivityServiceProvider);
  return NetworkStatusNotifier(service);
});
