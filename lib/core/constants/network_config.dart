import 'package:flutter/foundation.dart';

/// Configuración global para el sistema de detección y bloqueo de conectividad.
@immutable
class NetworkConfig {
  const NetworkConfig._();

  /// FLAG PRINCIPAL DE DESARROLLADOR:
  /// - `true`: Activa la escucha y el bloqueo visual ante pérdida de internet.
  /// - `false`: Desactiva por completo el bloqueo (ideal para pruebas locales/offline).
  static const bool isConnectivityGateEnabled = true;

  /// Tiempo de espera para evitar bloqueos por micro-cortes o conmutación Wi-Fi <-> 4G.
  static const Duration debounceDuration = Duration(milliseconds: 1500);

  /// Timeout máximo para la comprobación de socket TCP / DNS real.
  static const Duration checkTimeout = Duration(milliseconds: 2500);

  /// Intervalo de polling automático para verificar reconexión mientras la app esté offline.
  /// Tras detectar desconexión, se ejecuta un Timer.periodic con este intervalo.
  static const Duration offlinePollingInterval = Duration(seconds: 4);

  /// URL HTTP de fallback para verificar salida a internet cuando los sockets
  /// TCP en puerto 53 son bloqueados (firewalls, portales cautivos).
  /// Endpoint ultra-ligero que responde HTTP 204 sin payload.
  static const String fallbackHttpUrl = 'https://clients3.google.com/generate_204';

  /// Hosts IP públicos de alta disponibilidad y puerto DNS estándar para socket ping.
  static const String primaryLookupHost = '1.1.1.1'; // Cloudflare DNS
  static const String secondaryLookupHost = '8.8.8.8'; // Google DNS
  static const int dnsPort = 53;
}
