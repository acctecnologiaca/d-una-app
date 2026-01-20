import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  Future<void> _onVerify() async {
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length == 6) {
      try {
        await ref.read(registerProvider.notifier).verifyCode(otp);
        if (mounted) {
          context.push('/register/success');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
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
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus(); // Done
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

    return RegisterLayout(
      title: 'Confirma tu cuenta',
      subtitle:
          'Introduce el código que hemos enviado a tu correo electrónico:\n\n$email',
      progress: 0.95, // Approx step 7/7
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
                      LengthLimitingTextInputFormatter(1),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: '-',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al reenviar: $e')),
                            );
                          }
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
          ],
        ),
      ),
    );
  }
}
