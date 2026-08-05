import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../providers/create_supplier_order_provider.dart';
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
          bottom: TabBar(
            controller: _tabController,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorColor: colors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Detalles'),
              Tab(text: 'Productos'),
              Tab(text: 'Resúmen'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const CreateSupplierOrderDetailsTab(),
            const CreateSupplierOrderProductsTab(),
            CreateSupplierOrderSummaryTab(
              onNavigateToTab: (index) => _tabController.animateTo(index),
            ),
          ],
        ),
      ),
    );
  }
}
