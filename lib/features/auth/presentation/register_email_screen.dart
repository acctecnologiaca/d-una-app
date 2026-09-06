import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import '../../../shared/widgets/custom_dialog.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import 'widgets/register_layout.dart';
import 'providers/register_provider.dart';
import '../data/repositories/auth_repository.dart';

class RegisterEmailScreen extends ConsumerStatefulWidget {
  const RegisterEmailScreen({super.key});

  @override
  ConsumerState<RegisterEmailScreen> createState() =>
      _RegisterEmailScreenState();
}

class _RegisterEmailScreenState extends ConsumerState<RegisterEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final currentEmail = ref.read(registerProvider).email;
    _emailController = TextEditingController(text: currentEmail);
  }

  void _onEmailChanged(String value) {
    final trimmed = value.trim();
    // 1. Clear previous availability error and loading state immediately
    ref.read(registerProvider.notifier).updateEmail(trimmed);

    // 2. Handle debounce for the next validation
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (trimmed.isEmpty) {
      // If empty, we don't start a new check, just ensure everything is clean
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (Validators.email(trimmed) == null) {
        ref.read(registerProvider.notifier).checkEmailAvailability(trimmed);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _onNext() async {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(registerProvider.notifier);
      final email = _emailController.text.trim();
      
      // Final check for email status
      final status = await notifier.checkEmailAvailability(email);
      
      if (!mounted) return;

      if (status == EmailStatus.available) {
        context.push('/register/password');
      } else if (status == EmailStatus.unverified) {
        // Mostrar diálogo informativo y ofrecer reenviar OTP
        final shouldContinue = await CustomDialog.show<bool>(
          context: context,
          dialog: CustomDialog.confirmation(
            title: 'Registro pendiente',
            contentText:
                'Este correo tiene un registro pendiente de confirmación. '
                '¿Deseas recibir un nuevo código de verificación?',
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Reenviar código'),
              ),
            ],
          ),
        );

        if (shouldContinue == true && mounted) {
          try {
            await notifier.resendCode();
            if (mounted) {
              context.push('/register/verification');
            }
          } catch (e) {
            if (mounted) {
              AppToast.error(
                context,
                message: 'No se pudo reenviar el código. Intenta de nuevo.',
              );
            }
          }
        }
      } else if (status == null) {
        AppToast.error(
          context,
          message: 'No se pudo verificar el correo. Verifica tu conexión.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);

    return RegisterLayout(
      title: '¿Cuál es tu correo\nelectrónico?',
      progress: 1,
      onNext: _onNext,
      isLoading: registerState.isCheckingEmail,
      content: Form(
        key: _formKey,
        child: CustomTextField(
          label: 'Correo electrónico*',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
          onChanged: _onEmailChanged,
          errorText: registerState.emailError,
          suffixIcon: registerState.isCheckingEmail
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
