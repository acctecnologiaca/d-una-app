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
import 'package:d_una_app/features/purchases/presentation/widgets/save_changes_dialog.dart';
import 'package:material_symbols_icons/symbols.dart';

class PurchaseDetailsScreen extends ConsumerStatefulWidget {
  final String purchaseId;

  const PurchaseDetailsScreen({super.key, required this.purchaseId});

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
    // Inicia en la pestaña "Resúmen" (index 2)
    _tabController = TabController(length: 3, initialIndex: 2, vsync: this);
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
      ref
          .read(addPurchaseProvider.notifier)
          .loadFromDetails(
            data.purchase,
            data.items,
            data.serials,
            data.supplierTaxId,
          );
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
        appBar: const StandardAppBar(title: 'Cargando compra...'),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: const StandardAppBar(title: 'Error'),
        body: Center(child: Text('Error: $error')),
      ),
      data: (data) {
        final purchase = data.purchase;
        final notifier = ref.read(addPurchaseProvider.notifier);

        return PopScope(
          canPop: !(_isEditing && notifier.hasChanges),
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            final shouldPop = await SaveChangesDialog.show<bool>(
              context,
              onSave: () async {
                final success = await notifier.createPurchase();
                if (success && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              onDiscard: () {
                notifier.reset();
                Navigator.of(context).pop(true);
              },
              onContinue: () {
                Navigator.of(context).pop(false);
              },
            );

            if (shouldPop == true && context.mounted) {
              context.pop();
            }
          },
          child: Scaffold(
          backgroundColor: colors.surface,
          appBar: StandardAppBar(
            title: 'Compra',
            subtitle:
                '${purchase.documentType == 'invoice' ? 'F/.' : 'N/E'} #${purchase.documentNumber} - ${purchase.supplierName ?? 'Proveedor'}',
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: Icon(Icons.more_vert, color: colors.onSurface),
                  tooltip: 'Opciones',
                  onPressed: () => _showPurchaseOptions(context, data),
                ),
              if (_isEditing)
                IconButton(
                  icon: Icon(Icons.close, color: colors.onSurface),
                  tooltip: 'Cancelar edición',
                  onPressed: () async {
                    if (notifier.hasChanges) {
                      final shouldClose = await SaveChangesDialog.show<bool>(
                        context,
                        onSave: () async {
                          final success = await notifier.createPurchase();
                          if (success && context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        onDiscard: () {
                          notifier.reset();
                          Navigator.of(context).pop(true);
                        },
                        onContinue: () {
                          Navigator.of(context).pop(false);
                        },
                      );
                      
                      if (shouldClose == true && mounted) {
                        setState(() { _isEditing = false; });
                      }
                    } else {
                      setState(() {
                        _isEditing = false;
                      });
                    }
                  },
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
                    const AddPurchaseProductsTab(),
                    AddPurchaseSummaryTab(
                      onNavigateToTab: (index) =>
                          _tabController.animateTo(index),
                    ),
                  ]
                : [
                    ViewPurchaseDetailsTab(data: data),
                    ViewPurchaseProductsTab(data: data),
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

  Widget? _buildFab(PurchaseDetailsData data) {
    final colors = Theme.of(context).colorScheme;
    if (_isEditing) {
      // Logic for editing mode FAB (delegated to inner screens if any, or managed here)
      // AddPurchaseScreen handles its own "Agregar" FAB conditionally on index 1
      if (_tabController.index == 1) {
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
    // Edit FAB visible depending on tabs (User requested edit FAB on Productos and Resúmen,
    // but also mentioned Detalles has its own. We can put it globally for all tabs).
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: FloatingActionButton(
        onPressed: () => _enterEditMode(data),
        backgroundColor: colors.primaryContainer,
        child: Icon(Icons.edit, color: colors.onPrimaryContainer),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar compra?'),
        content: const Text(
          'Esta acción eliminará permanentemente la compra y sus productos asociados del sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: colors.error),
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
