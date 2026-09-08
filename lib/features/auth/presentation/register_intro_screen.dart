import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/session_manager.dart';
import '../../../shared/widgets/custom_button.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'providers/register_provider.dart';

class RegisterIntroScreen extends ConsumerStatefulWidget {
  const RegisterIntroScreen({super.key});

  @override
  ConsumerState<RegisterIntroScreen> createState() =>
      _RegisterIntroScreenState();
}

class _RegisterIntroScreenState extends ConsumerState<RegisterIntroScreen> {
  bool _isLoadingGoogle = false;

  Future<void> _onGoogleSignUp() async {
    if (_isLoadingGoogle) return;

    setState(() => _isLoadingGoogle = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.signInWithGoogle();

      if (response == null) {
        return;
      }
      await SessionManager().updateLastActive();
      // Redirección automática a /portfolio vía onAuthStateChange
    } catch (e) {
      if (mounted) {
        String message = 'Error al registrarse con Google';
        if (ErrorHandler.isConnectionError(e)) {
          message =
              'No hay conexión a internet. Verifica tu red e intenta de nuevo.';
        } else if (e is AuthException) {
          message = e.message;
        } else {
          message = e.toString().replaceFirst('Exception: ', '');
        }
        AppToast.error(context, message: message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingGoogle = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 22.0, 16.0, 40.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 62,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Title
                      Text(
                        'Crea una cuenta',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                      ),

                      const SizedBox(height: 24),

                      // Hero Image
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/images/new_account.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description Text
                      Text(
                        'Crea una cuenta y comienza a gestionar tu trabajo de manera rápida y sencilla.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                            ),
                      ),

                      const SizedBox(height: 24),

                      // Slogan
                      Text(
                        '¡Házlo ahora, házlo de una!',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),

                      const SizedBox(height: 24),

                      // Buttons
                      CustomButton(
                        text: 'Comenzar',
                        onPressed: _isLoadingGoogle
                            ? null
                            : () {
                                ref.read(registerProvider.notifier).reset();
                                context.push('/register/email');
                              },
                        type: ButtonType.primary,
                      ),

                      const SizedBox(height: 24),

                      // Social Login Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'O accede con',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Google Button
                      Center(
                        child: Tooltip(
                          message: 'Continuar con Google',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoadingGoogle ? null : _onGoogleSignUp,
                              borderRadius: BorderRadius.circular(32),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: _isLoadingGoogle
                                    ? const Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/images/logo_google.png',
                                        height: 48,
                                        width: 48,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: _isLoadingGoogle
                            ? null
                            : () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/login');
                                }
                              },
                        child: Text(
                          'Salir',
                          style: TextStyle(
                            color: _isLoadingGoogle
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
