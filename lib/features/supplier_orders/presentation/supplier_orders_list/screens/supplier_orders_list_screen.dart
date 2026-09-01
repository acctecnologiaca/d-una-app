import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/empty_list_state.dart';
import 'package:d_una_app/shared/widgets/paginated_list_view.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/features/profile/domain/models/user_profile.dart';
import '../providers/supplier_orders_providers.dart';
import '../providers/supplier_orders_selection_provider.dart';
import '../supplier_order_selection_actions.dart';
import '../../create_supplier_order/providers/create_supplier_order_provider.dart';
import '../widgets/supplier_order_card.dart';
import '../../../domain/models/supplier_order_status.dart';

class SupplierOrdersListScreen extends ConsumerStatefulWidget {
  const SupplierOrdersListScreen({super.key});

  @override
  ConsumerState<SupplierOrdersListScreen> createState() =>
      _SupplierOrdersListScreenState();
}

class _SupplierOrdersListScreenState
    extends ConsumerState<SupplierOrdersListScreen>
    with WidgetsBindingObserver {
  SortOption _currentSort = SortOption.orderNumberDesc;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(paginatedSupplierOrdersProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final paginatedAsync = ref.watch(paginatedSupplierOrdersProvider);
    final selection = ref.watch(supplierOrderSelectionProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    final allOrders = paginatedAsync.valueOrNull?.items ?? [];
    final selectedOrders = allOrders
        .where((o) => selection.selectedIds.contains(o.id))
        .toList();

    final canSendBatch =
        selection.count > 0 &&
        selection.count <= 3 &&
        selectedOrders.every(
          (o) =>
              o.status != SupplierOrderStatus.approved &&
              o.status != SupplierOrderStatus.rejected &&
              o.status != SupplierOrderStatus.finalized &&
              o.status != SupplierOrderStatus.cancelled &&
              o.status != SupplierOrderStatus.merged,
        );

    final isSingleResend =
        selectedOrders.length == 1 &&
        (selectedOrders.first.status == SupplierOrderStatus.sent ||
            selectedOrders.first.status == SupplierOrderStatus.resent);

    final isAllArchived =
        selectedOrders.isNotEmpty && selectedOrders.every((o) => o.isArchived);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            selection.isSelectionMode
                ? _buildSelectionHeader(
                    context,
                    ref,
                    selection,
                    canSendBatch,
                    isSingleResend,
                    isAllArchived,
                  )
                : _buildNormalHeader(context, ref, userProfileAsync),
            const SizedBox(height: 16),

            // Search & Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: CustomSearchBar(
                controller: _searchController,
                hintText: 'Buscar...',
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
                    options: const [
                      SortOption.orderNumberDesc,
                      SortOption.orderNumberAsc,
                      SortOption.recent,
                      SortOption.nameAZ,
                      SortOption.nameZA,
                    ],
                  ),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userProfileProvider);
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
                    // Local sorting according to selected option
                     if (_currentSort == SortOption.orderNumberDesc) {
                      items = List.from(items)
                        ..sort((a, b) => b.orderNumber.compareTo(a.orderNumber));
                    } else if (_currentSort == SortOption.orderNumberAsc) {
                      items = List.from(items)
                        ..sort((a, b) => a.orderNumber.compareTo(b.orderNumber));
                    } else if (_currentSort == SortOption.recent) {
                      items = List.from(items)
                        ..sort((a, b) => b.date.compareTo(a.date));
                    } else if (_currentSort == SortOption.nameAZ) {
                      items = List.from(items)
                        ..sort(
                          (a, b) => a.supplierName.toLowerCase().compareTo(
                            b.supplierName.toLowerCase(),
                          ),
                        );
                    } else if (_currentSort == SortOption.nameZA) {
                      items = List.from(items)
                        ..sort(
                          (a, b) => b.supplierName.toLowerCase().compareTo(
                            a.supplierName.toLowerCase(),
                          ),
                        );
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
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
                      separatorBuilder: (context, index) =>
                          const Divider(height: 0, color: Colors.transparent),
                      itemBuilder: (context, index, order) {
                        return SupplierOrderCard(
                          order: order,
                          isSelectionMode: selection.isSelectionMode,
                          isSelected: selection.isSelected(order.id),
                          onLongPress: () => ref
                              .read(supplierOrderSelectionProvider.notifier)
                              .toggle(order.id),
                          onTap: selection.isSelectionMode
                              ? () => ref
                                    .read(
                                      supplierOrderSelectionProvider.notifier,
                                    )
                                    .toggle(order.id)
                              : () {
                                  context.push(
                                    '/supplier-orders/view/${order.id}',
                                  );
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
      ),
      floatingActionButton: selection.isSelectionMode
          ? null
          : Padding(
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

  Widget _buildNormalHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<UserProfile?> userProfileAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.pop();
            },
          ),
          const SizedBox(width: 8),
          Text(
            'Órdenes de compra',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader(
    BuildContext context,
    WidgetRef ref,
    SupplierOrderSelectionState selection,
    bool canSendBatch,
    bool isSingleResend,
    bool isAllArchived,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => ref
                .read(supplierOrderSelectionProvider.notifier)
                .clearSelection(),
          ),
          Text(
            '${selection.count} Ítem${selection.count > 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isAllArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
            ),
            tooltip: isAllArchived ? 'Desarchivar' : 'Archivar',
            onPressed: () => SupplierOrderSelectionActions.handleBatchArchive(
              context,
              ref,
              selection,
              archive: !isAllArchived,
            ),
          ),
          IconButton(
            icon: Icon(isSingleResend ? Symbols.forward : Icons.send),
            tooltip: isSingleResend ? 'Reenviar' : 'Enviar',
            onPressed: canSendBatch
                ? () => SupplierOrderSelectionActions.handleBatchSend(
                    context,
                    ref,
                    selection,
                  )
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => SupplierOrderSelectionActions.showActionsSheet(
              context,
              ref,
              selection,
            ),
          ),
        ],
      ),
    );
  }
}
