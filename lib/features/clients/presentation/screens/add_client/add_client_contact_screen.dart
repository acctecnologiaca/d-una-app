import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/wizard_bottom_bar.dart';
import 'package:d_una_app/shared/widgets/wizard_progress_bar.dart';
import '../../providers/add_client_provider.dart';
import '../../providers/clients_provider.dart';

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

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _positionController = TextEditingController(); // Cargo
  final _departmentController = TextEditingController();

  String _selectedCode = '0424';
  final List<String> _codes = ['0414', '0424', '0412', '0416', '0426'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _onFinish() async {
    if (_formKey.currentState!.validate()) {
      // 1. Add Contact to Provider
      final contactData = {
        'name': _isPerson
            ? ref.read(addClientProvider)['name'] ?? 'Cliente'
            : _nameController
                  .text, // If person, contact name is same as client? Or empty? Logic check.
        // If it's a "Person" client, the contact info IS the client's contact info.
        // If "Company", it's a contact person.
        'role': _positionController.text,
        'department': _departmentController.text,
        'email': _emailController.text,
        'phone':
            '$_selectedCode${_phoneController.text.replaceAll(RegExp(r'\D'), '')}',
        'isPrimary': true,
      };

      // For "Person" client type, we might want to update the main client info with this data as well.
      // Re-reading logic: Person clients behave like their own contact.
      // Provider `updateBasicInfo` had email/phone.
      // If `_isPerson`, we should probably update the main client info with this data as well.

      final notifier = ref.read(addClientProvider.notifier);

      if (_isPerson) {
        notifier.updateBasicInfo(
          email: _emailController.text,
          phone:
              '$_selectedCode${_phoneController.text.replaceAll(RegExp(r'\D'), '')}',
        );
      } else {
        // Add as distinct contact
        notifier.addContact(contactData);
      }

      // 2. Submit
      await notifier.submit();

      // Check for success (optional, or rely on ClientsProvider state)
      // Since `addClient` (provider) awaits, we can check `ref.read(clientsProvider)` for value vs error

      final clientsState = ref.read(clientsProvider);

      if (clientsState is AsyncData) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente agregado exitosamente')),
          );
          context.go('/clients');
        }
      } else if (clientsState is AsyncError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${clientsState.error}')),
          );
        }
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
                              width: 100,
                              child: CustomDropdown<String>(
                                label: 'Cod.',
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
                onCancel: () {
                  context.go('/clients');
                },
                onBack: () => context.pop(),
                onNext: _onFinish,
                isLastStep: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
