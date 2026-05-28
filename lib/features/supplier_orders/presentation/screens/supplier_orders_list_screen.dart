import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/empty_list_state.dart';
import 'package:d_una_app/shared/widgets/paginated_list_view.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import '../providers/supplier_orders_providers.dart';
import '../providers/create_supplier_order_provider.dart';
import '../widgets/supplier_order_card.dart';

class SupplierOrdersListScreen extends ConsumerStatefulWidget {
  const SupplierOrdersListScreen({super.key});

  @override
  ConsumerState<SupplierOrdersListScreen> createState() =>
      _SupplierOrdersListScreenState();
}

class _SupplierOrdersListScreenState
    extends ConsumerState<SupplierOrdersListScreen> {
  SortOption _currentSort = SortOption.recent;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final paginatedAsync = ref.watch(paginatedSupplierOrdersProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: const StandardAppBar(title: 'Órdenes de Compra'),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: 'Buscar órdenes...',
              readOnly: true,
              showFilterIcon: true,
              onTap: () {
                context.push('/supplier-orders/search');
              },
            ),
          ),
          const SizedBox(height: 16),
          // Sort Selector
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                SortSelector(
                  currentSort: _currentSort,
                  onSortChanged: (val) {
                    setState(() => _currentSort = val);
                  },
                  options: const [SortOption.recent],
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(paginatedSupplierOrdersProvider.notifier)
                    .refresh();
              },
              child: Builder(
                builder: (context) {
                  final state = paginatedAsync.valueOrNull;

                  if (state == null || state.isInitialLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (paginatedAsync.hasError && state.items.isEmpty) {
                    return FriendlyErrorWidget(
                      error: paginatedAsync.error!,
                      onRetry: () => ref
                          .read(paginatedSupplierOrdersProvider.notifier)
                          .refresh(),
                    );
                  }

                  var items = state.items;
                  // Local sorting just in case we add more sorting options
                  if (_currentSort == SortOption.recent) {
                    // Ordered by date desc (already handled in Supabase mostly, but safe backup)
                    items = List.from(items)
                      ..sort((a, b) => b.date.compareTo(a.date));
                  }

                  if (items.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: const EmptyListState(
                          icon: Icons.shopping_cart_outlined,
                          message: 'No hay órdenes de compra registradas.',
                        ),
                      ),
                    );
                  }

                  return PaginatedListView(
                    items: items,
                    isLoadingMore: state.isLoadingMore,
                    hasReachedEnd: state.hasReachedEnd,
                    onLoadMore: () => ref
                        .read(paginatedSupplierOrdersProvider.notifier)
                        .loadMore(),
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 90),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 0, color: Colors.transparent),
                    itemBuilder: (context, index, order) {
                      return SupplierOrderCard(
                        order: order,
                        onTap: () {
                          context.push('/supplier-orders/view/${order.id}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          onPressed: () {
            ref
                .read(createSupplierOrderProvider.notifier)
                .initializeNew(supplierId: '');
            context.push('/supplier-orders/create');
          },
          label: 'Nueva',
          icon: Icons.add,
        ),
      ),
    );
  }
}
