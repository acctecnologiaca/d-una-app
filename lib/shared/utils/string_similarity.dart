/// Utility class for calculating string similarity using Levenshtein distance.
///
/// Can be used generically to detect duplicates or near-duplicates in any
/// list of items (brands, product models, categories, etc.).
class StringSimilarity {
  /// Calculates similarity between two strings (0.0 to 1.0).
  ///
  /// Returns 1.0 for identical strings, 0.0 for completely different strings.
  /// Comparison is case-insensitive.
  static double calculate(String s1, String s2) {
    final a = s1.toLowerCase();
    final b = s2.toLowerCase();

    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final distance = _levenshteinDistance(a, b);
    final maxLength = (a.length > b.length) ? a.length : b.length;
    return 1.0 - (distance / maxLength);
  }

  /// Finds the first similar item in a list that meets the [threshold].
  ///
  /// [items] – the list to search through.
  /// [target] – the string to compare against.
  /// [labelBuilder] – extracts the comparable string from each item.
  /// [threshold] – minimum similarity (0.0–1.0) to be considered a match.
  /// [excludeId] – optional ID to skip (useful when editing an existing item).
  /// [idBuilder] – extracts the ID from each item (used with [excludeId]).
  static T? findSimilar<T>(
    List<T> items,
    String target,
    String Function(T) labelBuilder, {
    double threshold = 0.8,
    String? excludeId,
    String Function(T)? idBuilder,
  }) {
    if (target.isEmpty) return null;

    for (final item in items) {
      final label = labelBuilder(item);
      if (label.isEmpty) continue;

      // Skip the item being edited
      if (excludeId != null && idBuilder != null) {
        if (idBuilder(item) == excludeId) continue;
      }

      final similarity = calculate(target, label);
      if (similarity >= threshold) {
        return item;
      }
    }
    return null;
  }

  // ── Private ──────────────────────────────────────────────────────────────

  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1.codeUnitAt(i) == s2.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }
}
