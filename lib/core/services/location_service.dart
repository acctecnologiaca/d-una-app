import 'package:country_state_city/country_state_city.dart' as csc;
import '../data/venezuela_locations.dart';

/// Centralized service to manage country, state, and city data offline.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  static const String defaultCountryName = 'Venezuela';
  static const String defaultCountryIso = 'VE';

  // Default allowed countries for the app (can be expanded later)
  static const List<String> defaultAllowedCountries = [defaultCountryName];

  // In-memory cache
  List<csc.Country>? _cachedAllCountries;
  final Map<String, List<csc.State>> _cachedStatesByCountry = {};
  final Map<String, List<csc.City>> _cachedCitiesByState = {};

  /// Retrieves list of country names, optionally filtered by [allowedCountries].
  Future<List<String>> getCountries({List<String>? allowedCountries}) async {
    final allowed = allowedCountries ?? defaultAllowedCountries;
    if (allowed.length == 1 && allowed.first == defaultCountryName) {
      return [defaultCountryName];
    }

    _cachedAllCountries ??= await csc.getAllCountries();
    return _cachedAllCountries!
        .where((c) => allowed.contains(c.name) || allowed.contains(c.isoCode))
        .map((c) => c.name)
        .toList()
      ..sort();
  }

  /// Retrieves list of states for a given country.
  Future<List<String>> getStates({String countryName = defaultCountryName}) async {
    if (_isVenezuela(countryName)) {
      return VenezuelaLocations.states;
    }

    final countryIso = await _resolveCountryIso(countryName);
    if (_cachedStatesByCountry.containsKey(countryIso)) {
      return _cachedStatesByCountry[countryIso]!.map((s) => s.name).toList();
    }

    final states = await csc.getStatesOfCountry(countryIso);
    _cachedStatesByCountry[countryIso] = states;
    final stateNames = states.map((s) => s.name).toList()..sort();
    return stateNames;
  }

  /// Retrieves list of cities for a given state and country.
  Future<List<String>> getCities({
    required String stateName,
    String countryName = defaultCountryName,
  }) async {
    if (stateName.trim().isEmpty) return [];

    if (_isVenezuela(countryName) || VenezuelaLocations.hasState(stateName)) {
      final cities = VenezuelaLocations.getCities(stateName);
      if (cities.isNotEmpty) return cities;
    }

    final countryIso = await _resolveCountryIso(countryName);
    final cacheKey = '$countryIso-$stateName';

    if (_cachedCitiesByState.containsKey(cacheKey)) {
      return _cachedCitiesByState[cacheKey]!.map((c) => c.name).toList();
    }

    // Ensure states for this country are loaded
    if (!_cachedStatesByCountry.containsKey(countryIso)) {
      _cachedStatesByCountry[countryIso] = await csc.getStatesOfCountry(countryIso);
    }

    final states = _cachedStatesByCountry[countryIso] ?? [];
    final stateMatches = states.where(
      (s) =>
          s.name.toLowerCase() == stateName.toLowerCase() ||
          s.isoCode.toLowerCase() == stateName.toLowerCase(),
    );

    if (stateMatches.isEmpty) return [];
    final state = stateMatches.first;

    final cities = await csc.getStateCities(countryIso, state.isoCode);
    _cachedCitiesByState[cacheKey] = cities;

    final cityNames = cities.map((c) => c.name).toSet().toList()..sort();
    return cityNames;
  }

  bool _isVenezuela(String countryName) {
    final trimmed = countryName.trim().toLowerCase();
    return trimmed.isEmpty || trimmed == 'venezuela' || trimmed == 've';
  }

  Future<String> _resolveCountryIso(String countryName) async {
    if (_isVenezuela(countryName)) {
      return defaultCountryIso;
    }

    _cachedAllCountries ??= await csc.getAllCountries();
    final countryMatches = _cachedAllCountries!.where(
      (c) =>
          c.name.toLowerCase() == countryName.toLowerCase() ||
          c.isoCode.toUpperCase() == countryName.toUpperCase(),
    );
    if (countryMatches.isEmpty) {
      return defaultCountryIso;
    }
    return countryMatches.first.isoCode;
  }
}
