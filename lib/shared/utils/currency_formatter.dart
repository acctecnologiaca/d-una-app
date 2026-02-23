import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'es_VE', // Venezuela uses comma decimal, dot thousand
    symbol: '\$',
    customPattern: '\$#,##0.00',
    decimalDigits: 2,
  );

  static String format(num amount) {
    return _formatter.format(amount);
  }
}
