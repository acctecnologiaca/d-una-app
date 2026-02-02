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

  /// Converts the string to Title Case (e.g. "hello world" -> "Hello World").
  /// Keeps common Spanish prepositions/conjunctions lowercase unless they are the first word.
  String get toTitleCase {
    if (isEmpty) return this;

    final exceptions = {
      'de',
      'del',
      'la',
      'las',
      'el',
      'los',
      'y',
      'e',
      'o',
      'u',
      'en',
      'por',
      'para',
      'con',
      'sin',
      'a',
      'al',
      'un',
      'una',
    };

    final words = split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      final lowerWord = word.toLowerCase();

      // Capitalize if it's the first word or not an exception
      if (i == 0 || !exceptions.contains(lowerWord)) {
        words[i] = lowerWord[0].toUpperCase() + lowerWord.substring(1);
      } else {
        words[i] = lowerWord;
      }
    }

    return words.join(' ');
  }
}
