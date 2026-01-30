import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'widgets/register_layout.dart';
import 'providers/register_provider.dart';

class RegisterNameScreen extends ConsumerStatefulWidget {
  const RegisterNameScreen({super.key});

  @override
  ConsumerState<RegisterNameScreen> createState() => _RegisterNameScreenState();
}

class _RegisterNameScreenState extends ConsumerState<RegisterNameScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(registerProvider);
    _firstNameController = TextEditingController(text: state.firstName);
    _lastNameController = TextEditingController(text: state.lastName);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(registerProvider.notifier)
          .updateName(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
          );
      context.push('/register/occupation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RegisterLayout(
      title: 'Ingresa tu nombre',
      progress: 3,
      onNext: _onNext,
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              label: 'Nombre*',
              controller: _firstNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Apellido*',
              controller: _lastNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es obligatorio';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
