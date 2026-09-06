import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import 'providers/register_provider.dart'; // To access authRepositoryProvider
import '../../../shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isLoadingGoogle = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // El redirect global del router manejará la navegación automática a /portfolio
      } catch (e) {
        if (mounted) {
          String message = 'Correo o contraseña incorrecta';
          if (e is AuthException) {
            switch (e.code) {
              case 'email_not_confirmed':
                message =
                    'Tu cuenta aún no ha sido confirmada. Revisa tu correo electrónico.';
                break;
              case 'invalid_credentials':
              case 'invalid_grant':
                message = 'Correo o contraseña incorrecta.';
                break;
              case 'over_request_rate_limit':
                message =
                    'Demasiados intentos fallidos. Por favor, espera unos minutos.';
                break;
              case 'user_banned':
                message = 'Tu cuenta ha sido suspendida. Contacta a soporte.';
                break;
              default:
                if (e.message.toLowerCase().contains('email not confirmed')) {
                  message =
                      'Tu cuenta aún no ha sido confirmada. Revisa tu correo electrónico.';
                } else {
                  message = 'Correo o contraseña incorrecta.';
                }
            }
          } else if (ErrorHandler.isConnectionError(e)) {
            message =
                'No hay conexión a internet. Verifica tu red e intenta de nuevo.';
          }
          AppToast.error(context, message: message);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await CustomDialog.show(
      context: context,
      dialog: CustomDialog.confirmation(
        title: 'Recuperar contraseña',
        contentWidget: StatefulBuilder(
          builder: (context, setDialogState) {
            return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa tu correo electrónico para recibir un enlace de recuperación.',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Correo electrónico',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final email = emailController.text.trim();
                Navigator.of(context).pop();
                try {
                  await ref
                      .read(authRepositoryProvider)
                      .resetPassword(email: email);
                  if (mounted) {
                    AppToast.success(
                      context,
                      message: 'Se ha enviado un correo de recuperación.',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    if (ErrorHandler.isConnectionError(e)) {
                      AppToast.error(
                        context,
                        message: 'No hay conexión a internet. Verifica tu red.',
                      );
                    } else {
                      AppToast.error(
                        context,
                        message:
                            'No se pudo enviar la solicitud. Intenta de nuevo.',
                      );
                    }
                  }
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Future<void> _onGoogleLogin() async {
    // Bloquear si ya hay una operación de login en curso
    if (_isLoading || _isLoadingGoogle) return;

    setState(() => _isLoadingGoogle = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.signInWithGoogle();

      if (response == null) {
        // El usuario canceló la selección de cuenta (tocó fuera del sheet)
        // No mostrar error, simplemente retornar al estado normal
        return;
      }
      // Si llegamos aquí, signInWithIdToken fue exitoso.
      // GoRouter detecta automáticamente la sesión nueva vía onAuthStateChange
      // y redirige a /portfolio. No se requiere navegación manual.
    } catch (e) {
      if (mounted) {
        String message = 'Error al iniciar sesión con Google';
        if (ErrorHandler.isConnectionError(e)) {
          message =
              'No hay conexión a internet. Verifica tu red e intenta de nuevo.';
        } else if (e is AuthException) {
          message = e.message;
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
      // backgroundColor: Colors.white, // Using Theme Surface
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 22.0, 16.0, 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              //mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo_d_una.png',
                    height: 60, // Approximate height
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Iniciar sesión',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 48),

                // Email Field
                CustomTextField(
                  label: 'Correo electrónico',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  suffixIcon: const Icon(Icons.email_outlined),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),

                // Password Field
                CustomTextField(
                  label: 'Contraseña',
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Login Button
                CustomButton(
                  text: 'Iniciar sesión',
                  onPressed: _isLoading ? null : _onLogin,
                  type: ButtonType.primary,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),

                // Forgot Password Link
                Center(
                  child: GestureDetector(
                    onTap: _showForgotPasswordDialog,
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Create Account Button
                CustomButton(
                  text: 'Crear una cuenta nueva',
                  onPressed: () {
                    ref.read(registerProvider.notifier).reset();
                    context.push('/register');
                  },
                  type: ButtonType.secondary,
                ),
                const SizedBox(height: 32),

                // Social Login Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Accede con',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Google Button
                Center(
                  child: InkWell(
                    onTap: (_isLoading || _isLoadingGoogle)
                        ? null
                        : _onGoogleLogin,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: _isLoadingGoogle
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
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
                //const SizedBox(height: 24),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
