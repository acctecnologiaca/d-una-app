import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/custom_location_picker.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
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
  String? _initialCountry = 'Venezuela';
  String? _initialState;
  String? _initialCity;

  bool get _hasChanges {
    final countryChanged =
        (_selectedCountry ?? 'Venezuela') != (_initialCountry ?? 'Venezuela');
    final stateChanged = (_selectedState ?? '') != (_initialState ?? '');
    final cityChanged = (_selectedCity ?? '') != (_initialCity ?? '');
    final addressChanged =
        _addressController.text.trim() != _initialAddress.trim();

    return countryChanged || stateChanged || cityChanged || addressChanged;
  }

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController()..addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  void _populateData(UserProfile profile) {
    if (_initialDataLoaded) return;

    final newAddress = profile.mainAddress ?? '';
    final newCountry = profile.mainCountry ?? 'Venezuela';
    final newState = profile.mainState;
    final newCity = profile.mainCity;

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
      AppToast.warning(
        context,
        message: 'Por favor complete la selección de ubicación',
      );
      return;
    }

    final colors = Theme.of(context).colorScheme;
    final isVerified = currentProfile.verificationStatus == 'verified';

    if (isVerified) {
      final confirmed = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.destructive(
          title: 'Modificar dirección principal',
          contentText:
              'Al modificar tu dirección principal, perderás tu estado de verificación actual y pasarás a "No verificado". ¿Deseas continuar?',
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedProfile = currentProfile.copyWith(
        mainAddress: _addressController.text.trim(),
        mainCountry: _selectedCountry,
        mainState: _selectedState,
        mainCity: _selectedCity,
        verificationStatus:
            isVerified ? 'unverified' : currentProfile.verificationStatus,
      );

      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      ref.invalidate(userProfileProvider);

      if (mounted) {
        context.pop();
        AppToast.success(
          context,
          message: 'Dirección actualizada correctamente',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          message: 'Error al guardar: $e',
        );
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
              error: (error, stack) => FriendlyErrorWidget(error: error),
              data: (profile) {
                if (profile != null && !_initialDataLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _populateData(profile);
                    }
                  });
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
                          controller: _addressController,
                          label: 'Urbanización/Calle/Edificio*',
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Este campo es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Location Picker (Country, State, City)
                        CustomLocationPicker(
                          selectedCountry: _selectedCountry ?? 'Venezuela',
                          selectedState: _selectedState,
                          selectedCity: _selectedCity,
                          isRequired: true,
                          onCountryChanged: (value) {
                            setState(() {
                              _selectedCountry = value;
                              _selectedState = null;
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
