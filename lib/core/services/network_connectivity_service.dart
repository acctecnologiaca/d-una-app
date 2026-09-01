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
  static const Duration _throttleDuration = Duration(milliseconds: 500);

  NetworkConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Valida si hay salida real a internet con estrategia en 3 niveles:
  /// 1. Socket TCP a DNS primario (1.1.1.1:53)
  /// 2. Socket TCP a DNS secundario (8.8.8.8:53)
  /// 3. HTTP GET a endpoint generate_204 (para firewalls/portales cautivos)
  Future<bool> checkRealInternetConnection({Duration? timeout}) async {
    // Throttle: reutilizar resultado reciente si la última comprobación fue hace < 500ms
    if (_lastResult != null && _lastCheckTime != null) {
      final elapsed = DateTime.now().difference(_lastCheckTime!);
      if (elapsed < _throttleDuration) {
        return _lastResult!;
      }
    }

    final effectiveTimeout = timeout ?? NetworkConfig.checkTimeout;
    bool result = false;

    if (kIsWeb) {
      result = await _checkViaHttp(effectiveTimeout);
    } else {
      result = await _checkViaSocket(
            NetworkConfig.primaryLookupHost,
            effectiveTimeout,
          ) ||
          await _checkViaSocket(
            NetworkConfig.secondaryLookupHost,
            effectiveTimeout,
          ) ||
          await _checkViaHttp(effectiveTimeout);
    }

    _lastResult = result;
    _lastCheckTime = DateTime.now();
    return result;
  }

  /// Nivel 1 y 2: Socket TCP directo a puerto DNS (rápido, sin overhead HTTP).
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

  /// Nivel 3: HTTP GET a endpoint generate_204 (funciona con portales cautivos
  /// y firewalls que bloquean puerto 53). CORS-safe para plataforma Web.
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

  /// Stream transformado que emite `true` si hay internet real y `false` si no.
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
