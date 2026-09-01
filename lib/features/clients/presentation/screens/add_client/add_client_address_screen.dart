import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/custom_location_picker.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/wizard_bottom_bar.dart';
import 'package:d_una_app/shared/widgets/wizard_progress_bar.dart';
import '../../providers/add_client_provider.dart';

class AddClientAddressScreen extends ConsumerStatefulWidget {
  const AddClientAddressScreen({super.key});

  @override
  ConsumerState<AddClientAddressScreen> createState() =>
      _AddClientAddressScreenState();
}

class _AddClientAddressScreenState
    extends ConsumerState<AddClientAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();

  bool get _isPerson =>
      GoRouterState.of(context).uri.queryParameters['type'] == 'person';

  String? get _returnTo =>
      GoRouterState.of(context).uri.queryParameters['returnTo'];

  String? _selectedState;
  String? _selectedCity;
  String? _selectedCountry;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(addClientProvider.notifier)
          .updateAddress(
            address: _addressController.text,
            city: _selectedCity,
            state: _selectedState,
            country: _selectedCountry,
          );

      final type = _isPerson ? 'person' : 'company';
      final returnToParam = _returnTo != null ? '&returnTo=$_returnTo' : '';
      context.push('/clients/add/contact?type=$type$returnToParam');
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
        bottom: const WizardProgressBar(totalSteps: 4, currentStep: 3),
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
                        _isPerson
                            ? '¿Cuál es su dirección?'
                            : '¿Cuál es la dirección de la empresa?',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.normal,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Address Line
                      CustomTextField(
                        label: 'Urbanización/Calle/Edificio',
                        controller: _addressController,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Location Picker (Country, State, City)
                      CustomLocationPicker(
                        selectedCountry: _selectedCountry ?? 'Venezuela',
                        selectedState: _selectedState,
                        selectedCity: _selectedCity,
                        onCountryChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                          });
                        },
                        onStateChanged: (value) {
                          setState(() {
                            _selectedState = value;
                          });
                        },
                        onCityChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
