import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import '../../providers/add_client_provider.dart';
import '../../providers/clients_provider.dart';

class AddClientCompanyInfoScreen extends ConsumerStatefulWidget {
  const AddClientCompanyInfoScreen({super.key});

  @override
  ConsumerState<AddClientCompanyInfoScreen> createState() =>
      _AddClientCompanyInfoScreenState();
}

class _AddClientCompanyInfoScreenState
    extends ConsumerState<AddClientCompanyInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController(); // RIF
  final _aliasController = TextEditingController();

  bool _isLoading = false;
  String? _rifError;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    setState(() => _rifError = null);

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Check if RIF exists
      final rif = _idController.text.trim();
      if (rif.isNotEmpty) {
        try {
          final exists = await ref
              .read(clientsProvider.notifier)
              .checkClientExists(rif);
          if (exists) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _rifError = 'RIF/Identificación existente';
              });
              _formKey.currentState!.validate();
            }
            return;
          }
        } catch (e) {
          // Handle error
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ref
            .read(addClientProvider.notifier)
            .updateBasicInfo(
              name: _nameController.text,
              rif: _idController.text, // Mapping ID to RIF for company
              alias: _aliasController.text,
            );
        context.push('/clients/add/address');
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(color: colors.primary, height: 4),
              ),
              Expanded(
                flex: 3,
                child: Container(color: colors.secondaryContainer, height: 4),
              ),
            ],
          ),
        ),
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
                        '¿Cuáles son los datos fiscales de la empresa?',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.normal,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Name / Reason Social
                      CustomTextField(
                        label: 'Nombre o razón social*',
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tax ID (RIF)
                      CustomTextField(
                        label: 'RIF/NIF/RUT* (Identificación Tributaria)',
                        controller: _idController,
                        validator: (value) {
                          if (_rifError != null) return _rifError;
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Alias
                      CustomTextField(
                        label: 'Nombre corto o alias',
                        controller: _aliasController,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 56),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      context.go('/clients');
                    },
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Atrás',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120, // Check width constraint
                    child: CustomButton(
                      text: 'Siguiente',
                      onPressed: _onNext,
                      isLoading: _isLoading,
                      type: ButtonType.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
