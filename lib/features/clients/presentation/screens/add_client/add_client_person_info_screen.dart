import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/wizard_bottom_bar.dart';
import 'package:d_una_app/shared/widgets/wizard_progress_bar.dart';
import '../../providers/add_client_provider.dart';
import '../../providers/clients_provider.dart';

class AddClientPersonInfoScreen extends ConsumerStatefulWidget {
  const AddClientPersonInfoScreen({super.key});

  @override
  ConsumerState<AddClientPersonInfoScreen> createState() =>
      _AddClientPersonInfoScreenState();
}

class _AddClientPersonInfoScreenState
    extends ConsumerState<AddClientPersonInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();

  String? get _returnTo =>
      GoRouterState.of(context).uri.queryParameters['returnTo'];

  bool _isLoading = false;
  String? _idError;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    // Reset error on submit attempt
    setState(() => _idError = null);

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Check if ID exists
      final id = _idController.text.trim();
      if (id.isNotEmpty) {
        try {
          final exists = await ref
              .read(clientsProvider.notifier)
              .checkClientExists(id);
          if (exists) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _idError = 'Número de identificación existente';
              });
              _formKey.currentState!
                  .validate(); // Trigger rebuild to show error
            }
            return;
          }
        } catch (e) {
          // Handle error silently or show generic snackbar?
          // For now silent proceed or log.
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ref
            .read(addClientProvider.notifier)
            .updateBasicInfo(
              name: _nameController.text,
              personalID: _idController.text,
            );
        final returnToParam = _returnTo != null ? '&returnTo=$_returnTo' : '';
        context.push('/clients/add/address?type=person$returnToParam');
      }
    }
  }

  Future<void> _onCancelWizard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Si sales ahora, perderás toda la información que has ingresado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Descartar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
        bottom: const WizardProgressBar(totalSteps: 4, currentStep: 2),
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
                        '¿Cuáles son los datos de tu cliente?',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.normal,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Name / Surname
                      CustomTextField(
                        label: 'Nombre y apellido*',
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Identification ID
                      CustomTextField(
                        label: 'Número de identificación (ID)',
                        controller: _idController,
                        validator: (value) {
                          if (_idError != null) return _idError;
                          // Other validations can go here
                          return null;
                        },
                      ),
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
                onNext: _onNext,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
