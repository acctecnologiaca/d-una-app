import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';

import 'package:d_una_app/features/purchases/presentation/providers/purchases_providers.dart';
import '../widgets/purchase_list_item.dart';
import '../../../../shared/widgets/empty_list_state.dart';
import '../../../../shared/widgets/paginated_list_view.dart';

class PurchasesListScreen extends ConsumerStatefulWidget {
  const PurchasesListScreen({super.key});

  @override
  ConsumerState<PurchasesListScreen> createState() =>
      _PurchasesListScreenState();
}

class _PurchasesListScreenState extends ConsumerState<PurchasesListScreen> {
  SortOption _currentSort = SortOption.recent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final productId = GoRouterState.of(
      context,
    ).uri.queryParameters['productId'];

    // Note: If productId is present, we might still want to use the FutureProvider
    // or pass it to PaginatedPurchasesList. For this refactor, we use paginated list.
    final paginatedAsync = ref.watch(paginatedPurchasesListProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: StandardAppBar(
        title: productId != null
            ? 'Compras del producto'
            : 'Registro de compras',
      ),
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
              hintText: 'Buscar...',
              readOnly: true,
              showFilterIcon: true,
              onTap: () => context.push('/my-purchases/search'),
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
                    String orderBy = 'date';
                    bool ascending = false;
                    if (val == SortOption.oldest) {
                      ascending = true;
                    } else if (val == SortOption.highestPrice) {
                      orderBy = 'subtotal';
                      ascending = false;
                    } else if (val == SortOption.lowestPrice) {
                      orderBy = 'subtotal';
                      ascending = true;
                    }
                    ref
                        .read(paginatedPurchasesListProvider.notifier)
                        .updateSort(orderBy, ascending);
                  },
                  options: const [
                    SortOption.recent,
                    SortOption.oldest,
                    SortOption.highestPrice,
                    SortOption.lowestPrice,
                  ],
                ),
              ],
            ),
          ),

          // Purchases List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(paginatedPurchasesListProvider.notifier)
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
                          .read(paginatedPurchasesListProvider.notifier)
                          .refresh(),
                    );
                  }

                  if (state.items.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: const EmptyListState(
                          icon: Icons.receipt_long,
                          message: 'No tienes compras registradas',
                        ),
                      ),
                    );
                  }

                  return PaginatedListView(
                    items: state.items,
                    isLoadingMore: state.isLoadingMore,
                    hasReachedEnd: state.hasReachedEnd,
                    onLoadMore: () => ref
                        .read(paginatedPurchasesListProvider.notifier)
                        .loadMore(),
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 90),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 0, color: Colors.transparent),
                    itemBuilder: (context, index, purchase) {
                      return PurchaseListItem(
                        purchase: purchase,
                        onTap: () {
                          context.push('/my-purchases/view/${purchase.id}');
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
            ref.read(addPurchaseProvider.notifier).reset();
            context.push('/my-purchases/add');
          },
          label: 'Registrar',
          icon: Icons.post_add,
        ),
      ),
    );
  }
}
