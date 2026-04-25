import 'string_extensions.dart';

class SearchUtils {
  /// Returns true if all tokens in [query] are found in at least one of [targetFields].
  /// Comparisons are case-insensitive and ignore accents (using .normalized).
  static bool matchesCombo(String query, List<String?> targetFields) {
    // If query is empty, it's always a match
    final queryTrimmed = query.trim();
    if (queryTrimmed.isEmpty) return true;

    // Tokenize query
    final tokens = queryTrimmed.normalized.split(' ').where((t) => t.isNotEmpty);
    if (tokens.isEmpty) return true;

    // Normalize target fields once to avoid redundant work in the inner loop
    final normalizedFields = targetFields
        .where((f) => f != null)
        .map((f) => f!.normalized)
        .toList();

    // EVERY token must match AT LEAST ONE field
    return tokens.every((token) {
      return normalizedFields.any((field) => field.contains(token));
    });
  }
}
