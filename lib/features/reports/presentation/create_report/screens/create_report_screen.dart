import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/draft_toast.dart';
import '../../../../../shared/widgets/app_toast.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../providers/create_report_provider.dart';
import '../../view_report/providers/view_report_provider.dart';
import '../../reports_list/providers/reports_provider.dart';
import '../tabs/report_details_tab.dart';
import '../tabs/report_client_tab.dart';
import '../tabs/report_services_tab.dart';
import '../tabs/report_products_tab.dart';
import '../tabs/report_conditions_tab.dart';
import '../tabs/report_summary_tab.dart';
import '../../../domain/models/service_report_model.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  final String? reportId;
  const CreateReportScreen({super.key, this.reportId});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AppLifecycleListener _lifecycleListener;
  bool _hasInitializedTab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        ref
            .read(createReportProvider.notifier)
            .autoSaveDraft(tabIndex: _tabController.index, reportId: widget.reportId);
      }
    });

    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        ref
            .read(createReportProvider.notifier)
            .autoSaveDraft(tabIndex: _tabController.index, reportId: widget.reportId);
      },
      onInactive: () {
        ref
            .read(createReportProvider.notifier)
            .autoSaveDraft(tabIndex: _tabController.index, reportId: widget.reportId);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentState = ref.read(createReportProvider);

      if (widget.reportId != null) {
        // Modo EDICIÓN:
        // 1. Buscar si existen cambios locales no guardados para este reporte
        final draft = await ref
            .read(createReportProvider.notifier)
            .checkAndRestoreDraft(reportId: widget.reportId);

        if (draft != null && mounted) {
          setState(() {
            if (draft.tabIndex >= 0 && draft.tabIndex < 6) {
              _tabController.index = draft.tabIndex;
            }
          });

          DraftToast.show(
            context,
            message: 'Cambios restaurados automáticamente',
            onDiscard: () async {
              final shouldDiscard = await _showDiscardDialog();
              if (shouldDiscard && mounted) {
                await ref
                    .read(createReportProvider.notifier)
                    .clearDraft(reportId: widget.reportId);
                await ref
                    .read(createReportProvider.notifier)
                    .loadReport(widget.reportId!);
                setState(() {
                  _tabController.index = 0;
                });
              }
            },
          );
        } else {
          // No hay borrador local, cargar datos frescos desde DB
          ref.read(createReportProvider.notifier).loadReport(widget.reportId!);
        }
      } else {
        // Modo CREACIÓN (nuevo reporte):
        if (currentState.report != null && currentState.report!.id.isNotEmpty) {
          ref.read(createReportProvider.notifier).reset(clearPersistedDraft: false);
        }

        final draft = await ref
            .read(createReportProvider.notifier)
            .checkAndRestoreDraft();
        if (draft != null && mounted) {
          setState(() {
            if (draft.tabIndex >= 0 && draft.tabIndex < 6) {
              _tabController.index = draft.tabIndex;
            }
          });

          DraftToast.show(
            context,
            message: 'Cambios restaurados automáticamente',
            onDiscard: () async {
              final shouldDiscard = await _showDiscardDialog();
              if (shouldDiscard && mounted) {
                await ref
                    .read(createReportProvider.notifier)
                    .clearDraft();
                ref.read(createReportProvider.notifier).reset(clearPersistedDraft: true);
                ref.read(createReportProvider.notifier).initReport();
                setState(() {
                  _tabController.index = 0;
                });
              }
            },
          );
        } else {
          // Si no hay borrador previo, inicializar parámetros y valores por defecto
          if (ref.read(createReportProvider).currentReportNumber == null) {
            ref.read(createReportProvider.notifier).initReport();
          }
        }
      }

      if (widget.reportId != null &&
          currentState.report?.status ==
              ServiceReportStatus.finalized.dbValue) {
        if (mounted) {
          AppToast.error(
            context,
            message: 'El reporte está finalizado y no se puede editar.',
          );
          context.pop();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedTab && _tabController.index == 0) {
      final tabStr = GoRouterState.of(context).uri.queryParameters['tab'];
      if (tabStr != null) {
        final initialTab = int.tryParse(tabStr);
        if (initialTab != null && initialTab >= 0 && initialTab < 6) {
          _tabController.index = initialTab;
        }
      }
      _hasInitializedTab = true;
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePop() async {
    final state = ref.read(createReportProvider);
    final hasDataOrChanges = state.hasChanges;

    // Guardar inmediatamente el borrador sincrónico antes de salir
    await ref
        .read(createReportProvider.notifier)
        .saveDraftNow(tabIndex: _tabController.index, reportId: widget.reportId);
    
    // Limpiar estado en memoria sin borrar el borrador persistido en disco
    ref.read(createReportProvider.notifier).reset(clearPersistedDraft: false, reportId: widget.reportId);
    
    if (!mounted) return;

    if (hasDataOrChanges) {
      AppToast.info(
        context,
        message: 'Cambios guardados temporalmente',
        icon: Icons.bookmark_added_outlined,
      );
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createReportProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        appBar: StandardAppBar(
          title: widget.reportId != null
              ? 'Editar reporte'
              : 'Nuevo reporte de servicio',
          subtitle: state.clientName != null
              ? '${state.currentReportNumber ?? "RS-..."} (${state.clientName})'
              : (state.currentReportNumber != null
                    ? '${state.currentReportNumber}'
                    : 'Cargando...'),
          actions: [
            if (widget.reportId != null)
              IconButton(
                icon: Icon(
                  Icons.save_outlined,
                  color: state.hasChanges
                      ? colors.onSurfaceVariant
                      : colors.onSurfaceVariant.withValues(alpha: 0.38),
                ),
                tooltip: state.hasChanges
                    ? 'Guardar cambios'
                    : 'Sin modificaciones',
                onPressed: state.hasChanges
                    ? () => _handleSaveDraft(ref)
                    : null,
              ),
            IconButton(
              icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
              onPressed: () => _showActionsMenu(ref),
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
              Tab(text: 'Informe'),
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
            const ReportDetailsTab(),
            const ReportProductsTab(),
            const ReportServicesTab(),
            const ReportClientTab(),
            const ReportConditionsTab(),
            ReportSummaryTab(
              onNavigateToTab: (index) {
                _tabController.animateTo(index);
              },
            ),
          ],
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget? _buildFab() {
    final state = ref.watch(createReportProvider);

    // Botón flotante según la pestaña activa
    // 1: Productos, 2: Servicios, 4: Condiciones, 5: Resumen
    if (_tabController.index != 1 &&
        _tabController.index != 2 &&
        _tabController.index != 4 &&
        _tabController.index != 5) {
      return null;
    }

    if (_tabController.index == 5) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          label: state.isLoading ? 'Guardando...' : 'Guardar',
          icon: state.isLoading ? Icons.hourglass_empty : Icons.save_outlined,
          isEnabled: state.isReadyToFinalize && !state.isLoading,
          onPressed: () async {
            final success = await ref
                .read(createReportProvider.notifier)
                .createReport(status: ServiceReportStatus.draft.dbValue);

            if (!mounted) return;

            if (success) {
              final report = ref.read(createReportProvider).report;
              if (report != null) {
                ref.invalidate(viewReportProvider(report.id));
              }
              refreshAllReportProviders(ref);
              final savedReportNumber =
                  ref.read(createReportProvider).report?.reportNumber ?? '';
              _showPostSaveOptions(ref, savedReportNumber);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ref.read(createReportProvider).error ?? 'Error al guardar',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: CustomExtendedFab(
        onPressed: () {
          if (_tabController.index == 1) {
            context.push('/reports/create/select-product');
          } else if (_tabController.index == 2) {
            context.push('/reports/create/select-service');
          } else if (_tabController.index == 4) {
            context.push('/reports/create/select-condition');
          }
        },
        icon: Icons.add,
        label: 'Agregar',
      ),
    );
  }

  void _showPostSaveOptions(WidgetRef ref, String reportNumber) {
    final report = ref.read(createReportProvider).report;
    if (report == null) {
      context.pop();
      return;
    }

    CustomDialog.show(
      context: context,
      dialog: CustomDialog.confirmation(
        icon: Icons.check_circle_outline,
        iconColor: Theme.of(context).colorScheme.primary,
        title: 'Reporte Guardado',
        contentText:
            'El reporte $reportNumber ha sido guardado exitosamente. ¿Qué deseas hacer ahora?',
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop(); // Volver al listado
            },
            child: const Text('Ir al listado'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
              context.push('/reports/${report.id}');
            },
            child: const Text('Ver reporte'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveDraft(WidgetRef ref) async {
    final success = await ref.read(createReportProvider.notifier).saveAsDraft();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borrador guardado exitosamente')),
      );
    }
  }

  void _showActionsMenu(WidgetRef ref) {
    final state = ref.read(createReportProvider);
    final notifier = ref.read(createReportProvider.notifier);

    CustomActionSheet.show(
      context: context,
      title: 'Opciones de reporte',
      actions: [
        BottomSheetActionItem(
          icon: Icons.save_outlined,
          label: 'Guardar como borrador',
          onTap: () async {
            context.pop();
            final success = await notifier.saveAsDraft();
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Borrador guardado')),
              );
              context.pop();
            }
          },
        ),
        if (state.hasChanges)
          BottomSheetActionItem(
            icon: Icons.delete_outline,
            label: widget.reportId != null
                ? 'Descartar cambios locales'
                : 'Descartar borrador',
            onTap: () async {
              context.pop();
              final shouldDiscard = await _showDiscardDialog();
              if (!shouldDiscard) return;
              await ref
                  .read(createReportProvider.notifier)
                  .clearDraft(reportId: widget.reportId);
              ref.read(createReportProvider.notifier).reset(
                    clearPersistedDraft: true,
                    reportId: widget.reportId,
                  );
              if (!mounted) return;
              context.pop();
            },
          ),
      ],
    );
  }

  Future<bool> _showDiscardDialog() async {
    final isEditing = widget.reportId != null;
    final result = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.destructive(
        title: isEditing
            ? '¿Descartar cambios locales?'
            : '¿Descartar borrador?',
        contentText: isEditing
            ? 'Se eliminarán las modificaciones sin guardar y se recargarán los datos del servidor.'
            : 'Se eliminará el borrador guardado automáticamente y se limpiará el formulario.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
