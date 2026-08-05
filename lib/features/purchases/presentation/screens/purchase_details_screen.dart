import 'package:d_una_app/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/bottom_sheet_action_item.dart';
import '../providers/purchase_details_provider.dart';
import '../providers/add_purchase_provider.dart';
import '../widgets/view_purchase_details_tab.dart';
import '../widgets/view_purchase_products_tab.dart';
import '../widgets/view_purchase_summary_tab.dart';
import '../widgets/add_purchase_details_tab.dart';
import '../widgets/add_purchase_products_tab.dart';
import '../widgets/add_purchase_summary_tab.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:material_symbols_icons/symbols.dart';

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
  bool _isEditing = false;
  bool _dataLoadedToEditState = false;

  @override
  void initState() {
    super.initState();
    // Inicia en la pestaña "Productos" (index 1) si startInEditMode es true o se especificó un producto a destacar,
    // de lo contrario en "Resúmen" (index 2)
    _tabController = TabController(
      length: 3,
      initialIndex:
          (widget.startInEditMode || widget.highlightProductId != null) ? 1 : 2,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _enterEditMode(PurchaseDetailsData data) {
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
        final notifier = ref.read(addPurchaseProvider.notifier);

        if (widget.startInEditMode && !_dataLoadedToEditState) {
          _dataLoadedToEditState = true;
          _isEditing = true;
          final editState = ref.read(addPurchaseProvider);
          if (editState.purchaseId != widget.purchaseId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(addPurchaseProvider.notifier)
                  .loadFromDetails(
                    data.purchase,
                    data.items,
                    data.serials,
                    data.supplierTaxId,
                  );
            });
          }
        }

        return PopScope(
          canPop: !_isEditing,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            if (_isEditing) {
              if (notifier.hasChanges) {
                final shouldDiscard = await CustomDialog.show<bool>(
                  context: context,
                  dialog: CustomDialog.destructive(
                    title: '¿Descartar cambios?',
                    contentText:
                        'Se perderán todos los cambios realizados en esta compra.',
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Continuar editando'),
                      ),
                      FilledButton(
                        onPressed: () {
                          notifier.reset(); // clear state if discarded
                          Navigator.of(context).pop(true);
                        },
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
                  setState(() {
                    _isEditing = false;
                  });
                }
              } else {
                setState(() {
                  _isEditing = false;
                });
              }
            }
          },
          child: Scaffold(
            backgroundColor: colors.surface,
            appBar: StandardAppBar(
              title: 'Registro de compra',
              subtitle:
                  '${purchase.documentType == 'invoice' ? 'FC' : 'NE'} #${purchase.documentNumber} (${purchase.supplierName ?? 'Proveedor'})',
              actions: [
                if (!_isEditing)
                  IconButton(
                    icon: Icon(Icons.more_vert, color: colors.onSurface),
                    tooltip: 'Opciones',
                    onPressed: () => _showPurchaseOptions(context, data),
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
                        if (_isEditing
                            ? ref.watch(addPurchaseProvider).hasMissingSerials
                            : data.hasMissingSerials) ...[
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
              children: _isEditing
                  ? [
                      const AddPurchaseDetailsTab(),
                      AddPurchaseProductsTab(
                        highlightProductId: widget.highlightProductId,
                      ),
                      AddPurchaseSummaryTab(
                        onNavigateToTab: (index) =>
                            _tabController.animateTo(index),
                      ),
                    ]
                  : [
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
    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra actualizada correctamente')),
      );
    } else if (mounted) {
      final error = ref.read(addPurchaseProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  Widget _buildQuickSaveFab(bool hasChanges, bool isLoading) {
    final colors = Theme.of(context).colorScheme;
    final isEnabled = hasChanges && !isLoading;

    return FloatingActionButton(
      heroTag: 'quick_save_fab',
      onPressed: isEnabled ? _savePurchaseChanges : null,
      backgroundColor: isEnabled
          ? colors.secondaryContainer
          : colors.surfaceContainerHighest,
      foregroundColor: isEnabled
          ? colors.onSecondaryContainer
          : colors.onSurface.withValues(alpha: 0.38),
      elevation: isEnabled ? 4 : 0,
      tooltip: 'Guardar cambios',
      child: const Icon(Icons.save_outlined),
    );
  }

  Widget? _buildFab(PurchaseDetailsData data) {
    final colors = Theme.of(context).colorScheme;
    final notifier = ref.read(addPurchaseProvider.notifier);
    final addState = ref.watch(addPurchaseProvider);
    final hasChanges = notifier.hasChanges;
    final isLoading = addState.isLoading;

    if (_isEditing) {
      // Pestaña 2 (Resumen): No mostrar FAB rápido (AddPurchaseSummaryTab ya tiene su botón de guardar)
      if (_tabController.index == 2) return null;

      // Pestaña 1 (Productos): Apilar con el FAB de Agregar si no es una compra desde OC
      if (_tabController.index == 1 && data.purchase.supplierOrderId == null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildQuickSaveFab(hasChanges, isLoading),
              const SizedBox(height: 12),
              CustomExtendedFab(
                onPressed: () {
                  context.push('/my-purchases/add/select-product');
                },
                icon: Icons.add,
                label: 'Agregar',
              ),
            ],
          ),
        );
      }

      // Pestaña 0 (Detalles) o Pestaña 1 (Productos vinculada a OC)
      return Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: _buildQuickSaveFab(hasChanges, isLoading),
      );
    }

    // Modo Visualización FAB
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: FloatingActionButton(
        onPressed: () => _enterEditMode(data),
        backgroundColor: colors.primaryContainer,
        child: Icon(Icons.edit_outlined, color: colors.onPrimaryContainer),
      ),
    );
  }

  void _showPurchaseOptions(BuildContext context, PurchaseDetailsData data) {
    CustomActionSheet.show(
      context: context,
      title: 'Otras opciones',
      actions: [
        BottomSheetActionItem(
          label: 'Descargar PDF',
          icon: Symbols.picture_as_pdf,
          onTap: () {
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Generando PDF... (Funcionalidad en desarrollo)'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        if (data.purchase.supplierOrderId == null)
          BottomSheetActionItem(
            label: 'Eliminar',
            icon: Icons.delete_outline,
            onTap: () {
              context.pop();
              _confirmDelete(context);
            },
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    final confirmed = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.destructive(
        title: '¿Eliminar compra?',
        contentText:
            'Esta acción eliminará permanentemente la compra y los productos asociados.',
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(purchasesRepositoryProvider)
            .deletePurchase(widget.purchaseId);
        ref.invalidate(purchasesProvider(null));
        if (context.mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compra eliminada correctamente')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }
}
