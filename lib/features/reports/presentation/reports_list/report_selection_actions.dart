import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../../shared/widgets/app_toast.dart';
import '../../../../../shared/utils/string_utils.dart';
import '../../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../../core/pdf/templates/service_report_pdf_template.dart';

import '../../domain/models/service_report_model.dart';
import '../create_report/providers/create_report_provider.dart';
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
    final isCancelled = report.status == ServiceReportStatus.cancelled;
    final isSentOrResent =
        report.status == ServiceReportStatus.sent ||
        report.status == ServiceReportStatus.resent ||
        report.status == ServiceReportStatus.opened;

    CustomActionSheet.show(
      context: context,
      title: '${report.reportNumber} (${report.clientName})',
      actions: [
        BottomSheetActionItem(
          icon: Icons.edit_outlined,
          label: 'Modificar',
          enabled: !isFinalized && !isCancelled,
          subtitle: isFinalized
              ? 'Reporte finalizado. No se puede editar'
              : (isCancelled ? 'Reporte cancelado. No se puede editar' : null),
          onTap: () {
            context.pop();
            ref.read(reportSelectionProvider.notifier).clear();
            context.push('/reports/${report.id}/edit');
          },
        ),
        BottomSheetActionItem(
          icon: isSentOrResent ? Symbols.forward : Icons.send,
          label: isSentOrResent ? 'Reenviar' : 'Enviar',
          enabled: !isFinalized && !isCancelled,
          subtitle: isFinalized
              ? 'Reporte finalizado. No se puede enviar'
              : (isCancelled ? 'Reporte cancelado. No se puede enviar' : null),
          onTap: () {
            context.pop();
            _checkDateAndSendFromSelection(context, ref, report);
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
              AppToast.info(
                context,
                message: 'Cargando perfil de usuario... Por favor espere.',
              );
              return;
            }

            AppToast.info(
              context,
              message: 'Preparando documento...',
              duration: const Duration(seconds: 1),
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
                AppToast.error(
                  context,
                  message: 'Error al cargar detalles del reporte: $e',
                );
              }
            }
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus',
          enabled: !isCancelled,
          subtitle: isCancelled
              ? 'Reporte cancelado. No se puede cambiar de estado'
              : null,
          onTap: () {
            context.pop();
            handleBatchStatusChange(
              context,
              ref,
              selection,
              currentStatus: report.status,
            );
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Icons.content_copy_outlined,
          label: 'Crear una copia',
          onTap: () async {
            context.pop();
            await ref
                .read(createReportProvider.notifier)
                .loadReportAsCopy(report.id);
            if (context.mounted) {
              ref.read(reportSelectionProvider.notifier).clear();
              context.push('/reports/create');
            }
          },
        ),
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
            handleBatchStatusChange(context, ref, selection);
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

  static Future<ServiceReportStatus?> showStatusDialog(
    BuildContext context, [
    ServiceReportStatus? currentStatus,
  ]) async {
    final colors = Theme.of(context).colorScheme;
    final isFinalized = currentStatus == ServiceReportStatus.finalized;
    final isCancelled = currentStatus == ServiceReportStatus.cancelled;

    final selectedStatus = await CustomDialog.show<ServiceReportStatus>(
      context: context,
      dialog: CustomDialog.vertical(
        icon: Symbols.conversion_path,
        title: 'Cambiar estatus',
        contentWidget: Builder(
          builder: (dialogContext) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: ServiceReportStatus.values
                  .where(
                    (status) =>
                        status != ServiceReportStatus.draft &&
                        status != ServiceReportStatus.opened &&
                        status != ServiceReportStatus.resent,
                  )
                  .map((status) {
                    final isSelected =
                        currentStatus != null && status == currentStatus;
                    bool isEnabled = true;
                    String? subtitle;
                    Color? subtitleColor;

                    if (isCancelled) {
                      isEnabled = false;
                      subtitle =
                          'El reporte cancelado no puede cambiar de estatus';
                    } else if (isFinalized) {
                      if (status == ServiceReportStatus.sent) {
                        isEnabled = false;
                        subtitle = 'Al enviarse no cambia de estatus';
                      } else if (status == ServiceReportStatus.finalized) {
                        isEnabled = false;
                        subtitle = 'Estatus actual';
                      } else if (status == ServiceReportStatus.cancelled) {
                        isEnabled = true;
                        subtitle = 'Cancelar reporte y reponer inventario';
                        subtitleColor = colors.primary;
                      }
                    } else {
                      if (isSelected) {
                        isEnabled = false;
                        subtitle = 'Estatus actual';
                      }
                    }

                    return ListTile(
                      leading: Opacity(
                        opacity: (isEnabled || isSelected) ? 1.0 : 0.4,
                        child: Image.asset(
                          status.iconPath,
                          width: 24,
                          height: 24,
                        ),
                      ),
                      title: Text(
                        status.label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? colors.primary
                              : (!isEnabled
                                    ? colors.onSurfaceVariant.withValues(
                                        alpha: 0.4,
                                      )
                                    : colors.onSurface),
                        ),
                      ),
                      subtitle: subtitle != null
                          ? Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    subtitleColor ??
                                    (isSelected
                                        ? colors.primary.withValues(alpha: 0.8)
                                        : colors.outline),
                              ),
                            )
                          : null,
                      trailing: isSelected
                          ? Icon(Icons.check, color: colors.primary, size: 20)
                          : null,
                      onTap: isEnabled
                          ? () => Navigator.of(dialogContext).pop(status)
                          : null,
                    );
                  })
                  .toList(),
            );
          },
        ),
        actions: [
          Builder(
            builder: (dialogContext) => TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );

    if (selectedStatus == null) return null;

    if (selectedStatus == ServiceReportStatus.finalized) {
      if (!context.mounted) return null;
      final confirmFinalize = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.confirmation(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.amber.shade800,
          title: 'Finalizar Reporte',
          contentText:
              '¿Estás seguro de que deseas finalizar este reporte? Los productos y repuestos propios consumidos se descontarán permanentemente del inventario físico. Una vez finalizado, el reporte quedará cerrado y solo podrá ser cancelado posteriormente.',
          actions: [
            Builder(
              builder: (c) => TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: const Text('Cancelar'),
              ),
            ),
            Builder(
              builder: (c) => FilledButton(
                onPressed: () => Navigator.of(c).pop(true),
                child: const Text('Finalizar'),
              ),
            ),
          ],
        ),
      );

      if (confirmFinalize != true) return null;
    }

    if (currentStatus == ServiceReportStatus.finalized &&
        selectedStatus == ServiceReportStatus.cancelled) {
      if (!context.mounted) return null;
      final confirmCancel = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.confirmation(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.amber.shade800,
          title: 'Cancelar Reporte Finalizado',
          contentText:
              '¿Estás seguro de que deseas cancelar este reporte finalizado? Esta acción registrará la cancelación del reporte de servicio y repondrá los productos utilizados al stock disponible de inventario.',
          actions: [
            Builder(
              builder: (c) => TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: const Text('Volver'),
              ),
            ),
            Builder(
              builder: (c) => FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(c).colorScheme.error,
                ),
                onPressed: () => Navigator.of(c).pop(true),
                child: const Text('Confirmar Cancelación'),
              ),
            ),
          ],
        ),
      );

      if (confirmCancel != true) return null;
    }

    return selectedStatus;
  }

  static Future<void> handleBatchStatusChange(
    BuildContext context,
    WidgetRef ref,
    ReportSelectionState selection, {
    ServiceReportStatus? currentStatus,
  }) async {
    final selectedStatus = await showStatusDialog(context, currentStatus);
    if (!context.mounted || selectedStatus == null) return;

    final result = await ref
        .read(reportsListProvider.notifier)
        .batchUpdateStatus(
          selection.selectedIds.toList(),
          selectedStatus.dbValue,
        );

    ref.read(reportSelectionProvider.notifier).clear();
    refreshAllReportProviders(ref);

    if (!context.mounted) return;

    if (result.hasErrors) {
      if (result.stockErrors.isNotEmpty) {
        final errorMessages = <String>[];
        for (final entry in result.stockErrors.entries) {
          errorMessages.add('• ${entry.value.productNames.join(', ')}');
        }

        CustomDialog.show(
          context: context,
          dialog: CustomDialog.confirmation(
            icon: Symbols.warning,
            iconColor: Colors.amber.shade800,
            title: 'Stock Insuficiente en Reportes',
            contentText:
                'No se pudieron finalizar ${result.stockErrors.length} reporte(s) porque no hay suficiente stock disponible en el inventario propio de los siguientes productos:\n\n${errorMessages.toSet().join('\n')}\n\nPor favor, reponga el stock en almacén para poder finalizarlos.',
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } else if (result.generalErrors.isNotEmpty) {
        AppToast.error(
          context,
          message: 'Ocurrieron errores al actualizar algunos reportes.',
        );
      }
    }

    if (result.successfulIds.isNotEmpty) {
      AppToast.success(
        context,
        message:
            'Estatus cambiado a "${selectedStatus.label}" en ${result.successfulIds.length} reporte${result.successfulIds.length > 1 ? 's' : ''}.',
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
      AppToast.success(
        context,
        message:
            '${selection.count} reporte${selection.count > 1 ? 's' : ''} ${selection.count > 1 ? statusWordPlural : statusWord}',
      );
    }
  }

  static Future<void> _checkDateAndSendFromSelection(
    BuildContext context,
    WidgetRef ref,
    ServiceReportSummary report,
  ) async {
    if (report.status == ServiceReportStatus.finalized ||
        report.status == ServiceReportStatus.cancelled) {
      AppToast.warning(
        context,
        message: report.status == ServiceReportStatus.finalized
            ? 'El reporte está finalizado y no se puede enviar.'
            : 'El reporte está cancelado y no se puede enviar.',
      );
      return;
    }

    final now = DateTime.now();
    final serviceDate = report.date;
    final isSameDate =
        serviceDate.year == now.year &&
        serviceDate.month == now.month &&
        serviceDate.day == now.day;

    void onProceedSend(ServiceReportSummary targetReport) {
      ref.read(reportSelectionProvider.notifier).clear();
      context.push('/reports/${targetReport.id}', extra: {'triggerSend': true});
    }

    if (isSameDate) {
      onProceedSend(report);
      return;
    }

    final formattedReportDate = DateFormat('dd/MM/yyyy').format(serviceDate);
    final formattedToday = DateFormat('dd/MM/yyyy').format(now);

    final action = await CustomDialog.show<String>(
      context: context,
      dialog: CustomDialog.confirmation(
        icon: Icons.date_range_outlined,
        title: 'Fecha de servicio diferente',
        contentText:
            'La fecha de este reporte ($formattedReportDate) es distinta a la fecha de hoy ($formattedToday). ¿Cómo deseas proceder?',
        actions: [
          Builder(
            builder: (c) => TextButton(
              onPressed: () => Navigator.of(c).pop('send_as_is'),
              child: const Text('Enviar así'),
            ),
          ),
          Builder(
            builder: (c) => FilledButton(
              onPressed: () => Navigator.of(c).pop('update_date'),
              child: const Text('Actualizar fecha y enviar'),
            ),
          ),
          Builder(
            builder: (c) => OutlinedButton(
              onPressed: () => Navigator.of(c).pop('modify'),
              child: const Text('Modificar'),
            ),
          ),
        ],
      ),
    );

    if (action == 'send_as_is') {
      onProceedSend(report);
    } else if (action == 'update_date') {
      try {
        await ref
            .read(reportsListProvider.notifier)
            .updateReportDate(report.id, DateTime.now());
        ref.invalidate(reportsListProvider);
        refreshAllReportProviders(ref);
        onProceedSend(report);
      } catch (e) {
        if (context.mounted) {
          AppToast.error(context, message: 'Error al actualizar fecha: $e');
        }
      }
    } else if (action == 'modify') {
      if (context.mounted) {
        ref.read(reportSelectionProvider.notifier).clear();
        await context.push('/reports/${report.id}/edit?tab=0');
        ref.invalidate(reportsListProvider);
        refreshAllReportProviders(ref);
      }
    }
  }
}
