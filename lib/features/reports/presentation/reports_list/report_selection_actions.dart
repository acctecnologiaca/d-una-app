import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../../shared/utils/string_utils.dart';
import '../../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../../core/pdf/templates/service_report_pdf_template.dart';

import '../../domain/models/service_report_model.dart';
import 'providers/reports_provider.dart';

/// Shared action methods for report multi-selection, used in both
/// ReportsListScreen and ReportsSearchScreen.
class ReportSelectionActions {
  ReportSelectionActions._();

  static void showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    ReportSelectionState selection,
    List<ServiceReportSummary> allReports,
  ) {
    if (selection.isSingle) {
      final report = allReports.firstWhere(
        (r) => r.id == selection.selectedIds.first,
      );
      _showSingleActionsSheet(context, ref, selection, report);
    } else {
      _showMultiActionsSheet(context, ref, selection, allReports);
    }
  }

  static void _showSingleActionsSheet(
    BuildContext context,
    WidgetRef ref,
    ReportSelectionState selection,
    ServiceReportSummary report,
  ) {
    final isFinalized = report.status == ServiceReportStatus.finalized;

    CustomActionSheet.show(
      context: context,
      title: '${report.reportNumber} (${report.clientName})',
      actions: [
        BottomSheetActionItem(
          icon: Icons.edit_outlined,
          label: 'Modificar',
          enabled: !isFinalized,
          subtitle: isFinalized
              ? 'Reporte finalizado. No se puede editar'
              : null,
          onTap: () {
            context.pop();
            ref.read(reportSelectionProvider.notifier).clear();
            context.push('/reports/${report.id}/edit');
          },
        ),
        BottomSheetActionItem(
          icon: Icons.picture_as_pdf_outlined,
          label: 'Descargar PDF',
          onTap: () async {
            context.pop();

            final userProfile = ref.read(userProfileProvider).value;
            final userEmail = Supabase.instance.client.auth.currentUser?.email;

            if (userProfile == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Cargando perfil de usuario... Por favor espere.',
                  ),
                ),
              );
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Preparando documento...'),
                duration: Duration(seconds: 1),
              ),
            );

            try {
              final fullReport = await ref
                  .read(serviceReportsRepositoryProvider)
                  .getReportWithDetails(report.id);

              if (context.mounted) {
                context.push(
                  '/pdf-preview',
                  extra: {
                    'title': 'Previsualizar Reporte de Servicio',
                    'subtitle':
                        ' ${fullReport.reportNumber} (${fullReport.clientName})',
                    'fileName': StringUtils.sanitizeForFileName(
                      '${fullReport.serviceDate.toIso8601String().substring(0, 10)}_${fullReport.clientName ?? ''}_${fullReport.reportNumber ?? fullReport.id}.pdf',
                    ),
                    'buildPdf': (PdfPageFormat format) =>
                        ServiceReportPdfTemplate(
                          report: fullReport,
                          products: fullReport.products ?? [],
                          services: fullReport.services ?? [],
                          conditions: fullReport.conditions ?? [],
                          userProfile: userProfile,
                          userEmail: userEmail,
                        ).generate(format),
                  },
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al cargar detalles del reporte: $e'),
                  ),
                );
              }
            }
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus',
          enabled: !isFinalized,
          subtitle: isFinalized
              ? 'Reporte finalizado. No se puede cambiar de estado'
              : null,
          onTap: () {
            context.pop();
            showStatusDialog(context, ref, selection);
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: report.isArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
          label: report.isArchived ? 'Desarchivar' : 'Archivar',
          onTap: () async {
            context.pop();
            await ref
                .read(reportsListProvider.notifier)
                .archiveReport(report.id, archive: !report.isArchived);
            ref.read(reportSelectionProvider.notifier).clear();
          },
        ),
      ],
    );
  }

  static void _showMultiActionsSheet(
    BuildContext context,
    WidgetRef ref,
    ReportSelectionState selection,
    List<ServiceReportSummary> allReports,
  ) {
    final selectedReports = allReports
        .where((r) => selection.selectedIds.contains(r.id))
        .toList();
    final isAllArchived =
        selectedReports.isNotEmpty &&
        selectedReports.every((r) => r.isArchived);

    CustomActionSheet.show(
      context: context,
      title: '${selection.count} seleccionados',
      actions: [
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus',
          onTap: () {
            context.pop();
            showStatusDialog(context, ref, selection);
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: isAllArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
          label: isAllArchived ? 'Desarchivar' : 'Archivar',
          onTap: () async {
            context.pop();
            handleBatchArchive(
              context,
              ref,
              selection,
              archive: !isAllArchived,
            );
          },
        ),
      ],
    );
  }

  static Future<void> showStatusDialog(
    BuildContext context,
    WidgetRef ref,
    ReportSelectionState selection,
  ) async {
    final selectedStatus = await CustomDialog.show<ServiceReportStatus>(
      context: context,
      dialog: CustomDialog.vertical(
        icon: Symbols.conversion_path,
        title: 'Cambiar estatus',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: ServiceReportStatus.values.map((status) {
            return ListTile(
              leading: Image.asset(status.iconPath, width: 24, height: 24),
              title: Text(status.label),
              onTap: () =>
                  Navigator.of(context, rootNavigator: true).pop(status),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (selectedStatus == ServiceReportStatus.finalized) {
      final confirmFinalize = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.confirmation(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.amber.shade800,
          title: 'Finalizar Reporte',
          contentText:
              '¿Estás seguro de que deseas finalizar este reporte? Una vez finalizado, el reporte quedará cerrado permanentemente y no se podrá editar, enviar ni cambiar de estado.',
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(true),
              child: const Text('Confirmar y Finalizar'),
            ),
          ],
        ),
      );

      if (confirmFinalize != true) return;
    }

    if (selectedStatus != null) {
      final successfulIds = await ref
          .read(reportsListProvider.notifier)
          .batchUpdateStatus(
            selection.selectedIds.toList(),
            selectedStatus.dbValue,
          );

      ref.read(reportSelectionProvider.notifier).clear();
      refreshAllReportProviders(ref);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estatus cambiado a "${selectedStatus.label}" en ${successfulIds.length} reporte${successfulIds.length > 1 ? 's' : ''}.',
          ),
        ),
      );
    }
  }

  static Future<void> handleBatchArchive(
    BuildContext context,
    WidgetRef ref,
    ReportSelectionState selection, {
    bool archive = true,
  }) async {
    await ref
        .read(reportsListProvider.notifier)
        .batchArchive(selection.selectedIds.toList(), archive: archive);
    ref.read(reportSelectionProvider.notifier).clear();
    refreshAllReportProviders(ref);

    if (context.mounted) {
      final statusWord = archive ? 'archivado' : 'desarchivado';
      final statusWordPlural = archive ? 'archivados' : 'desarchivados';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selection.count} reporte${selection.count > 1 ? 's' : ''} ${selection.count > 1 ? statusWordPlural : statusWord}',
          ),
        ),
      );
    }
  }
}
