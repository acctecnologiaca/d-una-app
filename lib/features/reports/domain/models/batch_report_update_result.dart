import '../repositories/service_reports_repository.dart';

class BatchReportUpdateResult {
  final List<String> successfulIds;
  final Map<String, InsufficientStockException> stockErrors;
  final Map<String, Exception> generalErrors;

  BatchReportUpdateResult({
    required this.successfulIds,
    required this.stockErrors,
    required this.generalErrors,
  });

  bool get hasErrors => stockErrors.isNotEmpty || generalErrors.isNotEmpty;
  bool get hasSuccesses => successfulIds.isNotEmpty;
}
