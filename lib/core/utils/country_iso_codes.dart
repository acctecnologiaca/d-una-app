/// Map of country display names to ISO 3166-1 alpha-2 codes.
/// Used to build the user code portion of order numbers.
class CountryIsoCodes {
  CountryIsoCodes._();

  static const Map<String, String> _map = {
    'Venezuela': 'VE',
    'Colombia': 'CO',
    'México': 'MX',
    'Ecuador': 'EC',
    'Perú': 'PE',
    'Chile': 'CL',
    'Argentina': 'AR',
    'Brasil': 'BR',
    'Panamá': 'PA',
    'Estados Unidos': 'US',
    'España': 'ES',
    'República Dominicana': 'DO',
    'Bolivia': 'BO',
    'Paraguay': 'PY',
    'Uruguay': 'UY',
    'Costa Rica': 'CR',
    'Guatemala': 'GT',
    'Honduras': 'HN',
    'El Salvador': 'SV',
    'Nicaragua': 'NI',
    'Cuba': 'CU',
    'Puerto Rico': 'PR',
    'Trinidad y Tobago': 'TT',
  };

  /// Returns the ISO 3166-1 alpha-2 code for the given country name.
  /// Falls back to 'XX' if the country is not found.
  static String getCode(String? countryName) {
    if (countryName == null || countryName.trim().isEmpty) return 'XX';
    return _map[countryName] ?? 'XX';
  }
}
