import 'package:csc_picker_plus/csc_picker_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/form_bottom_bar.dart';

class MainAddressScreen extends ConsumerStatefulWidget {
  const MainAddressScreen({super.key});

  @override
  ConsumerState<MainAddressScreen> createState() => _MainAddressScreenState();
}

class _MainAddressScreenState extends ConsumerState<MainAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _addressController;

  // State
  String? _selectedCountry = 'Venezuela';
  String? _selectedState;
  String? _selectedCity;
  bool _isLoading = false;
  bool _initialDataLoaded = false;

  // Initial State for change detection
  String _initialAddress = '';
  String? _initialCountry;
  String? _initialState;
  String? _initialCity;

  bool get _hasChanges {
    final countryChanged = _selectedCountry != _initialCountry;
    final stateChanged = _selectedState != _initialState;
    final cityChanged = _selectedCity != _initialCity;
    final addressChanged = _addressController.text != _initialAddress;

    return countryChanged || stateChanged || cityChanged || addressChanged;
  }

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController()..addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      // triggers UI update
    });
  }

  UserProfile? _lastLoadedProfile;

  void _populateData(UserProfile profile) {
    if (_lastLoadedProfile == profile && _initialDataLoaded) return;
    _lastLoadedProfile = profile;

    final newAddress = profile.mainAddress ?? '';
    final newCountry = profile.mainCountry ?? 'Venezuela';
    final newState = profile.mainState;
    final newCity = profile.mainCity;

    // Force update pristine form (simplest for this bug fix)
    _addressController.text = newAddress;
    _selectedCountry = newCountry;
    _selectedState = newState;
    _selectedCity = newCity;

    _initialAddress = newAddress;
    _initialCountry = newCountry;
    _initialState = newState;
    _initialCity = newCity;

    _initialDataLoaded = true;
    setState(() {});
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save(String userId, UserProfile currentProfile) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCountry == null ||
        _selectedState == null ||
        _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete la selección de ubicación'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedProfile = currentProfile.copyWith(
        mainAddress: _addressController.text,
        mainCountry: _selectedCountry,
        mainState: _selectedState,
        mainCity: _selectedCity,
      );

      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      ref.invalidate(userProfileProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dirección actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Dirección principal',
          style: textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (profile) {
                if (profile != null) {
                  _populateData(profile);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dirección fiscal o lugar de trabajo',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Address Line
                        CustomTextField(
                          key: ValueKey('address-${profile?.mainAddress}'),
                          controller: _addressController,
                          label: 'Urbanización/Calle/Edificio*',
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Este campo es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // CSC Picker
                        // Note: Keys are important here to prevent reset if parent rebuilds drastically,
                        // but normally Riverpod state preservation handles this.
                        // However, CSCPicker might be tricky with initial values if populated late.
                        if (_initialDataLoaded)
                          CSCPickerPlus(
                            key: ValueKey(
                              '$_selectedCountry-$_selectedState-$_selectedCity',
                            ),
                            layout: Layout.vertical,
                            flagState: CountryFlag.DISABLE,
                            onCountryChanged: (value) {
                              setState(() {
                                _selectedCountry = value;
                                _selectedState = null; // reset lower levels
                                _selectedCity = null;
                              });
                            },
                            onStateChanged: (value) {
                              setState(() {
                                _selectedState = value;
                                _selectedCity = null;
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

                            // We pass the current selected state as the "current" parameters
                            // to ensure it reflects what we loaded from DB.
                            currentCountry: _selectedCountry,
                            currentState: _selectedState,
                            currentCity: _selectedCity,

                            // Styling
                            dropdownDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: colors.surface,
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
                            countryDropdownLabel: "País*",
                            stateDropdownLabel: "Estado*",
                            cityDropdownLabel: "Ciudad*",
                            selectedItemStyle: TextStyle(
                              color: colors.onSurface,
                              fontSize: 16,
                              height: 1.5,
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

                        const SizedBox(height: 48),

                        // Actions
                        FormBottomBar(
                          onCancel: () => context.pop(),
                          onSave: _hasChanges && profile != null
                              ? () => _save(profile.id, profile)
                              : null,
                          isSaveEnabled: _hasChanges && profile != null,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
