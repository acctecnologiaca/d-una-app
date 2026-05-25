import '../repositories/quotes_repository.dart';

class BatchUpdateResult {
  final List<String> successfulIds;
  final Map<String, InsufficientStockException> stockErrors;
  final Map<String, Exception> generalErrors;

  BatchUpdateResult({
    required this.successfulIds,
    required this.stockErrors,
    required this.generalErrors,
  });

  bool get hasErrors => stockErrors.isNotEmpty || generalErrors.isNotEmpty;
  bool get hasSuccesses => successfulIds.isNotEmpty;
}
