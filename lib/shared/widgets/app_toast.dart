import 'dart:async';
import 'package:flutter/material.dart';

enum AppToastType {
  success,
  error,
  info,
  warning,
}

class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  /// Muestra una notificación flotante centralizada basada en OverlayEntry.
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    // 1. Limpiar toast previo si existe
    dismiss();

    // 2. Obtener Overlay raíz para persistir sobre cierres de modals/pop
    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _AppToastWidget(
        message: message,
        type: type,
        customIcon: icon,
        actionLabel: actionLabel,
        onAction: () {
          dismiss();
          onAction?.call();
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, () {
      dismiss();
    });
  }

  /// Atajo para notificaciones de éxito (Verde)
  static void success(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Atajo para notificaciones de error (Rojo)
  static void error(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Atajo para notificaciones informativas (Azul)
  static void info(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.info,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Atajo para notificaciones de advertencia (Ámbar)
  static void warning(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Cierra y remueve inmediatamente el toast visible.
  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    if (_currentEntry != null) {
      if (_currentEntry!.mounted) {
        _currentEntry!.remove();
      }
      _currentEntry = null;
    }
  }
}

class _AppToastWidget extends StatefulWidget {
  final String message;
  final AppToastType type;
  final IconData? customIcon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AppToastWidget({
    required this.message,
    required this.type,
    this.customIcon,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    if (widget.customIcon != null) return widget.customIcon!;
    switch (widget.type) {
      case AppToastType.success:
        return Icons.check_circle_rounded;
      case AppToastType.error:
        return Icons.error_outline_rounded;
      case AppToastType.warning:
        return Icons.warning_amber_rounded;
      case AppToastType.info:
        return Icons.info_outline_rounded;
    }
  }

  Color _getIconColor(ColorScheme colors) {
    final isLight = colors.brightness == Brightness.light;
    switch (widget.type) {
      case AppToastType.success:
        return isLight ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
      case AppToastType.error:
        return isLight ? const Color(0xFFFFB4AB) : colors.error;
      case AppToastType.warning:
        return isLight ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
      case AppToastType.info:
        return colors.inversePrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      bottom: 24 + bottomInset,
      left: 16,
      right: 16,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.inverseSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _getIcon(),
                      color: _getIconColor(colors),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onInverseSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.actionLabel != null &&
                        widget.onAction != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: widget.onAction,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: colors.inversePrimary,
                        ),
                        child: Text(
                          widget.actionLabel!,
                          style: TextStyle(
                            color: colors.inversePrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
