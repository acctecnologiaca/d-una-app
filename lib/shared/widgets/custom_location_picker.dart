import 'package:flutter/material.dart';
import '../../core/services/location_service.dart';
import 'custom_dropdown.dart';

/// Reusable cascading Country -> State -> City selector widget
/// integrated with the app's standardized CustomDropdown and design system.
class CustomLocationPicker extends StatefulWidget {
  final String? selectedCountry;
  final String? selectedState;
  final String? selectedCity;
  final ValueChanged<String?>? onCountryChanged;
  final ValueChanged<String?>? onStateChanged;
  final ValueChanged<String?>? onCityChanged;
  final bool lockCountry;
  final List<String>? allowedCountries;
  final bool enabled;
  final bool isRequired;
  final String countryLabel;
  final String stateLabel;
  final String cityLabel;
  final double spacing;

  const CustomLocationPicker({
    super.key,
    this.selectedCountry = LocationService.defaultCountryName,
    this.selectedState,
    this.selectedCity,
    this.onCountryChanged,
    this.onStateChanged,
    this.onCityChanged,
    this.lockCountry = true,
    this.allowedCountries,
    this.enabled = true,
    this.isRequired = false,
    this.countryLabel = 'País',
    this.stateLabel = 'Estado',
    this.cityLabel = 'Ciudad',
    this.spacing = 16.0,
  });

  @override
  State<CustomLocationPicker> createState() => _CustomLocationPickerState();
}

class _CustomLocationPickerState extends State<CustomLocationPicker> {
  final LocationService _locationService = LocationService.instance;

  List<String> _countries = [];
  List<String> _states = [];
  List<String> _cities = [];

  String? _currentCountry;
  String? _currentState;
  String? _currentCity;

  bool _isLoadingStates = false;
  bool _isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    _currentCountry =
        widget.selectedCountry ?? LocationService.defaultCountryName;
    _currentState = widget.selectedState;
    _currentCity = widget.selectedCity;
    _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant CustomLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool shouldReloadStates = false;
    bool shouldReloadCities = false;

    if (widget.selectedCountry != oldWidget.selectedCountry &&
        widget.selectedCountry != _currentCountry) {
      _currentCountry =
          widget.selectedCountry ?? LocationService.defaultCountryName;
      shouldReloadStates = true;
    }

    if (widget.selectedState != oldWidget.selectedState &&
        widget.selectedState != _currentState) {
      _currentState = widget.selectedState;
      shouldReloadCities = true;
    }

    if (widget.selectedCity != oldWidget.selectedCity) {
      _currentCity = widget.selectedCity;
    }

    if (shouldReloadStates) {
      _loadStates();
    } else if (shouldReloadCities) {
      _loadCities();
    }
  }

  Future<void> _loadInitialData() async {
    final countries = await _locationService.getCountries(
      allowedCountries: widget.allowedCountries,
    );
    if (!mounted) return;

    setState(() {
      _countries = countries;
    });

    await _loadStates();
    if (_currentState != null && _currentState!.isNotEmpty) {
      await _loadCities();
    }
  }

  Future<void> _loadStates() async {
    final country = _currentCountry ?? LocationService.defaultCountryName;
    setState(() {
      _isLoadingStates = true;
    });

    final states = await _locationService.getStates(countryName: country);
    if (!mounted) return;

    setState(() {
      _states = states;
      _isLoadingStates = false;
      // If current state is not in the list, keep it only if list is empty or match
      if (_currentState != null && !states.contains(_currentState)) {
        // Try case-insensitive matching
        final matched = states.firstWhere(
          (s) => s.toLowerCase() == _currentState!.toLowerCase(),
          orElse: () => '',
        );
        if (matched.isNotEmpty) {
          _currentState = matched;
        }
      }
    });
  }

  Future<void> _loadCities() async {
    final state = _currentState;
    if (state == null || state.isEmpty) {
      setState(() {
        _cities = [];
      });
      return;
    }

    final country = _currentCountry ?? LocationService.defaultCountryName;
    setState(() {
      _isLoadingCities = true;
    });

    final cities = await _locationService.getCities(
      countryName: country,
      stateName: state,
    );
    if (!mounted) return;

    setState(() {
      _cities = cities;
      _isLoadingCities = false;
      if (_currentCity != null && !cities.contains(_currentCity)) {
        final matched = cities.firstWhere(
          (c) => c.toLowerCase() == _currentCity!.toLowerCase(),
          orElse: () => '',
        );
        if (matched.isNotEmpty) {
          _currentCity = matched;
        }
      }
    });
  }

  void _onCountrySelected(String? country) {
    if (country == _currentCountry) return;
    setState(() {
      _currentCountry = country;
      _currentState = null;
      _currentCity = null;
      _cities = [];
    });
    widget.onCountryChanged?.call(country);
    widget.onStateChanged?.call(null);
    widget.onCityChanged?.call(null);
    _loadStates();
  }

  void _onStateSelected(String? state) {
    if (state == _currentState) return;
    setState(() {
      _currentState = state;
      _currentCity = null;
      _cities = [];
    });
    widget.onStateChanged?.call(state);
    widget.onCityChanged?.call(null);
    _loadCities();
  }

  void _onCitySelected(String? city) {
    setState(() {
      _currentCity = city;
    });
    widget.onCityChanged?.call(city);
  }

  @override
  Widget build(BuildContext context) {
    final isCountryEditable = widget.enabled && !widget.lockCountry;
    final isStateEnabled =
        widget.enabled &&
        !_isLoadingStates &&
        (_currentCountry != null && _currentCountry!.isNotEmpty);
    final isCityEnabled =
        widget.enabled &&
        !_isLoadingCities &&
        (_currentState != null && _currentState!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Country Dropdown
        CustomDropdown<String>(
          searchable: true,
          value: _currentCountry,
          items: _countries.isNotEmpty
              ? _countries
              : [widget.selectedCountry ?? LocationService.defaultCountryName],
          label: widget.countryLabel,
          isRequired: widget.isRequired,
          enabled: isCountryEditable,
          itemLabelBuilder: (c) => c,
          onChanged: isCountryEditable ? _onCountrySelected : null,
          validator: widget.isRequired
              ? (val) => val == null || val.isEmpty ? 'Requerido' : null
              : null,
        ),
        SizedBox(height: widget.spacing),

        // State Dropdown
        CustomDropdown<String>(
          searchable: true,
          value: _currentState,
          items: _states,
          label: widget.stateLabel,
          isRequired: widget.isRequired,
          enabled: isStateEnabled,
          itemLabelBuilder: (s) => s,
          onChanged: isStateEnabled ? _onStateSelected : null,
          validator: widget.isRequired
              ? (val) => val == null || val.isEmpty ? 'Requerido' : null
              : null,
        ),
        SizedBox(height: widget.spacing),

        // City Dropdown
        CustomDropdown<String>(
          searchable: true,
          value: _currentCity,
          items: _cities,
          label: widget.cityLabel,
          isRequired: widget.isRequired,
          enabled: isCityEnabled,
          itemLabelBuilder: (c) => c,
          onChanged: isCityEnabled ? _onCitySelected : null,
          validator: widget.isRequired
              ? (val) => val == null || val.isEmpty ? 'Requerido' : null
              : null,
        ),
      ],
    );
  }
}
