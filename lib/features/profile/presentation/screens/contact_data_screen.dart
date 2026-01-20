import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_dropdown.dart';
import '../../../../shared/widgets/form_bottom_bar.dart';

class ContactDataScreen extends ConsumerStatefulWidget {
  const ContactDataScreen({super.key});

  @override
  ConsumerState<ContactDataScreen> createState() => _ContactDataScreenState();
}

class _ContactDataScreenState extends ConsumerState<ContactDataScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _emailController;
  late TextEditingController _primaryPhoneController;
  late TextEditingController _altPhoneController;
  final TextEditingController _verificationCodeController =
      TextEditingController();

  // State
  String _selectedPrimaryCode = '0412';
  String _selectedAltCode = '0424';
  // bool _isVerificationSent = false;
  bool _isLoading = false;
  bool _initialDataLoaded = false;

  final List<String> _phoneCodes = ['0412', '0414', '0424', '0416', '0426'];

  // Initial State for change detection
  String _initialPrimaryPhone = '';
  String _initialAltPhone = '';

  bool get _hasChanges {
    final currentPrimary =
        '$_selectedPrimaryCode${_primaryPhoneController.text}';
    final currentAlt = _altPhoneController.text.isNotEmpty
        ? '$_selectedAltCode${_altPhoneController.text}'
        : '';

    // Normalize initial (handle empty/null)
    final safeInitialPrimary = _initialPrimaryPhone;
    final safeInitialAlt = _initialAltPhone;

    return currentPrimary != safeInitialPrimary || currentAlt != safeInitialAlt;
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _primaryPhoneController = TextEditingController()
      ..addListener(_onFieldChanged);
    _altPhoneController = TextEditingController()..addListener(_onFieldChanged);

    // Load email directly from Auth as it's not in profile table usually or read-only
    final user = Supabase.instance.client.auth.currentUser;
    _emailController.text = user?.email ?? '';
  }

  void _onFieldChanged() {
    setState(() {
      // triggers UI update for button state
    });
  }

  UserProfile? _lastLoadedProfile;

  void _populateData(UserProfile profile) {
    if (_lastLoadedProfile == profile && _initialDataLoaded) return;
    _lastLoadedProfile = profile;

    // Helper to parse phone
    void parsePhone(
      String? fullPhone,
      Function(String code, String number) onParsed,
    ) {
      if (fullPhone == null || fullPhone.isEmpty) return;
      for (final code in _phoneCodes) {
        if (fullPhone.startsWith(code)) {
          onParsed(code, fullPhone.substring(code.length));
          return;
        }
      }
    }

    // Determine new values
    String newPrimaryCode = '0412';
    String newPrimaryNumber = '';
    if (profile.phone != null) {
      parsePhone(profile.phone, (code, number) {
        newPrimaryCode = code;
        newPrimaryNumber = number;
      });
    }

    String newAltCode = '0424';
    String newAltNumber = '';
    if (profile.secondaryPhone != null) {
      parsePhone(profile.secondaryPhone, (code, number) {
        newAltCode = code;
        newAltNumber = number;
      });
    }

    // Update Primary if pristine
    // Valid if current text matches initial (old) text OR if first load
    if (!_initialDataLoaded ||
        _primaryPhoneController.text ==
            (_initialPrimaryPhone.length > 4
                ? _initialPrimaryPhone.substring(4)
                : '')) {
      // Note: checking against substring is tricky because initial is full phone.
      // Simplified check: if user hasn't typed anything yet, or if we trust the update.
      // Given the user feedback, they want the DB value to overwrite if they come back.
      _selectedPrimaryCode = newPrimaryCode;
      _primaryPhoneController.text = newPrimaryNumber;
    }

    // Better Logic: Just update initial values to current profile.
    // If the screen was just built/rebuilt and we have fresh data, we should probably show it
    // unless the user is actively typing.
    // Since this is a "view/edit" screen, and typically you land here to see data:
    // We should strictly sync to profile if the Form is "clean" or if we are reloading.
    // Given the specific bug "go back and enter again", we should force update.

    _primaryPhoneController.text = newPrimaryNumber;
    _selectedPrimaryCode = newPrimaryCode;

    _altPhoneController.text = newAltNumber;
    _selectedAltCode = newAltCode;

    _initialPrimaryPhone = profile.phone ?? '';
    _initialAltPhone = profile.secondaryPhone ?? '';

    _initialDataLoaded = true;
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _primaryPhoneController.dispose();
    _altPhoneController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _save(String userId, UserProfile currentProfile) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final primaryPhone =
          '$_selectedPrimaryCode${_primaryPhoneController.text}';
      final altPhone = _altPhoneController.text.isNotEmpty
          ? '$_selectedAltCode${_altPhoneController.text}'
          : null;

      final updatedProfile = currentProfile.copyWith(
        phone: primaryPhone,
        secondaryPhone: altPhone, // Assuming secondaryPhone maps to this
      );

      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      ref.invalidate(userProfileProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos de contacto actualizados')),
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
          'Datos de contacto',
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
                          'Tus datos de contacto son:',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email Field (Read Only)
                        CustomTextField(
                          controller: _emailController,
                          label: 'Correo electrónico*',
                          enabled: false, // Visually disabled
                        ),
                        const SizedBox(height: 32),

                        // Primary Phone Section
                        Text(
                          'Teléfono principal',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Code Dropdown
                            SizedBox(
                              width: 100,
                              child: CustomDropdown<String>(
                                label: 'Código',
                                value: _selectedPrimaryCode,
                                items: _phoneCodes,
                                itemLabelBuilder: (item) => item,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedPrimaryCode = val!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Phone Number
                            Expanded(
                              child: CustomTextField(
                                controller: _primaryPhoneController,
                                label: 'Teléfono*',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),

                        /*const SizedBox(height: 16),

                        // Verification temporarily disabled
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isVerificationSent = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF325983),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Enviar código de verificación',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        if (_isVerificationSent) ...[
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _verificationCodeController,
                            label: 'Introduce el código',
                            suffixIcon: const Icon(
                              Icons.cancel_outlined,
                            ), // Close/Clear icon
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  // Resend logic
                                },
                                child: Text(
                                  'Reenviar código',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: null, // Disabled initially
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.grey.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text('Verificar'),
                              ),
                            ],
                          ),
                        ],
                        */
                        const SizedBox(height: 32),

                        // Alternative Phone Section
                        Text(
                          'Teléfono alternativo',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Code Dropdown
                            SizedBox(
                              width: 100,
                              child: CustomDropdown<String>(
                                label: 'Código',
                                value: _selectedAltCode,
                                items: _phoneCodes,
                                itemLabelBuilder: (item) => item,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedAltCode = val!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Phone Number
                            Expanded(
                              child: CustomTextField(
                                controller: _altPhoneController,
                                label: 'Teléfono (Opcional)',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
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
