import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
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

  // State
  String _selectedPrimaryCode = '0412';
  String? _selectedAltCode;
  bool _isLoading = false;
  bool _initialDataLoaded = false;

  final List<String> _phoneCodes = const [
    '0412',
    '0422',
    '0414',
    '0424',
    '0416',
    '0426',
  ];

  final List<String> _altPhoneCodes = const [
    '',
    '0412',
    '0422',
    '0414',
    '0424',
    '0416',
    '0426',
  ];

  // Initial State for change detection
  String _initialPrimaryCode = '0412';
  String _initialPrimaryNumber = '';
  String? _initialAltCode;
  String _initialAltNumber = '';

  bool get _hasChanges {
    final currentPrimaryDigits = _primaryPhoneController.text.trim();
    final currentPrimary = currentPrimaryDigits.isNotEmpty
        ? '$_selectedPrimaryCode$currentPrimaryDigits'
        : '';

    final currentAltDigits = _altPhoneController.text.trim();
    final currentAlt =
        (_selectedAltCode != null &&
            _selectedAltCode!.isNotEmpty &&
            currentAltDigits.isNotEmpty)
        ? '$_selectedAltCode$currentAltDigits'
        : '';

    final initialPrimaryDigits = _initialPrimaryNumber.trim();
    final initialPrimary = initialPrimaryDigits.isNotEmpty
        ? '$_initialPrimaryCode$initialPrimaryDigits'
        : '';

    final initialAltDigits = _initialAltNumber.trim();
    final initialAlt =
        (_initialAltCode != null &&
            _initialAltCode!.isNotEmpty &&
            initialAltDigits.isNotEmpty)
        ? '$_initialAltCode$initialAltDigits'
        : '';

    return currentPrimary != initialPrimary || currentAlt != initialAlt;
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _primaryPhoneController = TextEditingController()
      ..addListener(_onFieldChanged);
    _altPhoneController = TextEditingController()..addListener(_onFieldChanged);

    final user = Supabase.instance.client.auth.currentUser;
    _emailController.text = user?.email ?? '';
  }

  void _onFieldChanged() {
    setState(() {});
  }

  (String? code, String number) _parsePhone(
    String? fullPhone, {
    bool isOptional = false,
  }) {
    if (fullPhone == null || fullPhone.trim().isEmpty) {
      return (isOptional ? null : '0412', '');
    }

    var digits = fullPhone.replaceAll(RegExp(r'\D'), '');

    // Normalize +58 / 58
    if (digits.startsWith('58') && digits.length >= 12) {
      digits = '0${digits.substring(2)}';
    } else if (digits.length == 10 && !digits.startsWith('0')) {
      digits = '0$digits';
    }

    for (final code in _phoneCodes) {
      if (digits.startsWith(code)) {
        final num = digits.substring(code.length);
        return (code, num.length > 7 ? num.substring(0, 7) : num);
      }
    }

    if (digits.length >= 4) {
      final codeCandidate = digits.substring(0, 4);
      if (_phoneCodes.contains(codeCandidate)) {
        final num = digits.substring(4);
        return (codeCandidate, num.length > 7 ? num.substring(0, 7) : num);
      }
    }

    if (isOptional && digits.isEmpty) {
      return (null, '');
    }

    return (
      isOptional ? null : '0412',
      digits.length > 7 ? digits.substring(0, 7) : digits,
    );
  }

  void _populateData(UserProfile profile) {
    if (_initialDataLoaded) return;

    final primaryParsed = _parsePhone(profile.phone, isOptional: false);
    final altParsed = _parsePhone(profile.secondaryPhone, isOptional: true);

    _selectedPrimaryCode = primaryParsed.$1 ?? '0412';
    _primaryPhoneController.text = primaryParsed.$2;

    _selectedAltCode = altParsed.$1;
    _altPhoneController.text = altParsed.$2;

    _initialPrimaryCode = primaryParsed.$1 ?? '0412';
    _initialPrimaryNumber = primaryParsed.$2;

    _initialAltCode = altParsed.$1;
    _initialAltNumber = altParsed.$2;

    _initialDataLoaded = true;
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _primaryPhoneController.dispose();
    _altPhoneController.dispose();
    super.dispose();
  }

  Future<void> _save(String userId, UserProfile currentProfile) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final primaryDigits = _primaryPhoneController.text.trim();
      final altDigits = _altPhoneController.text.trim();

      final primaryPhone = primaryDigits.isNotEmpty
          ? '$_selectedPrimaryCode$primaryDigits'
          : null;
      final altPhone =
          (altDigits.isNotEmpty &&
              _selectedAltCode != null &&
              _selectedAltCode!.isNotEmpty)
          ? '$_selectedAltCode$altDigits'
          : null;

      final updatedProfile = currentProfile.copyWith(
        phone: primaryPhone,
        secondaryPhone: altPhone,
      );

      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      ref.invalidate(userProfileProvider);

      if (mounted) {
        context.pop();
        AppToast.success(context, message: 'Datos de contacto actualizados');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Error al guardar: $e');
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
                          enabled: false,
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
                              width: 110,
                              child: CustomDropdown<String>(
                                label: 'Código',
                                value: _selectedPrimaryCode,
                                items: _phoneCodes,
                                itemLabelBuilder: (item) => item,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedPrimaryCode = val;
                                    });
                                  }
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
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(7),
                                ],
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'El teléfono es obligatorio';
                                  }
                                  if (val.trim().length != 7) {
                                    return 'Debe tener 7 dígitos';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

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
                            // Code Dropdown (Optional with blank option)
                            SizedBox(
                              width: 110,
                              child: CustomDropdown<String>(
                                label: 'Código',
                                isRequired: false,
                                value: _selectedAltCode,
                                items: _altPhoneCodes,
                                itemLabelBuilder: (item) =>
                                    item.isEmpty ? ' ' : item,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedAltCode =
                                        (val == null || val.isEmpty)
                                        ? null
                                        : val;
                                  });
                                  _formKey.currentState?.validate();
                                },
                                validator: (val) {
                                  final altDigits = _altPhoneController.text
                                      .trim();
                                  if (altDigits.isNotEmpty &&
                                      (val == null || val.isEmpty)) {
                                    return 'Requerido';
                                  }
                                  return null;
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
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(7),
                                ],
                                validator: (val) {
                                  if (val != null &&
                                      val.trim().isNotEmpty &&
                                      val.trim().length != 7) {
                                    return 'Debe tener 7 dígitos';
                                  }
                                  return null;
                                },
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
