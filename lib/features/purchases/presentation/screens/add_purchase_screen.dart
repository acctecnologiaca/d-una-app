import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_details_tab.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_products_tab.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_summary_tab.dart';
import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';

class AddPurchaseScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const AddPurchaseScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends ConsumerState<AddPurchaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final state = ref.watch(addPurchaseProvider);
    final colors = Theme.of(context).colorScheme;
    final notifier = ref.read(addPurchaseProvider.notifier);

    return PopScope(
      canPop: !notifier.hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await CustomDialog.show<bool>(
          context: context,
          dialog: CustomDialog.destructive(
            title: '¿Descartar registro?',
            contentText:
                'Se perderán todos los datos y productos ingresados en este registro de compra.',
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

        if (shouldPop == true && context.mounted) {
          context.pop(); // Pop the screen
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: StandardAppBar(
          title: 'Registrar nueva compra',
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
              const Tab(text: 'Resúmen'),
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
