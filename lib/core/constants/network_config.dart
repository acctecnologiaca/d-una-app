import 'package:flutter/foundation.dart';

/// Configuración global para el sistema de detección y bloqueo de conectividad.
@immutable
class NetworkConfig {
  const NetworkConfig._();

  /// Flag principal de desarrollo:
  /// - `true`: Activa la escucha y el bloqueo visual ante pérdida de internet.
  /// - `false`: Desactiva por completo el bloqueo (pruebas locales/offline).
  static const bool isConnectivityGateEnabled = true;

  /// Tiempo de espera para evitar bloqueos por micro-cortes o conmutación Wi-Fi <-> 4G.
  static const Duration debounceDuration = Duration(milliseconds: 1500);

  /// Timeout máximo para la comprobación paralela de sockets TCP.
  static const Duration checkTimeout = Duration(milliseconds: 1800);

  /// Intervalo inicial de polling automático tras detectar desconexión.
  static const Duration initialOfflinePollingInterval = Duration(seconds: 3);

  /// Intervalo máximo de polling con backoff adaptativo para preservar batería.
  static const Duration maxOfflinePollingInterval = Duration(seconds: 8);

  /// Ventana de throttle para reutilizar lecturas muy recientes.
  static const Duration throttleDuration = Duration(milliseconds: 600);

  /// Duración de la animación de transición Fade del overlay de bloqueo.
  static const Duration fadeDuration = Duration(milliseconds: 300);

  /// URL HTTP de fallback para firewalls o portales cautivos (retorna HTTP 204 sin cuerpo).
  static const String fallbackHttpUrl = 'https://clients3.google.com/generate_204';

  /// Hosts IP públicos de alta disponibilidad y puerto DNS estándar para socket ping.
  static const String primaryLookupHost = '1.1.1.1'; // Cloudflare DNS
  static const String secondaryLookupHost = '8.8.8.8'; // Google DNS
  static const int dnsPort = 53;
}

