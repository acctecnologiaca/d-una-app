import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/register_layout.dart';
import 'providers/register_provider.dart';

class RegisterVerificationScreen extends ConsumerStatefulWidget {
  const RegisterVerificationScreen({super.key});

  @override
  ConsumerState<RegisterVerificationScreen> createState() =>
      _RegisterVerificationScreenState();
}

class _RegisterVerificationScreenState
    extends ConsumerState<RegisterVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  int _resendCountdown = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleError(dynamic e, String fallbackMessage) {
    if (!mounted) return;
    String message = fallbackMessage;

    if (e is AuthException) {
      // Mapping verified Supabase Auth codes from official table
      switch (e.code) {
        case 'otp_expired':
          message =
              'El código es inválido o ha expirado. Por favor, verifica e intenta de nuevo o solicita uno nuevo.';
          break;
        case 'over_email_send_rate_limit':
          message =
              'Has solicitado demasiados correos. Espera un momento antes de reintentar.';
          break;
        case 'over_request_rate_limit':
          message =
              'Demasiados intentos desde esta red. Por favor, espera unos minutos.';
          break;
        case 'validation_failed':
          message = 'El formato del código ingresado es incorrecto.';
          break;
        case 'unexpected_failure':
          message =
              'El servicio de correo falló temporalmente. Por favor, intenta de nuevo en unos minutos.';
          break;
        default:
          // Fallback for other auth errors
          if (e.message.toLowerCase().contains('invalid')) {
            message =
                'El código ingresado es incorrecto. Verifica e intenta de nuevo.';
          } else if (e.message.toLowerCase().contains('confirmation email')) {
            message =
                'Hubo un problema al enviar el correo. Por favor, intenta de nuevo más tarde.';
          }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _onVerify() async {
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length == 6) {
      try {
        await ref.read(registerProvider.notifier).verifyCode(otp);
        if (mounted) {
          context.push('/register/success');
        }
      } catch (e) {
        _handleError(e, 'No se pudo verificar el código. Inténtalo de nuevo.');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el código de 6 dígitos'),
        ),
      );
    }
  }

  void _onChanged(String value, int index) {
    // 1. Detectar si el usuario pegó un código múltiple
    if (value.length > 1) {
      // Extraer solo los números
      String digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length > 6) digits = digits.substring(0, 6);

      // Distribuir cada dígito en su controlador correspondiente
      for (int i = 0; i < _controllers.length; i++) {
        if (i < digits.length) {
          _controllers[i].text = digits[i];
        } else {
          _controllers[i].text = '';
        }
      }

      // Mover el foco o auto-verificar
      if (digits.length == 6) {
        _focusNodes[5].unfocus();
        _onVerify(); // Auto-verificar para mayor rapidez
      } else if (digits.isNotEmpty) {
        _focusNodes[digits.length - 1].requestFocus();
      }
      return;
    }

    // 2. Comportamiento normal (tecleo manual)
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus(); // Listo
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read email from state
    final state = ref.read(registerProvider);
    final email = state.email.isNotEmpty
        ? state.email
        : 'tu correo electrónico';

    return PopScope(
      canPop: false,
      child: RegisterLayout(
        title: 'Confirma tu cuenta',
        subtitle: Text.rich(
          TextSpan(
            text:
                'Introduce el código que hemos enviado a tu correo electrónico:\n\n',
            children: [
              TextSpan(
                text: email,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        progress: 5,
        showBackButton: false, // Ocultar flecha del AppBar
        onNext: _onVerify,
        nextButtonText: 'Verificar',
        content: Form(
          key: _formKey,
          child: Column(
            children: [
              // 6-digit PIN Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      onChanged: (value) => _onChanged(value, index),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(6),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: '-',
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: _resendCountdown > 0
                      ? null
                      : () async {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reenviando código...'),
                              ),
                            );
                            await ref
                                .read(registerProvider.notifier)
                                .resendCode();
                            _startResendTimer();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Código reenviado con éxito'),
                                ),
                              );
                            }
                          } catch (e) {
                            _handleError(
                              e,
                              'No se pudo reenviar el código. Inténtalo de nuevo.',
                            );
                          }
                        },
                  child: Text(
                    _resendCountdown > 0
                        ? 'Reenviar código (${_resendCountdown}s)'
                        : 'Reenviar código',
                    style: TextStyle(
                      color: _resendCountdown > 0
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botón de escape: Cambiar correo
              Center(
                child: TextButton(
                  onPressed: () {
                    // Limpiar el estado y volver al paso del correo
                    ref.read(registerProvider.notifier).reset();
                    context.go('/register/email');
                  },
                  child: Text(
                    '¿Escribiste mal tu correo? Cambiar correo',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
