import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _hasInitializedTab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = ref.read(createReportProvider);

      if (widget.reportId != null) {
        ref.read(createReportProvider.notifier).loadReport(widget.reportId!);
      } else {
        if (currentState.report != null) {
          ref.read(createReportProvider.notifier).reset();
        } else {
          final hasData =
              currentState.products.isNotEmpty ||
              currentState.services.isNotEmpty ||
              currentState.clientId != null;
          if (!hasData) {
            ref.read(createReportProvider.notifier).reset();
          } else if (currentState.currentReportNumber == null) {
            ref.read(createReportProvider.notifier).fetchNextReportNumber();
          }
        }
      }

      if (widget.reportId != null &&
          currentState.report?.status ==
              ServiceReportStatus.finalized.dbValue) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El reporte está finalizado y no se puede editar.'),
            ),
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createReportProvider);
    final notifier = ref.read(createReportProvider.notifier);

    return PopScope(
      canPop: !state.hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog();
        if (shouldPop && context.mounted) {
          notifier.reset();
          context.pop();
        }
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
                  color: state.hasChanges ? colors.onSurface : colors.outline,
                ),
                tooltip: state.hasChanges
                    ? 'Guardar cambios'
                    : 'Sin modificaciones',
                onPressed: state.hasChanges
                    ? () => _handleSaveDraft(ref)
                    : null,
              ),
            IconButton(
              icon: Icon(Icons.more_vert, color: colors.onSurface),
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
            label: 'Descartar cambios',
            onTap: () async {
              context.pop();
              final shouldDiscard = await _showDiscardDialog();
              if (shouldDiscard && mounted) {
                notifier.reset();
                context.pop();
              }
            },
          ),
      ],
    );
  }

  Future<bool> _showDiscardDialog() async {
    final result = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.confirmation(
        title: '¿Descartar cambios?',
        contentText:
            'Tienes modificaciones sin guardar en el reporte. Si sales ahora, se perderán.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
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
