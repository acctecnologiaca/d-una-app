import '../../../data/models/quote_item_product.dart';
import 'quote_validation_provider.dart';

/// Represents alerts for a single source type within a product group.
class QuoteSourceAlert {
  final QuoteItemSourceType sourceType;
  final Set<QuoteValidationStatus> statuses;

  const QuoteSourceAlert({
    required this.sourceType,
    required this.statuses,
  });
}
