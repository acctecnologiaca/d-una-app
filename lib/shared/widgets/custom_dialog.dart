import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String? contentText;
  final Widget? contentWidget;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;
  final List<Widget> actions;
  final bool verticalActions;

  const CustomDialog._({
    super.key,
    required this.title,
    this.contentText,
    this.contentWidget,
    this.icon,
    this.iconColor,
    this.isDestructive = false,
    required this.actions,
    this.verticalActions = false,
  });

  /// Diálogo estándar para confirmaciones o información.
  /// Los botones se alinean horizontalmente a la derecha.
  factory CustomDialog.confirmation({
    Key? key,
    required String title,
    String? contentText,
    Widget? contentWidget,
    IconData? icon,
    Color? iconColor,
    required List<Widget> actions,
  }) {
    return CustomDialog._(
      key: key,
      title: title,
      contentText: contentText,
      contentWidget: contentWidget,
      icon: icon,
      iconColor: iconColor,
      actions: actions,
    );
  }

  /// Diálogo especializado para acciones destructivas (eliminar, descartar).
  /// El título se resalta en rojo y usa un icono de advertencia por defecto.
  factory CustomDialog.destructive({
    Key? key,
    required String title,
    String? contentText,
    Widget? contentWidget,
    IconData? icon = Symbols.warning,
    required List<Widget> actions,
  }) {
    return CustomDialog._(
      key: key,
      title: title,
      contentText: contentText,
      contentWidget: contentWidget,
      icon: icon,
      isDestructive: true,
      actions: actions,
    );
  }

  /// Diálogo para múltiples opciones o botones de ancho completo.
  /// Apila las acciones verticalmente (ideal para selectores o menús).
  factory CustomDialog.vertical({
    Key? key,
    required String title,
    String? contentText,
    Widget? contentWidget,
    IconData? icon,
    Color? iconColor,
    required List<Widget> actions,
  }) {
    return CustomDialog._(
      key: key,
      title: title,
      contentText: contentText,
      contentWidget: contentWidget,
      icon: icon,
      iconColor: iconColor,
      actions: actions,
      verticalActions: true,
    );
  }

  /// Helper estático para mostrar el diálogo fácilmente sin escribir showDialog
  static Future<T?> show<T>({
    required BuildContext context,
    required CustomDialog dialog,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => dialog,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final effectiveIconColor = isDestructive
        ? colors.error
        : (iconColor ?? colors.primary);

    Widget? finalContent;

    // Si es vertical, las acciones se meten dentro del content para que ocupen todo el ancho
    if (verticalActions) {
      finalContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contentText != null)
            Text(
              contentText!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ?contentWidget,
          if (contentText != null || contentWidget != null)
            const SizedBox(height: 24),
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: action,
            ),
          ),
        ],
      );
    } else {
      if (contentText != null) {
        finalContent = Text(
          contentText!,
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        );
      } else if (contentWidget != null) {
        finalContent = contentWidget;
      }
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colors.surfaceContainerHigh,
      icon: icon != null
          ? Icon(icon, size: 28, color: effectiveIconColor)
          : null,
      title: Text(
        title,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDestructive ? colors.error : colors.onSurface,
        ),
        // Si hay icono o es vertical, centramos el texto por defecto
        textAlign: (icon != null || verticalActions)
            ? TextAlign.center
            : TextAlign.start,
      ),
      content: finalContent,
      // Si no es vertical, usamos el actions nativo del AlertDialog
      actions: verticalActions ? null : actions,
    );
  }
}
