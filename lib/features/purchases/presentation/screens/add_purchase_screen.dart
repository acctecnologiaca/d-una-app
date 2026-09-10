import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/draft_toast.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_details_tab.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_products_tab.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_summary_tab.dart';
import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';
import 'package:d_una_app/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:d_una_app/features/purchases/presentation/providers/purchase_details_provider.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/bottom_sheet_action_item.dart';

class AddPurchaseScreen extends ConsumerStatefulWidget {
  final String? purchaseId;
  final int initialTabIndex;

  const AddPurchaseScreen({
    super.key,
    this.purchaseId,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends ConsumerState<AddPurchaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        final purchaseId =
            widget.purchaseId ?? ref.read(addPurchaseProvider).purchaseId;
        ref
            .read(addPurchaseProvider.notifier)
            .autoSaveDraft(
              tabIndex: _tabController.index,
              purchaseId: purchaseId,
            );
      }
    });

    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        final purchaseId =
            widget.purchaseId ?? ref.read(addPurchaseProvider).purchaseId;
        ref
            .read(addPurchaseProvider.notifier)
            .autoSaveDraft(
              tabIndex: _tabController.index,
              purchaseId: purchaseId,
            );
      },
      onInactive: () {
        final purchaseId =
            widget.purchaseId ?? ref.read(addPurchaseProvider).purchaseId;
        ref
            .read(addPurchaseProvider.notifier)
            .autoSaveDraft(
              tabIndex: _tabController.index,
              purchaseId: purchaseId,
            );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentState = ref.read(addPurchaseProvider);
      final isEditing =
          widget.purchaseId != null || currentState.purchaseId != null;

      if (isEditing) {
        final currentId = widget.purchaseId ?? currentState.purchaseId;
        if (currentId != null) {
          final draft = await ref
              .read(addPurchaseProvider.notifier)
              .checkAndRestoreDraft(purchaseId: currentId);

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
                      .read(addPurchaseProvider.notifier)
                      .clearDraft(purchaseId: currentId);
                  final repo = ref.read(purchasesRepositoryProvider);
                  try {
                    final details = await repo.getPurchaseDetails(currentId);
                    ref
                        .read(addPurchaseProvider.notifier)
                        .loadFromDetails(
                          details.purchase,
                          details.items,
                          details.serials,
                          details.supplierTaxId,
                        );
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
        if (currentState.purchaseId != null &&
            currentState.purchaseId!.isNotEmpty) {
          ref
              .read(addPurchaseProvider.notifier)
              .reset(clearPersistedDraft: false);
        }

        final draft = await ref
            .read(addPurchaseProvider.notifier)
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
                await ref.read(addPurchaseProvider.notifier).clearDraft();
                ref
                    .read(addPurchaseProvider.notifier)
                    .reset(clearPersistedDraft: true);
                setState(() {
                  _tabController.index = 0;
                });
              }
            },
          );
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
    final state = ref.read(addPurchaseProvider);
    final notifier = ref.read(addPurchaseProvider.notifier);
    final isEditing = widget.purchaseId != null || state.purchaseId != null;
    final hasDataOrChanges = isEditing
        ? notifier.hasChanges
        : (state.products.isNotEmpty ||
            (state.supplierId != null && state.supplierId!.isNotEmpty) ||
            (state.documentNumber != null &&
                state.documentNumber!.trim().isNotEmpty));
    final currentId = widget.purchaseId ?? state.purchaseId;

    if (hasDataOrChanges) {
      await notifier.saveDraftNow(
        tabIndex: _tabController.index,
        purchaseId: currentId,
      );
    }
    notifier.reset(clearPersistedDraft: false, purchaseId: currentId);
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
    final isEditing = widget.purchaseId != null;
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

  void _showActionsMenu(WidgetRef ref) {
    final state = ref.read(addPurchaseProvider);
    final notifier = ref.read(addPurchaseProvider.notifier);
    final isEditing = widget.purchaseId != null || state.purchaseId != null;
    final currentId = widget.purchaseId ?? state.purchaseId;

    CustomActionSheet.show(
      context: context,
      title: 'Opciones de compra',
      actions: [
        BottomSheetActionItem(
          icon: Icons.bookmark_add_outlined,
          label: 'Guardar y continuar luego',
          subtitle: 'Guarda un borrador local para continuar luego',
          onTap: () async {
            context.pop();
            await notifier.saveDraftNow(
              tabIndex: _tabController.index,
              purchaseId: currentId,
            );
            notifier.reset(clearPersistedDraft: false, purchaseId: currentId);
            if (!mounted) return;
            AppToast.info(
              context,
              message: 'Cambios guardados temporalmente',
              icon: Icons.bookmark_added_outlined,
            );
            context.pop();
          },
        ),
        BottomSheetActionItem(
          icon: Icons.delete_outline,
          label: isEditing
              ? 'Descartar cambios locales'
              : 'Descartar borrador',
          subtitle: 'Elimina las modificaciones no guardadas',
          onTap: () async {
            context.pop();
            final shouldDiscard = await _showDiscardDialog();
            if (!shouldDiscard) return;
            await notifier.clearDraft(purchaseId: currentId);
            notifier.reset(clearPersistedDraft: true, purchaseId: currentId);
            if (!mounted) return;
            context.pop();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addPurchaseProvider);
    final colors = Theme.of(context).colorScheme;

    final isEditing = widget.purchaseId != null || state.purchaseId != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: StandardAppBar(
          title: isEditing ? 'Modificar compra' : 'Registrar nueva compra',
          subtitle: state.supplierName != null
              ? '${state.documentNumber ?? "Sin número"} (${state.supplierName})'
              : (state.documentNumber != null
                    ? '${state.documentNumber}'
                    : null),
          actions: [
            if (isEditing)
              IconButton(
                icon: Icon(
                  state.isLoading ? Icons.hourglass_empty : Icons.save_outlined,
                  color: (ref.watch(addPurchaseProvider.notifier).hasChanges &&
                          !state.isLoading)
                      ? colors.onSurfaceVariant
                      : colors.onSurfaceVariant.withValues(alpha: 0.38),
                ),
                tooltip: ref.watch(addPurchaseProvider.notifier).hasChanges
                    ? 'Guardar cambios'
                    : 'Sin modificaciones',
                onPressed: (ref.watch(addPurchaseProvider.notifier).hasChanges &&
                        !state.isLoading)
                    ? () async {
                        final currentId = widget.purchaseId ?? state.purchaseId;
                        final success = await ref
                            .read(addPurchaseProvider.notifier)
                            .createPurchase();
                        if (!context.mounted) return;
                        if (success) {
                          ref.invalidate(paginatedPurchasesListProvider);
                          if (currentId != null) {
                            ref.invalidate(purchaseDetailsProvider(currentId));
                          }
                          AppToast.success(
                            context,
                            message: 'Compra actualizada correctamente',
                          );
                          context.pop();
                        } else {
                          AppToast.error(
                            context,
                            message: state.error ?? 'Error al guardar la compra',
                          );
                        }
                      }
                    : null,
              ),
            IconButton(
              icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
              onPressed: () => _showActionsMenu(ref),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorColor: colors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              const Tab(text: 'Detalles'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Productos'),
                    if (state.hasMissingSerials) ...[
                      const SizedBox(width: 6),
                      Badge(backgroundColor: colors.error, smallSize: 8),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Resumen'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const AddPurchaseDetailsTab(),
            const AddPurchaseProductsTab(),
            AddPurchaseSummaryTab(
              onNavigateToTab: (index) => _tabController.animateTo(index),
            ),
          ],
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget? _buildFab() {
    // Only show FAB on Products (1) tab
    if (_tabController.index != 1) return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: CustomExtendedFab(
        onPressed: () {
          context.push('/my-purchases/add/select-product');
        },
        icon: Icons.add,
        label: 'Agregar',
      ),
    );
  }
}
