import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/network_status_provider.dart';

class NoInternetBlockingOverlay extends ConsumerStatefulWidget {
  const NoInternetBlockingOverlay({super.key});

  @override
  ConsumerState<NoInternetBlockingOverlay> createState() =>
      _NoInternetBlockingOverlayState();
}

class _NoInternetBlockingOverlayState
    extends ConsumerState<NoInternetBlockingOverlay>
    with SingleTickerProviderStateMixin {
  bool _showRetryError = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final networkState = ref.watch(networkStatusProvider);
    final isChecking = networkState.isChecking;
    final theme = Theme.of(context);

    // Si vuelve la conexión, aseguramos resetear cualquier mensaje de error local
    if (networkState.isOnline && _showRetryError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showRetryError = false);
      });
    }

    // PopScope bloquea el botón físico/gesto de retroceso de Android mientras esté desconectado
    return PopScope(
      canPop: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Capa de desenfoque de fondo y oscurecimiento translúcido
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              color: theme.colorScheme.scrim.withValues(alpha: 0.40),
            ),
          ),

          // 2. Tarjeta Modal Central
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Contenedor circular con icono y animación de pulso
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.wifi_off_rounded,
                            size: 38,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Título
                      Text(
                        'Sin conexión a internet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Mensaje descriptivo
                      Text(
                        'No detectamos acceso a internet. Para proteger la integridad de tus operaciones, el acceso está pausado temporalmente.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón de reintento manual
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: isChecking
                              ? null
                              : () async {
                                  HapticFeedback.lightImpact();
                                  if (_showRetryError) {
                                    setState(() => _showRetryError = false);
                                  }

                                  final isSuccess = await ref
                                      .read(networkStatusProvider.notifier)
                                      .retryManualConnection();

                                  if (!isSuccess && mounted) {
                                    setState(() => _showRetryError = true);
                                  }
                                },
                          child: isChecking
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh_rounded),
                                    SizedBox(width: 8),
                                    Text(
                                      'Reintentar conexión',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // Alerta Inline de error al reintentar (Reemplaza al SnackBar)
                      if (_showRetryError) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: theme.colorScheme.error
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Aún no hay conexión. Por favor verifica tu red Wi-Fi o datos móviles.',
                                  style:
                                      theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Nota al pie
                      Text(
                        'La app se reactivará automáticamente al recuperar señal.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
