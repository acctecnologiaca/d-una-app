import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/send_document_email_sheet.dart';
import '../../reports_list/providers/reports_provider.dart';
import '../../../data/models/service_report.dart';
import '../../../domain/models/service_report_model.dart'
    show ServiceReportStatus;
import '../providers/view_report_provider.dart';

class SendReportEmailSheet {
  static Future<void> show(BuildContext context, ServiceReport report) {
    return SendDocumentEmailSheet.show(
      context: context,
      documentId: report.id,
      documentType: 'report',
      documentNumber: report.reportNumber,
      initialRecipient: report.contactEmail ?? report.clientEmail,
      validityDays: 30,
      sheetTitle: 'Enviar reporte por correo',
      categoryName: report.categoryName,
      tag: report.reportTag,
      advisorName: report.advisorName,
      clientDisplayName: report.contactName ?? report.clientName,
      generateToken: (ref) => ref
          .read(serviceReportsRepositoryProvider)
          .generateActionToken(report.id),
      onStatusUpdate: (ref, _) async {
        final currentStatus = report.status;
        final newStatus = (currentStatus == ServiceReportStatus.sent.dbValue ||
                currentStatus == ServiceReportStatus.resent.dbValue)
            ? ServiceReportStatus.resent.dbValue
            : ServiceReportStatus.sent.dbValue;
        await ref
            .read(serviceReportsRepositoryProvider)
            .updateReportStatus(report.id, newStatus);
      },
      onSendSuccess: () {
        final container = ProviderScope.containerOf(context, listen: false);
        container.invalidate(viewReportProvider(report.id));
        refreshAllReportProviders(container);
      },
    );
  }
}
