import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';

/// Helper de compatibilidad para notificaciones de borradores
/// que delega la visualización al componente unificado `AppToast`.
class DraftToast {
  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onDiscard,
    Duration duration = const Duration(seconds: 4),
  }) {
    AppToast.info(
      context,
      message: message,
      icon: Icons.history_rounded,
      actionLabel: 'Descartar',
      onAction: onDiscard,
      duration: duration,
    );
  }

  static void dismiss() {
    AppToast.dismiss();
  }
}
