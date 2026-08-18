import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../providers/create_supplier_order_provider.dart';
import '../../supplier_orders_list/providers/supplier_orders_providers.dart';
import '../tabs/create_supplier_order_details_tab.dart';
import '../tabs/create_supplier_order_products_tab.dart';
import '../tabs/create_supplier_order_summary_tab.dart';

class CreateSupplierOrderScreen extends ConsumerStatefulWidget {
  final bool editMode;
  final int? initialTab;

  const CreateSupplierOrderScreen({
    super.key,
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
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final canSave = !state.isLoading &&
        widget.editMode &&
        state.isDirty &&
        state.items.isNotEmpty &&
        isDetailsValid;

    return PopScope(
      canPop: !state.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await CustomDialog.show<bool>(
          context: context,
          dialog: CustomDialog.destructive(
            title: '¿Descartar cambios?',
            contentText:
                'Se perderán todos los datos y productos ingresados en este borrador.',
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continuar editando'),
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
        );

        if (shouldPop == true && context.mounted) {
          context.pop();
        }
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
                              content: Text('Orden de compra guardada exitosamente'),
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
