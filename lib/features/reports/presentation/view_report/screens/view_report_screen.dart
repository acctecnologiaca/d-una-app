import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/friendly_error_widget.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../../shared/utils/string_utils.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../../../core/pdf/templates/service_report_pdf_template.dart';
import '../../reports_list/providers/reports_provider.dart';
import '../providers/view_report_provider.dart';
import '../../../data/models/models.dart';
import '../tabs/view_report_details_tab.dart';
import '../tabs/view_report_client_tab.dart';
import '../tabs/view_report_services_tab.dart';
import '../tabs/view_report_products_tab.dart';
import '../tabs/view_report_conditions_tab.dart';
import '../tabs/view_report_summary_tab.dart';
import '../widgets/send_report_email_sheet.dart';
import '../widgets/send_report_whatsapp_sheet.dart';
import 'package:intl/intl.dart';

class ViewReportScreen extends ConsumerStatefulWidget {
  final String reportId;
  final bool triggerSend;

  const ViewReportScreen({
    super.key,
    required this.reportId,
    this.triggerSend = false,
  });

  @override
  ConsumerState<ViewReportScreen> createState() => _ViewReportScreenState();
}

class _ViewReportScreenState extends ConsumerState<ViewReportScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  bool _hasTriggeredSend = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 6 pestañas, empezando en Resumen (índice 5) igual que en cotizaciones
    _tabController = TabController(length: 6, vsync: this, initialIndex: 5);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(viewReportProvider(widget.reportId));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reportAsync = ref.watch(viewReportProvider(widget.reportId));

    return reportAsync.when(
      loading: () => Scaffold(
        appBar: const StandardAppBar(title: 'Reporte de Servicio'),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: const StandardAppBar(title: 'Reporte de Servicio'),
        body: FriendlyErrorWidget(
          error: err,
          onRetry: () => ref.invalidate(viewReportProvider(widget.reportId)),
        ),
      ),
      data: (report) {
        final status = ServiceReportStatus.fromDbValue(report.status);
        final isSentOrResent =
            status == ServiceReportStatus.sent ||
            status == ServiceReportStatus.resent ||
            status == ServiceReportStatus.opened;

        final isSendDisabled =
            status == ServiceReportStatus.finalized ||
            status == ServiceReportStatus.cancelled;

        if (widget.triggerSend && !_hasTriggeredSend && !isSendDisabled) {
          _hasTriggeredSend = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showSendOptions(context, report, isSentOrResent);
            }
          });
        }

        return Scaffold(
          appBar: StandardAppBar(
            title: 'Reporte de Servicio',
            subtitle: report.clientName != null
                ? '${report.reportNumber ?? "RS-..."} (${report.clientName})'
                : (report.reportNumber ?? 'Cargando...'),
            actions: [
              IconButton(
                onPressed: isSendDisabled
                    ? null
                    : () => _showSendOptions(context, report, isSentOrResent),
                icon: Icon(
                  isSentOrResent ? Symbols.forward : Icons.send,
                  color: isSendDisabled
                      ? colors.outline
                      : colors.onSurfaceVariant,
                ),
                tooltip: isSendDisabled
                    ? 'Reporte ${status.label.toLowerCase()}. No se puede enviar'
                    : (isSentOrResent ? 'Reenviar' : 'Enviar'),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
                onPressed: () => _showActionsSheet(context, ref, report),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurfaceVariant,
              indicatorColor: colors.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Reporte'),
                Tab(text: 'Productos'),
                Tab(text: 'Servicios'),
                Tab(text: 'Cliente'),
                Tab(text: 'Condiciones'),
                Tab(text: 'Resumen'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              ViewReportDetailsTab(reportId: widget.reportId),
              ViewReportProductsTab(reportId: widget.reportId),
              ViewReportServicesTab(reportId: widget.reportId),
              ViewReportClientTab(reportId: widget.reportId),
              ViewReportConditionsTab(reportId: widget.reportId),
              ViewReportSummaryTab(
                reportId: widget.reportId,
                onNavigateToTab: (index) => _tabController.animateTo(index),
              ),
            ],
          ),
          floatingActionButton: status == ServiceReportStatus.finalized
              ? null
              : Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: FloatingActionButton(
                    onPressed: () async {
                      await context.push(
                        '/reports/${widget.reportId}/edit?tab=${_tabController.index}',
                      );
                      ref.invalidate(viewReportProvider(widget.reportId));
                    },
                    child: const Icon(Icons.edit_outlined),
                  ),
                ),
        );
      },
    );
  }

  void _showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    ServiceReport report,
  ) {
    final isFinalized = report.status == ServiceReportStatus.finalized.dbValue;

    CustomActionSheet.show(
      context: context,
      title: 'Opciones',
      actions: [
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

            context.push(
              '/pdf-preview',
              extra: {
                'title': 'Previsualizar Reporte de Servicio',
                'subtitle':
                    '${report.reportNumber} (${report.clientName ?? ""})',
                'fileName': StringUtils.sanitizeForFileName(
                  '${report.serviceDate.toIso8601String().substring(0, 10)}_${report.clientName ?? ""}_${report.reportNumber ?? report.id}.pdf',
                ),
                'buildPdf': (PdfPageFormat format) => ServiceReportPdfTemplate(
                  report: report,
                  products: report.products ?? [],
                  services: report.services ?? [],
                  conditions: report.conditions ?? [],
                  userProfile: userProfile,
                  userEmail: userEmail,
                ).generate(format),
              },
            );
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
          onTap: () async {
            context.pop();
            final currentEnum = ServiceReportStatus.fromDbValue(report.status);
            final selectedStatus = await _showStatusDialog(currentEnum);

            if (selectedStatus != null && selectedStatus != currentEnum) {
              try {
                await ref
                    .read(reportsListProvider.notifier)
                    .updateReportStatus(
                      widget.reportId,
                      selectedStatus.dbValue,
                    );
                ref.invalidate(viewReportProvider(widget.reportId));
                refreshAllReportProviders(ref);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Estatus cambiado a "${selectedStatus.label}"',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al cambiar estatus: $e')),
                  );
                }
              }
            }
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: report.isArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
          label: report.isArchived ? 'Desarchivar' : 'Archivar',
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final router = GoRouter.of(context);
            context.pop();

            await ref
                .read(reportsListProvider.notifier)
                .archiveReport(widget.reportId, archive: !report.isArchived);

            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    report.isArchived
                        ? 'Reporte desarchivado exitosamente'
                        : 'Reporte archivado exitosamente',
                  ),
                ),
              );
              router.pop();
            }
          },
        ),
      ],
    );
  }

  Future<ServiceReportStatus?> _showStatusDialog(
    ServiceReportStatus currentStatus,
  ) async {
    final colors = Theme.of(context).colorScheme;

    final selectedStatus = await CustomDialog.show<ServiceReportStatus>(
      context: context,
      dialog: CustomDialog.vertical(
        icon: Symbols.conversion_path,
        title: 'Cambiar estatus',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: ServiceReportStatus.values.map((status) {
            final isSelected = status == currentStatus;
            return ListTile(
              leading: Image.asset(status.iconPath, width: 24, height: 24),
              title: Text(
                status.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colors.primary : colors.onSurface,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: colors.primary, size: 20)
                  : null,
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

    if (selectedStatus == ServiceReportStatus.finalized) {
      if (!mounted) return null;
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

      if (confirmFinalize != true) return null;
    }

    return selectedStatus;
  }

  void _showSendOptions(
    BuildContext context,
    ServiceReport report,
    bool isSentOrResent,
  ) {
    final status = ServiceReportStatus.fromDbValue(report.status);
    final isSendDisabled =
        status == ServiceReportStatus.finalized ||
        status == ServiceReportStatus.cancelled;

    if (isSendDisabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El reporte está ${status.label.toLowerCase()} y no se puede enviar.',
          ),
        ),
      );
      return;
    }

    _checkDateAndSend(
      context: context,
      report: report,
      onSend: (targetReport) {
        CustomActionSheet.show(
          context: context,
          title: isSentOrResent ? 'Reenviar reporte' : 'Enviar reporte',
          actions: [
            BottomSheetActionItem(
              icon: Icons.email_outlined,
              label: isSentOrResent
                  ? 'Reenviar por correo electrónico'
                  : 'Enviar por correo electrónico',
              onTap: () {
                Navigator.of(context).pop();
                SendReportEmailSheet.show(context, targetReport);
              },
            ),
            BottomSheetActionItem(
              icon: 'assets/icons/whatsapp_icon.png',
              label: isSentOrResent
                  ? 'Reenviar por WhatsApp'
                  : 'Enviar por WhatsApp',
              onTap: () {
                Navigator.of(context).pop();
                SendReportWhatsAppSheet.show(context, targetReport);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkDateAndSend({
    required BuildContext context,
    required ServiceReport report,
    required Function(ServiceReport report) onSend,
  }) async {
    final now = DateTime.now();
    final serviceDate = report.serviceDate;
    final isSameDate =
        serviceDate.year == now.year &&
        serviceDate.month == now.month &&
        serviceDate.day == now.day;

    if (isSameDate) {
      onSend(report);
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
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop('send_as_is'),
            child: const Text('Enviar así'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop('update_date'),
            child: const Text('Actualizar fecha y enviar'),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop('modify'),
            child: const Text('Modificar'),
          ),
        ],
      ),
    );

    if (action == 'send_as_is') {
      onSend(report);
    } else if (action == 'update_date') {
      try {
        await ref
            .read(reportsListProvider.notifier)
            .updateReportDate(report.id, DateTime.now());
        ref.invalidate(viewReportProvider(report.id));
        final updatedReport = report.copyWith(serviceDate: DateTime.now());
        onSend(updatedReport);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar fecha: $e')),
          );
        }
      }
    } else if (action == 'modify') {
      if (context.mounted) {
        await context.push('/reports/${report.id}/edit?tab=0');
        if (!context.mounted) return;
        ref.invalidate(viewReportProvider(report.id));
        final freshReport = await ref
            .read(serviceReportsRepositoryProvider)
            .getReportWithDetails(report.id);
        if (context.mounted) {
          final isSentOrResent =
              freshReport.status == ServiceReportStatus.sent.dbValue ||
              freshReport.status == ServiceReportStatus.resent.dbValue;
          _showSendOptions(context, freshReport, isSentOrResent);
        }
      }
    }
  }
}
