import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/network_config.dart';

class NetworkConnectivityService {
  final Connectivity _connectivity;

  /// Cache de resultado reciente para evitar llamadas concurrentes masivas.
  bool? _lastResult;
  DateTime? _lastCheckTime;

  /// Promesa en vuelo activa para deduplicar peticiones simultáneas.
  Future<bool>? _inFlightCheck;

  NetworkConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Valida si hay salida real a internet.
  /// - Si [force] es true, ignora el throttle de caché reciente.
  /// - Si ya hay una comprobación en curso, reusa el mismo Future.
  Future<bool> checkRealInternetConnection({
    Duration? timeout,
    bool force = false,
  }) async {
    // 1. Throttle: reusar si no es forzado y pasaron menos de throttleDuration
    if (!force && _lastResult != null && _lastCheckTime != null) {
      final elapsed = DateTime.now().difference(_lastCheckTime!);
      if (elapsed < NetworkConfig.throttleDuration) {
        return _lastResult!;
      }
    }

    // 2. Deduplicación de peticiones concurrentes
    if (_inFlightCheck != null) {
      return _inFlightCheck!;
    }

    final effectiveTimeout = timeout ?? NetworkConfig.checkTimeout;
    _inFlightCheck = _executeVerification(effectiveTimeout);

    try {
      final result = await _inFlightCheck!;
      _lastResult = result;
      _lastCheckTime = DateTime.now();
      return result;
    } finally {
      _inFlightCheck = null;
    }
  }

  /// Comprueba instantáneamente (<5ms) si existe al menos una interfaz de hardware activa
  /// (WiFi, Móvil, Ethernet).
  Future<bool> hasActiveNetworkInterface() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty ||
          results.every((result) => result == ConnectivityResult.none)) {
        return false;
      }
      return true;
    } catch (_) {
      return true; // En caso de fallo de plataforma, no asumir desconexión
    }
  }

  Future<bool> _executeVerification(Duration timeout) async {
    // Si la interfaz de hardware está completamente desconectada (modo avión, radios apagadas),
    // podemos retornar false de inmediato (<5ms) sin desperdiciar el timeout de sockets.
    final hasHardware = await hasActiveNetworkInterface();
    if (!hasHardware) {
      return false;
    }

    if (kIsWeb) {
      return await _checkViaHttp(timeout);
    }

    // 1. Carrera paralela de sockets DNS primario y secundario
    final socketSuccess = await _checkSocketsInParallel(timeout);
    if (socketSuccess) {
      return true;
    }

    // 2. Fallback HTTP (portales cautivos / firewalls que bloquean puerto 53)
    return await _checkViaHttp(timeout);
  }

  /// Ejecuta sockets TCP a 1.1.1.1:53 y 8.8.8.8:53 en paralelo.
  /// Si cualquiera tiene éxito, retorna true de inmediato sin esperar al otro.
  Future<bool> _checkSocketsInParallel(Duration timeout) async {
    final completer = Completer<bool>();
    int failureCount = 0;
    const totalChecks = 2;

    void onSuccess() {
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    }

    void onFailure() {
      failureCount++;
      if (failureCount >= totalChecks && !completer.isCompleted) {
        completer.complete(false);
      }
    }

    _checkViaSocket(NetworkConfig.primaryLookupHost, timeout)
        .then((ok) => ok ? onSuccess() : onFailure())
        .catchError((_) => onFailure());

    _checkViaSocket(NetworkConfig.secondaryLookupHost, timeout)
        .then((ok) => ok ? onSuccess() : onFailure())
        .catchError((_) => onFailure());

    return completer.future;
  }

  /// Socket TCP directo a puerto DNS (rápido, sin overhead HTTP).
  Future<bool> _checkViaSocket(String host, Duration timeout) async {
    try {
      final socket = await Socket.connect(
        host,
        NetworkConfig.dnsPort,
        timeout: timeout,
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// HTTP GET a generate_204 con timeout controlado.
  Future<bool> _checkViaHttp(Duration timeout) async {
    try {
      final response = await http
          .get(Uri.parse(NetworkConfig.fallbackHttpUrl))
          .timeout(timeout);
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  /// Stream reactivo que emite cambios de conectividad real.
  Stream<bool> get onConnectionStatusChanged {
    return _connectivity.onConnectivityChanged.asyncMap((results) async {
      final hasNoInterface = results.isEmpty ||
          results.every((result) => result == ConnectivityResult.none);

      if (hasNoInterface) {
        return false;
      }

      return await checkRealInternetConnection();
    }).distinct();
  }
}

