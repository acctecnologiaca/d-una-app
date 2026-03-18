/// Hardcoded list of currencies used in Latin America, plus EUR and USD.
class Currency {
  final String code;
  final String name;
  final String symbol;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  String get displayLabel => '$name ($code) - $symbol';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

const List<Currency> availableCurrencies = [
  // South America
  Currency(code: 'USD', name: 'Estados Unidos', symbol: '\$'),
  Currency(code: 'VED', name: 'Venezuela', symbol: 'Bs.'),
  Currency(code: 'COP', name: 'Colombia', symbol: '\$'),
  Currency(code: 'ARS', name: 'Argentina', symbol: '\$'),
  Currency(code: 'CLP', name: 'Chile', symbol: '\$'),
  Currency(code: 'PEN', name: 'Perú', symbol: 'S/'),
  Currency(code: 'BRL', name: 'Brasil', symbol: 'R\$'),
  Currency(code: 'UYU', name: 'Uruguay', symbol: '\$U'),
  Currency(code: 'PYG', name: 'Paraguay', symbol: '₲'),
  Currency(code: 'BOB', name: 'Bolivia', symbol: 'Bs.'),
  Currency(code: 'GYD', name: 'Guyana', symbol: 'GY\$'),
  Currency(code: 'SRD', name: 'Surinam', symbol: 'SR\$'),
  Currency(code: 'XCD', name: 'Caribe Oriental', symbol: 'EC\$'),

  // North America & Caribbean
  Currency(code: 'MXN', name: 'México', symbol: '\$'),
  Currency(code: 'GTQ', name: 'Guatemala', symbol: 'Q'),
  Currency(code: 'BZD', name: 'Belice', symbol: 'BZ\$'),
  Currency(code: 'HNL', name: 'Honduras', symbol: 'L'),
  Currency(code: 'NIO', name: 'Nicaragua', symbol: 'C\$'),
  Currency(code: 'CRC', name: 'Costa Rica', symbol: '₡'),
  Currency(code: 'PAB', name: 'Panamá', symbol: 'B/.'),
  Currency(code: 'CUP', name: 'Cuba', symbol: '\$'),
  Currency(code: 'DOP', name: 'República Dominicana', symbol: 'RD\$'),
  Currency(code: 'HTG', name: 'Haití', symbol: 'G'),
  Currency(code: 'JMD', name: 'Jamaica', symbol: 'J\$'),
  Currency(code: 'TTD', name: 'Trinidad y Tobago', symbol: 'TT\$'),

  // Europe
  Currency(code: 'EUR', name: 'Unión Europea', symbol: '€'),
];
