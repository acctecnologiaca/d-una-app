import 'package:d_una_app/features/portfolio/data/models/product_model.dart';

class ProductValidators {
  /// Checks for an exact match of the model name in the product list.
  static Product? findExactMatch(List<Product> products, String model) {
    if (model.isEmpty) return null;
    return products
        .where((p) => p.model?.toLowerCase() == model.toLowerCase())
        .firstOrNull;
  }

  /// Checks for a similar match (>= 80%) of the model name using Levenshtein distance.
  static Product? findSimilarMatch(
    List<Product> products,
    String model, {
    double threshold = 0.8,
  }) {
    if (model.isEmpty) return null;

    for (final p in products) {
      if (p.model == null || p.model!.isEmpty) continue;

      final similarity = _calculateSimilarity(
        model.toLowerCase(),
        p.model!.toLowerCase(),
      );

      if (similarity >= threshold) {
        return p;
      }
    }
    return null;
  }

  /// Calculates similarity between two strings (0.0 to 1.0) using Levenshtein distance.
  static double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLength = (s1.length > s2.length) ? s1.length : s2.length;
    return 1.0 - (distance / maxLength);
  }

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
