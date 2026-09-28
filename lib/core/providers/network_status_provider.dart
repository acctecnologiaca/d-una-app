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
  bool _isPollingInProgress = false;
  int _offlinePollAttempts = 0;

  NetworkStatusNotifier(this._service) : super(const NetworkStatusState()) {
    _init();
  }

  Future<void> _init() async {
    if (!NetworkConfig.isConnectivityGateEnabled) {
      state = state.copyWith(isOnline: true, hasCheckedOnce: true);
      return;
    }

    // 1. Hardware fast-check: Si no hay interfaz física activa, marcamos offline de inmediato (<5ms)
    // para que ConnectivityGate bloquee antes de que se disparen peticiones a Supabase/APIs.
    final hasHardware = await _service.hasActiveNetworkInterface();
    if (!hasHardware && mounted) {
      state = state.copyWith(
        isOnline: false,
        hasCheckedOnce: true,
        lastCheckedAt: DateTime.now(),
      );
      _startOfflinePolling();
    }

    // 2. Comprobación profunda de sockets en paralelo
    _service.checkRealInternetConnection().then((hasConnection) {
      if (!mounted) return;
      state = state.copyWith(
        isOnline: hasConnection,
        hasCheckedOnce: true,
        lastCheckedAt: DateTime.now(),
      );
      if (!hasConnection) {
        _startOfflinePolling();
      } else {
        _stopOfflinePolling();
      }
    });

    // Escucha reactiva del stream de conectividad
    _subscription = _service.onConnectionStatusChanged.listen((hasConnection) {
      if (!mounted) return;

      if (!hasConnection) {
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
            _startOfflinePolling();
          }
        });
      } else {
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

  /// Inicia polling de auto-recuperación con backoff adaptativo y sin solapamiento.
  void _startOfflinePolling() {
    _stopOfflinePolling();
    _offlinePollAttempts = 0;
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    if (!mounted || state.isOnline) return;

    // Backoff adaptativo: 3s -> 5s -> 8s máximo
    final Duration delay;
    if (_offlinePollAttempts < 2) {
      delay = NetworkConfig.initialOfflinePollingInterval;
    } else if (_offlinePollAttempts < 5) {
      delay = const Duration(seconds: 5);
    } else {
      delay = NetworkConfig.maxOfflinePollingInterval;
    }

    _offlinePollingTimer?.cancel();
    _offlinePollingTimer = Timer(delay, () async {
      if (!mounted || state.isOnline || _isPollingInProgress) return;

      _isPollingInProgress = true;
      try {
        final hasConnection = await _service.checkRealInternetConnection();
        if (!mounted) return;

        if (hasConnection) {
          debugPrint('NetworkStatus: Polling detectó reconexión.');
          _stopOfflinePolling();
          state = state.copyWith(
            isOnline: true,
            isChecking: false,
            hasCheckedOnce: true,
            lastCheckedAt: DateTime.now(),
          );
        } else {
          _offlinePollAttempts++;
          _scheduleNextPoll();
        }
      } finally {
        _isPollingInProgress = false;
      }
    });
  }

  void _stopOfflinePolling() {
    _offlinePollingTimer?.cancel();
    _offlinePollingTimer = null;
    _isPollingInProgress = false;
    _offlinePollAttempts = 0;
  }

  /// Fuerza comprobación inmediata (útil en AppLifecycleState.resumed).
  Future<void> checkImmediately() async {
    if (!mounted || !NetworkConfig.isConnectivityGateEnabled) return;
    final hasConnection = await _service.checkRealInternetConnection(force: true);
    if (!mounted) return;

    final wasOffline = !state.isOnline;
    state = state.copyWith(
      isOnline: hasConnection,
      hasCheckedOnce: true,
      lastCheckedAt: DateTime.now(),
    );

    // Corrección Bug B: Activar o desactivar polling correctamente según el nuevo estado
    if (hasConnection) {
      if (wasOffline) _stopOfflinePolling();
    } else {
      if (_offlinePollingTimer == null) _startOfflinePolling();
    }
  }

  /// Notificación proactiva de fallas detectadas por interceptores HTTP o repositories.
  Future<void> notifyNetworkFailure() async {
    if (!mounted || !NetworkConfig.isConnectivityGateEnabled) return;
    debugPrint('NetworkStatus: Notificación de fallo de red. Verificando...');
    await checkImmediately();
  }

  /// Reintento manual disparado por el usuario desde la UI.
  Future<bool> retryManualConnection() async {
    if (state.isChecking) return state.isOnline;

    state = state.copyWith(isChecking: true);
    final isConnected = await _service.checkRealInternetConnection(force: true);

    if (mounted) {
      if (isConnected) {
        _stopOfflinePolling();
      } else {
        if (_offlinePollingTimer == null) _startOfflinePolling();
      }

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
    _stopOfflinePolling();
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

