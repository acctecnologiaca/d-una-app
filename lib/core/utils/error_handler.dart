import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ErrorHandler {
  /// Determina si un error corresponde a una pérdida o fallo de conexión de red/internet.
  static bool isConnectionError(dynamic error) {
    if (error == null) return false;
    final errorString = error.toString().toLowerCase();
    return error is SocketException ||
        error is RealtimeSubscribeException ||
        errorString.contains('realtimesubscribeexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection timed out') ||
        errorString.contains('clientexception') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection refused') ||
        errorString.contains('handshakeexception') ||
        errorString.contains('channelerror') ||
        errorString.contains('websocket') ||
        errorString.contains('realtime');
  }

  /// Devuelve un texto amigable y predecible para el usuario, escondiendo detalles de implementación backend.
  static String getFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // 1. Errores de Conexión / Internet Local
    if (isConnectionError(error)) {
      return 'Parece que no tienes conexión a internet. Verifícala e intenta nuevamente.';
    }

    // 2. Errores de Autenticación / Sesiones de Supabase
    if (error is AuthException ||
        errorString.contains('invalidjwttoken') ||
        errorString.contains('expired')) {
      return 'Tu sesión actual expiró o es inválida. Por favor, reinicia la app o ingresa de nuevo.';
    }

    // 3. Errores Puros de Base de Datos / PostgREST (Supabase)
    if (error is PostgrestException) {
      if (error.code == '23505') {
        // Violación Unique (Ej: ya existe un registro con el mismo nombre)
        return 'Ya existe un registro con estos datos. Intenta con una información diferente.';
      } else if (error.code == '23503') {
        // Violación de Foreign Key (Intentar borrar algo que está siendo usado)
        return 'Esta acción está restringida, este elemento forma parte de otros registros en uso.';
      } else {
        return 'Ocurrió un problema de comunicación con el servidor de la nube. Intenta de nuevo más tarde.';
      }
    }

    if (error is RealtimeSubscribeException) {
      return 'Problemas conectando con los datos en vivo. Intenta de nuevo más tarde.';
    }

    // 4. Fallback (Error no manejado, se esconde la info técnica)
    // Descomentar la siguiente línea para debug en desarrollo en paralelo
    debugPrint('Unhandled Raw Error: $error');
    return 'Ha ocurrido un error inesperado al procesar tu solicitud.';
  }

  /// Despliega universalmente en la UI una notificación flotante AppToast con estilo y prevención para errores.
  static void showError(BuildContext context, dynamic error) {
    final friendlyMessage = getFriendlyMessage(error);
    AppToast.error(context, message: friendlyMessage);
  }

  /// Alias de compatibilidad para código existente que invoque showErrorSnackBar.
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    showError(context, error);
  }
}
