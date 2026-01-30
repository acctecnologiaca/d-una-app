import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import 'widgets/register_layout.dart';
import 'providers/register_provider.dart';

class RegisterEmailScreen extends ConsumerStatefulWidget {
  const RegisterEmailScreen({super.key});

  @override
  ConsumerState<RegisterEmailScreen> createState() =>
      _RegisterEmailScreenState();
}

class _RegisterEmailScreenState extends ConsumerState<RegisterEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final currentEmail = ref.read(registerProvider).email;
    _emailController = TextEditingController(text: currentEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      ref.read(registerProvider.notifier).updateEmail(_emailController.text);
      context.push('/register/password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RegisterLayout(
      title: '¿Cuál es tu correo\nelectrónico?',
      progress: 1,
      onNext: _onNext,
      content: Form(
        key: _formKey,
        child: CustomTextField(
          label: 'Correo electrónico*',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        ),
      ),
    );
  }
}
