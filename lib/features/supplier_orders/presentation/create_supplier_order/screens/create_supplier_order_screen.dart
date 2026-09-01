import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/draft_toast.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../providers/create_supplier_order_provider.dart';
import '../../supplier_orders_list/providers/supplier_orders_providers.dart';
import '../tabs/create_supplier_order_details_tab.dart';
import '../tabs/create_supplier_order_products_tab.dart';
import '../tabs/create_supplier_order_summary_tab.dart';

class CreateSupplierOrderScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final bool editMode;
  final int? initialTab;

  const CreateSupplierOrderScreen({
    super.key,
    this.orderId,
    this.editMode = false,
    this.initialTab,
  });

  @override
  ConsumerState<CreateSupplierOrderScreen> createState() =>
      _CreateSupplierOrderScreenState();
}

class _CreateSupplierOrderScreenState
    extends ConsumerState<CreateSupplierOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: (widget.initialTab ?? 0).clamp(0, 2),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        final orderId =
            widget.orderId ?? ref.read(createSupplierOrderProvider).id;
        ref
            .read(createSupplierOrderProvider.notifier)
            .autoSaveDraft(tabIndex: _tabController.index, orderId: orderId);
      }
    });

    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        final orderId =
            widget.orderId ?? ref.read(createSupplierOrderProvider).id;
        ref
            .read(createSupplierOrderProvider.notifier)
            .autoSaveDraft(tabIndex: _tabController.index, orderId: orderId);
      },
      onInactive: () {
        final orderId =
            widget.orderId ?? ref.read(createSupplierOrderProvider).id;
        ref
            .read(createSupplierOrderProvider.notifier)
            .autoSaveDraft(tabIndex: _tabController.index, orderId: orderId);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentState = ref.read(createSupplierOrderProvider);

      if (widget.editMode) {
        final currentId = widget.orderId ?? currentState.id;
        if (currentId != null) {
          final draft = await ref
              .read(createSupplierOrderProvider.notifier)
              .checkAndRestoreDraft(orderId: currentId);

          if (draft != null && mounted) {
            setState(() {
              if (draft.tabIndex >= 0 && draft.tabIndex < 3) {
                _tabController.index = draft.tabIndex;
              }
            });

            DraftToast.show(
              context,
              message: 'Cambios restaurados automáticamente',
              onDiscard: () async {
                final colors = Theme.of(context).colorScheme;
                final shouldDiscard = await CustomDialog.show<bool>(
                  context: context,
                  dialog: CustomDialog.destructive(
                    title: '¿Descartar cambios locales?',
                    contentText:
                        'Se eliminarán las modificaciones sin guardar y se recargarán los datos del servidor.',
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.error,
                          foregroundColor: colors.onError,
                        ),
                        child: const Text('Descartar'),
                      ),
                    ],
                  ),
                );

                if (shouldDiscard == true && mounted) {
                  await ref
                      .read(createSupplierOrderProvider.notifier)
                      .clearDraft(orderId: currentId);
                  final repo = ref.read(supplierOrdersRepositoryProvider);
                  try {
                    final details = await repo.getSupplierOrderDetails(
                      currentId,
                    );
                    ref
                        .read(createSupplierOrderProvider.notifier)
                        .loadFromExisting(details.order, details.items);
                  } catch (_) {}
                  setState(() {
                    _tabController.index = 0;
                  });
                }
              },
            );
          }
        }
      } else {
        // Modo creación:
        if (currentState.id != null && currentState.id!.isNotEmpty) {
          ref
              .read(createSupplierOrderProvider.notifier)
              .reset(clearPersistedDraft: false);
        }

        final draft = await ref
            .read(createSupplierOrderProvider.notifier)
            .checkAndRestoreDraft();
        if (draft != null && mounted) {
          setState(() {
            if (draft.tabIndex >= 0 && draft.tabIndex < 3) {
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
                    .read(createSupplierOrderProvider.notifier)
                    .clearDraft();
                ref
                    .read(createSupplierOrderProvider.notifier)
                    .reset(clearPersistedDraft: true);
                ref
                    .read(createSupplierOrderProvider.notifier)
                    .fetchNextOrderNumber();
                setState(() {
                  _tabController.index = 0;
                });
              }
            },
          );
        } else {
          if (ref.read(createSupplierOrderProvider).currentOrderNumber ==
              null) {
            ref
                .read(createSupplierOrderProvider.notifier)
                .fetchNextOrderNumber();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePop() async {
    final state = ref.read(createSupplierOrderProvider);
    final hasDataOrChanges =
        state.isDirty || state.items.isNotEmpty || state.supplierId != null;
    final currentId = widget.orderId ?? state.id;

    await ref
        .read(createSupplierOrderProvider.notifier)
        .saveDraftNow(tabIndex: _tabController.index, orderId: currentId);
    ref
        .read(createSupplierOrderProvider.notifier)
        .reset(clearPersistedDraft: false, orderId: currentId);
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

  Future<bool> _showDiscardDialog() async {
    final colors = Theme.of(context).colorScheme;
    final isEditing = widget.orderId != null;
    return await CustomDialog.show<bool>(
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
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                ),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createSupplierOrderProvider);

    final branchesAsync = state.supplierId != null
        ? ref.watch(supplierBranchesProvider(state.supplierId!))
        : null;
    final branches = branchesAsync?.valueOrNull ?? [];
    final hasBranches = branches.isNotEmpty;
    final isDetailsValid = state.isDetailsValid(hasBranches: hasBranches);
    final canSave =
        !state.isLoading &&
        widget.editMode &&
        state.isDirty &&
        state.items.isNotEmpty &&
        isDetailsValid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: StandardAppBar(
          title: widget.editMode ? 'Modificar orden' : 'Nueva orden de compra',
          subtitle: state.supplierName != null
              ? '#${state.currentOrderNumber} (${state.supplierName})'
              : (state.currentOrderNumber != null
                    ? '#${state.currentOrderNumber}'
                    : 'Cargando...'),
          actions: [
            if (widget.editMode) ...[
              IconButton(
                icon: Icon(
                  state.isLoading ? Icons.hourglass_empty : Icons.save_outlined,
                  color: canSave
                      ? colors.onSurfaceVariant
                      : colors.onSurfaceVariant.withValues(alpha: 0.38),
                ),
                tooltip: canSave ? 'Guardar cambios' : null,
                onPressed: canSave
                    ? () async {
                        final updatedOrderId = await ref
                            .read(createSupplierOrderProvider.notifier)
                            .saveOrder();
                        if (!context.mounted) return;
                        if (updatedOrderId != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Orden de compra guardada exitosamente',
                              ),
                            ),
                          );
                          ref.invalidate(createSupplierOrderProvider);
                          context.pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                state.error ?? 'Error al guardar la orden',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    : null,
              ),
              const SizedBox(width: 48),
            ],
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorColor: colors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Detalles'),
              Tab(text: 'Productos'),
              Tab(text: 'Resumen'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const CreateSupplierOrderDetailsTab(),
            const CreateSupplierOrderProductsTab(),
            CreateSupplierOrderSummaryTab(
              editMode: widget.editMode,
              onNavigateToTab: (index) => _tabController.animateTo(index),
            ),
          ],
        ),
      ),
    );
  }
}
