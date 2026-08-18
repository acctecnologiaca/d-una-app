import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/wizard_bottom_bar.dart';
import 'package:d_una_app/shared/widgets/wizard_progress_bar.dart';
import '../../providers/add_client_provider.dart';
import '../../providers/clients_provider.dart';
import 'package:d_una_app/features/quotes/presentation/create_quote/providers/create_quote_provider.dart';

class AddClientContactScreen extends ConsumerStatefulWidget {
  const AddClientContactScreen({super.key});

  @override
  ConsumerState<AddClientContactScreen> createState() =>
      _AddClientContactScreenState();
}

class _AddClientContactScreenState
    extends ConsumerState<AddClientContactScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get _isPerson =>
      GoRouterState.of(context).uri.queryParameters['type'] == 'person';

  String? get _returnTo =>
      GoRouterState.of(context).uri.queryParameters['returnTo'];

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _positionController = TextEditingController(); // Cargo
  final _departmentController = TextEditingController();

  String _selectedCode = '0424';
  final List<String> _codes = ['0412', '0422', '0414', '0424', '0416', '0426'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _onFinish() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 1. Add Contact to Provider
        final contactData = {
          'name': _isPerson
              ? ref.read(addClientProvider)['name'] ?? 'Cliente'
              : _nameController.text,
          'role': _positionController.text,
          'department': _departmentController.text,
          'email': _emailController.text,
          'phone':
              '$_selectedCode${_phoneController.text.replaceAll(RegExp(r'\D'), '')}',
          'isPrimary': true,
        };

        final notifier = ref.read(addClientProvider.notifier);

        if (_isPerson) {
          notifier.updateBasicInfo(
            email: _emailController.text,
            phone:
                '$_selectedCode${_phoneController.text.replaceAll(RegExp(r'\D'), '')}',
          );
        } else {
          notifier.addContact(contactData);
        }

        // 2. Submit
        final newClientId = await notifier.submit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente agregado exitosamente')),
          );

          if (_returnTo != null && _returnTo!.contains('/quotes/create')) {
            final client = await ref
                .read(clientsRepositoryProvider)
                .getClient(newClientId);
            if (client != null && mounted) {
              ref.read(createQuoteProvider.notifier).setClient(client);
            }
          }

          if (!mounted) return;

          if (_returnTo != null) {
            context.go(_returnTo!);
          } else {
            context.go('/clients');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar cliente: $e')),
          );
        }
      }
    }
  }

  Future<void> _onCancelWizard() async {
    final colors = Theme.of(context).colorScheme;
    final confirmed = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.destructive(
        title: '¿Descartar cambios?',
        contentText:
            'Si sales ahora, perderás toda la información que has ingresado.',
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (_returnTo != null) {
        context.go(_returnTo!);
      } else {
        context.go('/clients');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onCancelWizard,
        ),
        title: Text(
          'Agregar cliente',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        bottom: const WizardProgressBar(totalSteps: 4, currentStep: 4),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isPerson ? 'Datos de contácto' : 'Persona de contácto',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.normal,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Name (Only for Company)
                      if (!_isPerson) ...[
                        CustomTextField(
                          label: 'Nombre y apellido*',
                          controller: _nameController,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Phone Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 0.0),
                            child: SizedBox(
                              width: 110,
                              child: CustomDropdown<String>(
                                label: 'Código',
                                value: _selectedCode,
                                items: _codes,
                                itemLabelBuilder: (item) => item,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCode = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: 'Teléfono*',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Requerido';
                                }
                                if (value.length != 7) {
                                  return 'Debe tener 7 dígitos';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Email
                      CustomTextField(
                        label: 'Correo electrónico',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null;
                          }
                          // Simple Regex for email
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Correo inválido';
                          }
                          return null;
                        },
                      ),
                      // Position and Department (Only for Company)
                      if (!_isPerson) ...[
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Cargo',
                          controller: _positionController,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Departamento',
                          controller: _departmentController,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: WizardButtonBar(
                onCancel: _onCancelWizard,
                onBack: () => context.pop(),
                onNext: _onFinish,
                isLastStep: true,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
