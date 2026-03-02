import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'es_VE', // Venezuela uses comma decimal, dot thousand
    symbol: '\$',
    customPattern: '\$#,##0.00',
    decimalDigits: 2,
  );

  static final NumberFormat _numberOnlyFormatter = NumberFormat.currency(
    locale: 'es_VE',
    symbol: '',
    customPattern: '#,##0.00',
    decimalDigits: 2,
  );

  static String format(num amount) {
    return _formatter.format(amount);
  }

  static String formatNumber(num amount) {
    return _numberOnlyFormatter.format(amount).trim();
  }

  static double? parse(String formattedString) {
    if (formattedString.isEmpty) return null;
    try {
      // Remove symbol, spaces, and thousand separators (dots in es_VE)
      String cleanString = formattedString
          .replaceAll('\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '');
      // Replace decimal comma with dot for double.parse
      cleanString = cleanString.replaceAll(',', '.');
      return double.parse(cleanString);
    } catch (e) {
      return null;
    }
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // ATM style: keep only digits, divide by 100 to get decimal
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(digitsOnly) / 100;
    String formatted = CurrencyFormatter.formatNumber(value);

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
