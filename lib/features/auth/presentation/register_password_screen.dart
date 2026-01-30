import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import 'widgets/register_layout.dart';
import 'providers/register_provider.dart';

class RegisterPasswordScreen extends ConsumerStatefulWidget {
  const RegisterPasswordScreen({super.key});

  @override
  ConsumerState<RegisterPasswordScreen> createState() =>
      _RegisterPasswordScreenState();
}

class _RegisterPasswordScreenState
    extends ConsumerState<RegisterPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Strict validation regex: At least 8 chars, 1 upper, 1 lower, 1 digit, 1 special char.
  // Special chars: !@#\$&*~ etc.
  // Removed local _validatePassword as we use Validators class now

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden')),
        );
        return;
      }

      ref
          .read(registerProvider.notifier)
          .updatePassword(_passwordController.text);
      context.push('/register/name');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RegisterLayout(
      title: 'Escribe tu contraseña',
      progress: 2,
      onNext: _onNext,
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              label: 'Contraseña*',
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 8),
            // Helper Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                'Debe contener al menos 8 caractéres, números, símbolos y mayúsculas.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Confirma contraseña*',
              controller: _confirmController,
              obscureText: !_isConfirmVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _isConfirmVisible = !_isConfirmVisible),
              ),
              validator: (value) =>
                  Validators.confirmPassword(value, _passwordController.text),
            ),
          ],
        ),
      ),
    );
  }
}
