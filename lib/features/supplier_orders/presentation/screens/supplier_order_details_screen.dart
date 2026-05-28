import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../providers/supplier_orders_providers.dart';
import '../providers/create_supplier_order_provider.dart';
import '../widgets/view_supplier_order_details_tab.dart';
import '../widgets/view_supplier_order_products_tab.dart';
import '../widgets/view_supplier_order_summary_tab.dart';
import '../../domain/models/supplier_order_status.dart';

class SupplierOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const SupplierOrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<SupplierOrderDetailsScreen> createState() => _SupplierOrderDetailsScreenState();
}

class _SupplierOrderDetailsScreenState extends ConsumerState<SupplierOrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final detailsAsync = ref.watch(supplierOrderDetailProvider(widget.orderId));

    return detailsAsync.when(
      data: (data) {
        final order = data.order;
        final items = data.items;
        final isDraft = order.status == SupplierOrderStatus.draft;

        return Scaffold(
          appBar: StandardAppBar(
            title: order.orderNumber,
            subtitle: order.supplierName,
            actions: [
              if (isDraft)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    ref.read(createSupplierOrderProvider.notifier).loadFromExisting(order, items);
                    context.push('/supplier-orders/edit/${order.id}');
                  },
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurfaceVariant,
              indicatorColor: colors.primary,
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
              ViewSupplierOrderDetailsTab(order: order),
              ViewSupplierOrderProductsTab(order: order, items: items),
              ViewSupplierOrderSummaryTab(
                order: order,
                onNavigateToTab: (index) => _tabController.animateTo(index),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error al cargar detalles de la orden')),
      ),
    );
  }
}
