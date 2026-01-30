import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';
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
      context.push('/clients/add/contact?type=$type');
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

                      // CSC Picker
                      CSCPickerPlus(
                        layout: Layout.vertical,
                        flagState: CountryFlag.DISABLE,
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
                        countryFilter: const [
                          CscCountry.Venezuela,
                          CscCountry.Colombia,
                          CscCountry.Argentina,
                          CscCountry.Chile,
                          CscCountry.Ecuador,
                          CscCountry.Peru,
                          CscCountry.Panama,
                          CscCountry.Bolivia,
                          CscCountry.Costa_Rica,
                          CscCountry.Cuba,
                          CscCountry.Dominican_Republic,
                          CscCountry.El_Salvador,
                          CscCountry.Guatemala,
                          CscCountry.Honduras,
                          CscCountry.Mexico,
                          CscCountry.Nicaragua,
                          CscCountry.Paraguay,
                          CscCountry.Puerto_Rico,
                          CscCountry.Spain,
                          CscCountry.Uruguay,
                        ],
                        countryStateLanguage:
                            CountryStateLanguage.englishOrNative,
                        cityLanguage: CityLanguage.native,
                        defaultCountry: CscCountry.Venezuela,
                        currentCountry: _selectedCountry,
                        currentState: _selectedState,
                        currentCity: _selectedCity,
                        dropdownDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        disabledDropdownDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        countrySearchPlaceholder: "País",
                        stateSearchPlaceholder: "Estado",
                        citySearchPlaceholder: "Ciudad",
                        countryDropdownLabel: "País",
                        stateDropdownLabel: "Estado",
                        cityDropdownLabel: "Ciudad",
                        selectedItemStyle: TextStyle(
                          color: colors.onSurface,
                          fontSize: 16,
                          height: 1.9,
                        ),
                        dropdownHeadingStyle: TextStyle(
                          color: colors.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        dropdownItemStyle: TextStyle(
                          color: colors.onSurface,
                          fontSize: 16,
                        ),
                        searchBarRadius: 30.0,
                        dropdownDialogRadius: 8.0,
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
                onCancel: () {
                  context.go('/clients');
                },
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
