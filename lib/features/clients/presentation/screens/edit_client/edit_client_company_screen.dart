import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/form_bottom_bar.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';

class EditClientCompanyScreen extends ConsumerStatefulWidget {
  final String clientId;
  final Client? client;

  const EditClientCompanyScreen({
    super.key,
    required this.clientId,
    this.client,
  });

  @override
  ConsumerState<EditClientCompanyScreen> createState() =>
      _EditClientCompanyScreenState();
}

class _EditClientCompanyScreenState
    extends ConsumerState<EditClientCompanyScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _rifController;
  late TextEditingController _addressController;
  late TextEditingController _aliasController;

  String? _selectedState;
  String? _selectedCity;
  String? _selectedCountry;

  bool _isSubmitting = false;
  String? _rifError;
  bool _hasChanges = false;

  late String _initialName;
  late String _initialRif;
  late String _initialAddress;
  late String _initialAlias;
  String? _initialState;
  String? _initialCity;
  String? _initialCountry;

  @override
  void initState() {
    super.initState();
    Client? client = widget.client;

    // Try to find the latest client data from the provider to ensure freshness
    try {
      final clientsState = ref.read(clientsProvider);
      if (clientsState.hasValue) {
        final foundClient = clientsState.value?.firstWhere(
          (c) => c.id == widget.clientId,
          orElse: () => client!,
        );
        if (foundClient != null) {
          client = foundClient;
        }
      }
    } catch (_) {
      // Fallback to widget.client if anything fails (e.g. client not found in list)
    }

    _nameController = TextEditingController(text: client?.name ?? '');
    _rifController = TextEditingController(text: client?.taxId ?? '');
    _addressController = TextEditingController(text: client?.address ?? '');
    _aliasController = TextEditingController(text: client?.alias ?? '');

    // Parse address for state/city/country if stored there, or defaults
    _selectedState = client?.state;
    _selectedCity = client?.city;
    _selectedCountry = client?.country ?? 'Venezuela';

    // Store initial values
    _initialName = _nameController.text;
    _initialRif = _rifController.text;
    _initialAddress = _addressController.text;
    _initialAlias = _aliasController.text;
    _initialState = _selectedState;
    _initialCity = _selectedCity;
    _initialCountry = _selectedCountry;

    // Listeners
    _nameController.addListener(_checkChanges);
    _rifController.addListener(_checkChanges);
    _addressController.addListener(_checkChanges);
    _aliasController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rifController.dispose();
    _addressController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final hasChanges =
        _nameController.text != _initialName ||
        _rifController.text != _initialRif ||
        _addressController.text != _initialAddress ||
        _aliasController.text != _initialAlias ||
        _selectedState != _initialState ||
        _selectedCity != _initialCity ||
        _selectedCountry != _initialCountry;

    if (_hasChanges != hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  Future<void> _onSave() async {
    setState(() => _rifError = null);

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // Check for duplicate RIF
      final rif = _rifController.text.trim();
      if (rif.isNotEmpty) {
        try {
          final exists = await ref
              .read(clientsProvider.notifier)
              .checkClientExists(rif, excludeId: widget.clientId);

          if (exists) {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
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

      try {
        await ref.read(clientsProvider.notifier).updateClient(widget.clientId, {
          'name': _nameController.text,
          'tax_id': _rifController.text,
          'address': _addressController.text,
          'city': _selectedCity,
          'state': _selectedState,
          'country': _selectedCountry,
          'alias': _aliasController.text,
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
              CustomTextField(
                label: 'Nombre o razón social*',
                controller: _nameController,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'RIF/NIF/RUT',
                controller: _rifController,
                validator: (val) {
                  if (_rifError != null) return _rifError;
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
                  color: Colors.white,
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
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Nombre corto o alias',
                controller: _aliasController,
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
