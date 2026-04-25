import 'package:d_una_app/core/utils/string_extensions.dart';
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

  /// Specialized validator for preventing duplicates in own inventory.
  /// Applies the Dual Logic:
  /// 1. Specific (with model): Matches Brand + Model Fingerprint + UOM
  /// 2. Generic (NO APLICA): Matches Name Fingerprint + Brand + UOM
  static Product? findDuplicate({
    required List<Product> products,
    required String? brandId,
    required String model,
    required String? uomId,
    required String name,
  }) {
    final cleanModel = model.trim().toUpperCase();

    if (cleanModel == 'NO APLICA' || cleanModel.isEmpty) {
      // Generic Logic: (Name + Brand + UOM)
      final targetFingerprint = name.normalizeFingerprint;
      return products.where((p) {
        final isModelGeneric =
            p.model == null ||
            p.model!.isEmpty ||
            p.model!.toUpperCase() == 'NO APLICA';

        return isModelGeneric &&
            p.brandId == brandId &&
            p.uomId == uomId &&
            p.name.normalizeFingerprint == targetFingerprint;
      }).firstOrNull;
    } else {
      // Specific Logic: (Brand + Model + UOM)
      final targetFingerprint = model.normalizeFingerprint;
      return products.where((p) {
        final isModelSpecific =
            p.model != null &&
            p.model!.isNotEmpty &&
            p.model!.toUpperCase() != 'NO APLICA';

        return isModelSpecific &&
            p.brandId == brandId &&
            p.uomId == uomId &&
            p.model!.normalizeFingerprint == targetFingerprint;
      }).firstOrNull;
    }
  }
}
