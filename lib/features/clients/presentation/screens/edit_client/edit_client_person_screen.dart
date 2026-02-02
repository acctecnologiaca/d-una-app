import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/shared/widgets/form_bottom_bar.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';

class EditClientPersonScreen extends ConsumerStatefulWidget {
  final String clientId;
  final Client? client;

  const EditClientPersonScreen({
    super.key,
    required this.clientId,
    this.client,
  });

  @override
  ConsumerState<EditClientPersonScreen> createState() =>
      _EditClientPersonScreenState();
}

class _EditClientPersonScreenState
    extends ConsumerState<EditClientPersonScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  String? _selectedState;
  String? _selectedCity;
  String? _selectedCountry;
  String? _selectedPhoneCode;

  final List<String> _phoneCodes = ['0412', '0414', '0424', '0416'];

  bool _isSubmitting = false;
  String? _idError;
  bool _hasChanges = false;

  late String _initialName;
  late String _initialId;
  late String _initialAddress;
  late String _initialPhone;
  late String _initialEmail;
  String? _initialState;
  String? _initialCity;
  String? _initialCountry;
  String? _initialPhoneCode;

  @override
  void initState() {
    super.initState();
    final client = widget.client;

    _nameController = TextEditingController(text: client?.name ?? '');
    _idController = TextEditingController(text: client?.taxId ?? '');
    _addressController = TextEditingController(text: client?.address ?? '');
    _emailController = TextEditingController(text: client?.email ?? '');

    // Parse phone
    final phone = client?.phone ?? '';
    if (phone.length >= 11) {
      // Try to match one of the codes
      for (final code in _phoneCodes) {
        if (phone.startsWith(code)) {
          _selectedPhoneCode = code;
          _phoneController = TextEditingController(text: phone.substring(4));
          break;
        }
      }
    }

    // Fallback if no code matched or phone is short
    if (_selectedPhoneCode == null) {
      _selectedPhoneCode = _phoneCodes.first;
      _phoneController = TextEditingController(text: phone);
    }

    // Initial values storage
    _selectedCountry = client?.country ?? 'Venezuela';
    _selectedState = client?.state;
    _selectedCity = client?.city;

    _initialName = _nameController.text;
    _initialId = _idController.text;
    _initialAddress = _addressController.text;
    _initialEmail = _emailController.text;
    _initialPhone = _phoneController.text;
    _initialState = _selectedState;
    _initialCity = _selectedCity;
    _initialCountry = _selectedCountry;
    _initialPhoneCode = _selectedPhoneCode;

    // Listeners
    _nameController.addListener(_checkChanges);
    _idController.addListener(_checkChanges);
    _addressController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
    _emailController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final hasChanges =
        _nameController.text != _initialName ||
        _idController.text != _initialId ||
        _addressController.text != _initialAddress ||
        _phoneController.text != _initialPhone ||
        _emailController.text != _initialEmail ||
        _selectedState != _initialState ||
        _selectedCity != _initialCity ||
        _selectedCountry != _initialCountry ||
        _selectedPhoneCode != _initialPhoneCode;

    // Additional logging if needed
    if (_hasChanges != hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  Future<void> _onSave() async {
    setState(() => _idError = null);

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // Check for duplicate ID
      final taxId = _idController.text.trim();
      if (taxId.isNotEmpty) {
        try {
          final exists = await ref
              .read(clientsProvider.notifier)
              .checkClientExists(taxId, excludeId: widget.clientId);

          if (exists) {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
                _idError = 'Cédula/ID existente';
              });
              _formKey.currentState!.validate();
            }
            return;
          }
        } catch (e) {
          // Handle error
        }
      }

      final fullPhone =
          _selectedPhoneCode != null && _phoneController.text.isNotEmpty
          ? '$_selectedPhoneCode${_phoneController.text.replaceAll(RegExp(r'\D'), '')}'
          : _phoneController.text.replaceAll(RegExp(r'\D'), '');

      try {
        await ref.read(clientsProvider.notifier).updateClient(widget.clientId, {
          'name': _nameController.text,
          'tax_id': _idController.text,
          'address': _addressController.text,
          'phone': fullPhone,
          'email': _emailController.text,
          'city': _selectedCity,
          'state': _selectedState,
          'country': _selectedCountry,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Información actualizada exitosamente'),
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modificar cliente',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        foregroundColor: colors.onSurface,
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Información fiscal',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Nombre y apellido*',
                controller: _nameController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Cédula/DNI/CC/Pasaporte',
                controller: _idController,
                validator: (val) {
                  if (_idError != null) return _idError;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Urbanización/Calle/Edificio*',
                controller: _addressController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // CSC Picker
              CSCPickerPlus(
                layout: Layout.vertical,
                flagState: CountryFlag.DISABLE,
                countryStateLanguage: CountryStateLanguage.englishOrNative,
                cityLanguage: CityLanguage.native,
                onCountryChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                    _checkChanges();
                  });
                },
                onStateChanged: (value) {
                  setState(() {
                    _selectedState = value;
                    _checkChanges();
                  });
                },
                onCityChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                    _checkChanges();
                  });
                },
                countryFilter: const [
                  CscCountry.Argentina,
                  CscCountry.Bolivia,
                  CscCountry.Chile,
                  CscCountry.Colombia,
                  CscCountry.Costa_Rica,
                  CscCountry.Cuba,
                  CscCountry.Dominican_Republic,
                  CscCountry.Ecuador,
                  CscCountry.El_Salvador,
                  CscCountry.Guatemala,
                  CscCountry.Honduras,
                  CscCountry.Mexico,
                  CscCountry.Nicaragua,
                  CscCountry.Panama,
                  CscCountry.Paraguay,
                  CscCountry.Peru,
                  CscCountry.Puerto_Rico,
                  CscCountry.Spain,
                  CscCountry.Uruguay,
                  CscCountry.Venezuela,
                ],
                currentCountry: _selectedCountry,
                currentState: _selectedState,
                currentCity: _selectedCity,
                dropdownDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colors.surface,
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                disabledDropdownDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade400, width: 1),
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
                  height: 1.9, // Match TextFormFields height
                ),
                dropdownHeadingStyle: TextStyle(
                  color: colors.onSurfaceVariant,
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

              const SizedBox(height: 32),

              Text(
                'Datos de contacto',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Phone Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: SizedBox(
                      width: 100,
                      child: CustomDropdown<String>(
                        label: 'Código',
                        value: _selectedPhoneCode,
                        items: _phoneCodes,
                        itemLabelBuilder: (item) => item,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedPhoneCode = val;
                              _checkChanges();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Teléfono*',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        if (val.length != 7) return 'Debe tener 7 dígitos';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Correo electrónico',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) return null; // Optional
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(val)) {
                    return 'Correo inválido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 48),

              // Buttons
              FormBottomBar(
                onCancel: () => context.pop(),
                onSave: _onSave,
                isSaveEnabled: !_isSubmitting && _hasChanges,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
