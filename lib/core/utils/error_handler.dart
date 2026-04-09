import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ErrorHandler {
  /// Devuelve un texto amigable y predecible para el usuario, escondiendo detalles de implementación backend.
  static String getFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // 1. Errores de Conexión / Internet Local
    if (error is SocketException ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection timed out') ||
        errorString.contains('clientexception')) {
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
    // debugPrint('Unhandled Raw Error: $error'); 
    return 'Ha ocurrido un error inesperado al procesar tu solicitud.';
  }

  /// Despliega universalmente en la UI un SnackBar con estilo y prevención para Stack_overflows o UI desconfigurado debido a errores largos.
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final friendlyMessage = getFriendlyMessage(error);
    
    // Removemos cualquier snackbar actual para no encimar los mensajes
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(friendlyMessage)),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
