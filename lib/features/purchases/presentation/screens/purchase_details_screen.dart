import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/draft_toast.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import '../providers/purchase_details_provider.dart';
import '../providers/add_purchase_provider.dart';
import '../widgets/view_purchase_details_tab.dart';
import '../widgets/view_purchase_products_tab.dart';
import '../widgets/view_purchase_summary_tab.dart';
import '../widgets/add_purchase_details_tab.dart';
import '../widgets/add_purchase_products_tab.dart';
import '../widgets/add_purchase_summary_tab.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';

class PurchaseDetailsScreen extends ConsumerStatefulWidget {
  final String purchaseId;
  final bool startInEditMode;
  final String? highlightProductId;

  const PurchaseDetailsScreen({
    super.key,
    required this.purchaseId,
    this.startInEditMode = false,
    this.highlightProductId,
  });

  @override
  ConsumerState<PurchaseDetailsScreen> createState() =>
      _PurchaseDetailsScreenState();
}

class _PurchaseDetailsScreenState extends ConsumerState<PurchaseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AppLifecycleListener _lifecycleListener;
  bool _isEditing = false;
  bool _dataLoadedToEditState = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      initialIndex:
          (widget.startInEditMode || widget.highlightProductId != null) ? 1 : 2,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        if (_isEditing) {
          ref
              .read(addPurchaseProvider.notifier)
              .autoSaveDraft(
                tabIndex: _tabController.index,
                purchaseId: widget.purchaseId,
              );
        }
      }
    });

    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        if (_isEditing) {
          ref
              .read(addPurchaseProvider.notifier)
              .autoSaveDraft(
                tabIndex: _tabController.index,
                purchaseId: widget.purchaseId,
              );
        }
      },
      onInactive: () {
        if (_isEditing) {
          ref
              .read(addPurchaseProvider.notifier)
              .autoSaveDraft(
                tabIndex: _tabController.index,
                purchaseId: widget.purchaseId,
              );
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _enterEditMode(PurchaseDetailsData data) async {
    if (!_dataLoadedToEditState) {
      final editState = ref.read(addPurchaseProvider);
      if (editState.purchaseId != widget.purchaseId) {
        ref
            .read(addPurchaseProvider.notifier)
            .loadFromDetails(
              data.purchase,
              data.items,
              data.serials,
              data.supplierTaxId,
            );
      }
      _dataLoadedToEditState = true;
    }

    setState(() {
      _isEditing = true;
    });

    final draft = await ref
        .read(addPurchaseProvider.notifier)
        .checkAndRestoreDraft(purchaseId: widget.purchaseId);

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
                .clearDraft(purchaseId: widget.purchaseId);
            ref
                .read(addPurchaseProvider.notifier)
                .loadFromDetails(
                  data.purchase,
                  data.items,
                  data.serials,
                  data.supplierTaxId,
                );
            setState(() {
              _tabController.index = 0;
            });
          }
        },
      );
    }
  }

  Future<void> _handlePop() async {
    final notifier = ref.read(addPurchaseProvider.notifier);

    if (_isEditing) {
      final hasChanges = notifier.hasChanges;
      await notifier.saveDraftNow(
        tabIndex: _tabController.index,
        purchaseId: widget.purchaseId,
      );
      notifier.reset(clearPersistedDraft: false, purchaseId: widget.purchaseId);
      setState(() {
        _isEditing = false;
      });
      if (hasChanges && mounted) {
        AppToast.info(
          context,
          message: 'Cambios guardados temporalmente',
          icon: Icons.bookmark_added_outlined,
        );
      }
    } else {
      if (!mounted) return;
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final asyncData = ref.watch(purchaseDetailsProvider(widget.purchaseId));

    return asyncData.when(
      loading: () => Scaffold(
        appBar: const StandardAppBar(
          title: 'Registro de compra',
          subtitle: 'Cargando...',
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: const StandardAppBar(title: 'Registro de compra'),
        body: Center(child: Text('Error al cargar los detalles: $error')),
      ),
      data: (data) {
        final purchase = data.purchase;

        if (widget.startInEditMode && !_dataLoadedToEditState) {
          _dataLoadedToEditState = true;
          _isEditing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _enterEditMode(data);
          });
        }

        return PopScope(
          canPop: !_isEditing,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handlePop();
          },
          child: Scaffold(
            backgroundColor: colors.surface,
            appBar: StandardAppBar(
              title: 'Registro de compra',
              subtitle:
                  '${purchase.documentType == 'invoice' ? 'FC' : 'NE'} #${purchase.documentNumber} (${purchase.supplierName ?? 'Proveedor'})',
              actions: [
                if (_isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.save_outlined),
                    tooltip: 'Guardar cambios',
                    onPressed:
                        (ref.read(addPurchaseProvider.notifier).hasChanges &&
                            !ref.watch(addPurchaseProvider).isLoading)
                        ? _savePurchaseChanges
                        : null,
                    color:
                        (ref.read(addPurchaseProvider.notifier).hasChanges &&
                            !ref.watch(addPurchaseProvider).isLoading)
                        ? colors.onSurfaceVariant
                        : colors.onSurfaceVariant.withValues(alpha: 0.38),
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
                tabs: [
                  const Tab(text: 'Detalles'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Productos'),
                        if (_isEditing &&
                            ref
                                .watch(addPurchaseProvider)
                                .hasMissingSerials) ...[
                          const SizedBox(width: 6),
                          Badge(backgroundColor: colors.error, smallSize: 8),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Resúmen'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: !_isEditing
                  ? [
                      ViewPurchaseDetailsTab(data: data),
                      ViewPurchaseProductsTab(
                        data: data,
                        highlightProductId: widget.highlightProductId,
                      ),
                      ViewPurchaseSummaryTab(
                        data: data,
                        onNavigateToTab: (index) =>
                            _tabController.animateTo(index),
                      ),
                    ]
                  : [
                      const AddPurchaseDetailsTab(),
                      const AddPurchaseProductsTab(),
                      AddPurchaseSummaryTab(
                        onNavigateToTab: (index) =>
                            _tabController.animateTo(index),
                      ),
                    ],
            ),
            floatingActionButton: _buildFab(data),
          ),
        );
      },
    );
  }

  Future<void> _savePurchaseChanges() async {
    final notifier = ref.read(addPurchaseProvider.notifier);
    final success = await notifier.createPurchase();
    if (success) {
      await notifier.clearDraft(purchaseId: widget.purchaseId);
      if (!mounted) return;
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra actualizada correctamente')),
      );
    } else {
      if (!mounted) return;
      final error = ref.read(addPurchaseProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
      }
    }
  }

  Widget? _buildFab(PurchaseDetailsData data) {
    final colors = Theme.of(context).colorScheme;

    if (_isEditing) {
      // Hide the 'Agregar' button if the purchase is linked to a supplier order
      if (_tabController.index == 1 && data.purchase.supplierOrderId == null) {
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
      return null;
    }

    // View Mode FABs
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: FloatingActionButton(
        onPressed: () => _enterEditMode(data),
        backgroundColor: colors.primaryContainer,
        child: Icon(Icons.edit_outlined, color: colors.onPrimaryContainer),
      ),
    );
  }
}
