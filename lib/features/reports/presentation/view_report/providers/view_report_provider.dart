import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../reports_list/providers/reports_provider.dart';
import '../../../data/models/service_report.dart';

final viewReportProvider =
    FutureProvider.autoDispose.family<ServiceReport, String>((ref, reportId) async {
  final repo = ref.watch(serviceReportsRepositoryProvider);
  return repo.getReportWithDetails(reportId);
});
