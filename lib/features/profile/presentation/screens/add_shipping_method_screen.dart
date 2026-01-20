import 'package:csc_picker_plus/csc_picker_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/shipping_method.dart';
import '../../domain/models/user_profile.dart'; // Needed for main address
import '../providers/profile_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_dropdown.dart';
import '../../../../shared/widgets/form_bottom_bar.dart';

class AddShippingMethodScreen extends ConsumerStatefulWidget {
  final ShippingMethod? shippingMethod;

  const AddShippingMethodScreen({super.key, this.shippingMethod});

  @override
  ConsumerState<AddShippingMethodScreen> createState() =>
      _AddShippingMethodScreenState();
}

class _AddShippingMethodScreenState
    extends ConsumerState<AddShippingMethodScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _labelController = TextEditingController();
  final _branchCodeController = TextEditingController();
  final _addressController = TextEditingController();

  // State
  String? _selectedCompany;
  String? _selectedDeliveryOption;
  bool _isLoading = false;

  // Address State
  String? _selectedCountry = 'Venezuela';
  String? _selectedState;
  String? _selectedCity;

  // Toggles
  bool _useMainAddress = false;
  bool _isDefaultMethod = false;

  // Initial State for Change Detection
  String? _initialLabel;
  String? _initialCompany;
  String? _initialDeliveryOption;
  String? _initialBranchCode;
  String? _initialAddress;
  String? _initialCountry;
  String? _initialState;
  String? _initialCity;
  bool _initialUseMainAddress = false;
  bool _initialIsDefaultMethod = false;

  final List<String> _companies = [
    'MRW',
    'Tealca',
    'Zoom',
    'Domesa',
    'Liberty Express',
  ];
  final List<String> _deliveryOptions = [
    'Entrega a domicilio',
    'Retiro en sucursal',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.shippingMethod != null) {
      _loadData(widget.shippingMethod!);
    } else {
      _captureInitialState();
    }

    _labelController.addListener(_onFieldChanged);
    _branchCodeController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
  }

  void _captureInitialState() {
    _initialLabel = _labelController.text;
    _initialCompany = _selectedCompany;
    _initialDeliveryOption = _selectedDeliveryOption;
    _initialBranchCode = _branchCodeController.text;
    _initialAddress = _addressController.text;
    _initialCountry = _selectedCountry;
    _initialState = _selectedState;
    _initialCity = _selectedCity;
    _initialUseMainAddress = _useMainAddress;
    _initialIsDefaultMethod = _isDefaultMethod;
  }

  void _loadData(ShippingMethod method) {
    _labelController.text = method.label;
    _selectedCompany = method.company;
    _selectedDeliveryOption = method.deliveryOption;
    _branchCodeController.text = method.branchCode ?? '';
    _addressController.text = method.address ?? '';
    _selectedCountry = method.country;
    _selectedState = method.state;
    _selectedCity = method.city;
    _useMainAddress = method.useMainAddress;
    _isDefaultMethod = method.isPrimary;

    _captureInitialState();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _labelController.dispose();
    _branchCodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    if (_labelController.text != _initialLabel) return true;
    if (_selectedCompany != _initialCompany) return true;
    if (_selectedDeliveryOption != _initialDeliveryOption) return true;
    if (_branchCodeController.text != _initialBranchCode) return true;
    if (_addressController.text != _initialAddress) return true;
    if (_selectedCountry != _initialCountry) return true;
    if (_selectedState != _initialState) return true;
    if (_selectedCity != _initialCity) return true;
    if (_useMainAddress != _initialUseMainAddress) return true;
    if (_isDefaultMethod != _initialIsDefaultMethod) return true;

    return false;
  }

  void _toggleMainAddress(bool value, UserProfile? profile) {
    if (profile == null) return;
    setState(() {
      _useMainAddress = value;
      if (_useMainAddress) {
        _addressController.text = profile.mainAddress ?? '';
        _selectedCountry = profile.mainCountry;
        _selectedState = profile.mainState;
        _selectedCity = profile.mainCity;
      }
    });
  }

  Future<void> _save(String userId) async {
    if (!_formKey.currentState!.validate()) return;

    // Simple validation for dropdowns
    if (_selectedCompany == null || _selectedDeliveryOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor llena todos los campos obligatorios'),
        ),
      );
      return;
    }

    // Check Address if method is Branch or Home Delivery with custom address
    bool isBranchDelivery = _selectedDeliveryOption == 'Retiro en sucursal';
    // If branch delivery: we might assume address is of the branch, but typically branch address is looked up.
    // Assuming for now the user enters it.

    // Check address fields if relevant
    if (_addressController.text.isEmpty && !isBranchDelivery) {
      // Assuming Home Delivery needs address
      if (_selectedDeliveryOption == 'Entrega a domicilio' &&
          _addressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor ingresa la dirección de entrega'),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final method = ShippingMethod(
        id:
            widget.shippingMethod?.id ??
            '', // ID handled by DB if empty/null, but model requires non-null
        userId: userId,
        label: _labelController.text,
        company: _selectedCompany!,
        deliveryOption: _selectedDeliveryOption!,
        branchCode: _branchCodeController.text.isNotEmpty
            ? _branchCodeController.text
            : null,
        address: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
        country: _selectedCountry,
        state: _selectedState,
        city: _selectedCity,
        isPrimary: _isDefaultMethod,
        useMainAddress: _useMainAddress,
      );

      final repo = ref.read(profileRepositoryProvider);

      if (widget.shippingMethod != null) {
        await repo.updateShippingMethod(method);
      } else {
        await repo.addShippingMethod(method);
      }

      ref.invalidate(shippingMethodsProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Método de envío guardado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProfileAsync = ref.watch(userProfileProvider);

    bool isHomeDelivery = _selectedDeliveryOption == 'Entrega a domicilio';
    bool areAddressFieldsEnabled = !(isHomeDelivery && _useMainAddress);
    bool isEditMode = widget.shippingMethod != null;

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
          isEditMode ? 'Modificar método de envío' : 'Agregar método de envío',
          style: textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error al cargar perfil: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No se encontró el perfil'));
          }

          return _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label
                        CustomTextField(
                          controller: _labelController,
                          label: 'Etiqueta*',
                        ),
                        const SizedBox(height: 16),

                        // Company Dropdown
                        CustomDropdown<String>(
                          label: 'Empresa',
                          value: _selectedCompany,
                          items: _companies,
                          itemLabelBuilder: (item) => item,
                          onChanged: (val) =>
                              setState(() => _selectedCompany = val),
                        ),
                        const SizedBox(height: 16),

                        // Delivery Option Dropdown
                        CustomDropdown<String>(
                          label: 'Opciones de entrega',
                          value: _selectedDeliveryOption,
                          items: _deliveryOptions,
                          itemLabelBuilder: (item) => item,
                          onChanged: (val) {
                            setState(() {
                              _selectedDeliveryOption = val;
                              // Reset main address switch if switching modes
                              if (val != 'Entrega a domicilio') {
                                _useMainAddress = false;
                                _addressController.clear();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 32),

                        if (_selectedDeliveryOption != null) ...[
                          Text(
                            _selectedDeliveryOption == 'Entrega a domicilio'
                                ? 'Dirección del domicilio'
                                : 'Dirección de la sucursal',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_selectedDeliveryOption != null) ...[
                          if (isHomeDelivery) ...[
                            // Switch: Entregar a la dirección principal
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Entregar a la dirección principal',
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSurface,
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.9,
                                  child: Switch(
                                    value: _useMainAddress,
                                    onChanged: (val) =>
                                        _toggleMainAddress(val, profile),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            // Branch Code Input
                            CustomTextField(
                              controller: _branchCodeController,
                              label: 'Código de la sucursal',
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],

                        // Address Line
                        CustomTextField(
                          controller: _addressController,
                          label: 'Urbanización/Calle/Edificio*',
                          maxLines: 2,
                          enabled: areAddressFieldsEnabled,
                        ),
                        const SizedBox(height: 16),

                        // CSC Picker
                        IgnorePointer(
                          ignoring: !areAddressFieldsEnabled,
                          child: Opacity(
                            opacity: areAddressFieldsEnabled ? 1.0 : 0.6,
                            child: CSCPickerPlus(
                              layout: Layout.vertical,
                              flagState: CountryFlag.DISABLE,
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

                              // Pass current state to ensure persistence
                              currentState: _selectedState,
                              currentCity: _selectedCity,

                              // Styling
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
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Default Method Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Establecer como método de envío principal',
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: 0.9,
                              child: Switch(
                                value: _isDefaultMethod,
                                onChanged: (val) =>
                                    setState(() => _isDefaultMethod = val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),

                        // Actions
                        FormBottomBar(
                          onCancel: () => context.pop(),
                          onSave: _hasChanges ? () => _save(profile.id) : null,
                          isSaveEnabled: _hasChanges,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }
}
