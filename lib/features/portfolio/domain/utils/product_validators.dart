import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/shared/utils/string_similarity.dart';

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

    return StringSimilarity.findSimilar<Product>(
      products,
      model,
      (p) => p.model ?? '',
      threshold: threshold,
    );
  }
}
