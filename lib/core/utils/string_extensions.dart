extension StringExtensions on String {
  /// Normalizes the string by converting to lowercase and removing accents from vowels.
  /// Used for accent-insensitive search.
  String get normalized {
    return toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u');
  }
}
