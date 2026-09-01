import 'package:d_una_app/shared/widgets/info_disclaimer_card.dart';
import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../providers/products_provider.dart';
import '../widgets/inventory_item_card.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
import '../widgets/inventory_action_sheet.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../../../shared/widgets/empty_list_state.dart';
import '../../../../../shared/widgets/paginated_list_view.dart';
import '../../../../ads/presentation/providers/ads_provider.dart';

class OwnInventoryScreen extends ConsumerStatefulWidget {
  const OwnInventoryScreen({super.key});

  @override
  ConsumerState<OwnInventoryScreen> createState() => _OwnInventoryScreenState();
}

class _OwnInventoryScreenState extends ConsumerState<OwnInventoryScreen> {
  SortOption _currentSort = SortOption.recent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final paginatedStateAsync = ref.watch(paginatedProductsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    final userProfile = userProfileAsync.valueOrNull;
    final occupationIds = <String>[
      if (userProfile?.occupationId != null) userProfile!.occupationId!,
      ...userProfile?.secondaryOccupationIds ?? [],
    ];

    final isAdsEnabled =
        ref.watch(isAdPlacementEnabledProvider('own_inventory_list'));
    final adBannersAsync = isAdsEnabled
        ? ref.watch(
            adBannersProvider(
              AdBannerParams(occupationIds: occupationIds),
            ),
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario propio'),
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
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
              onTap: () {
                context.push('/portfolio/own-inventory/search');
              },
            ),
          ),

          // Disclaimer (Updated text since price/stock are 0 for now)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: const InfoDisclaimerCard(
              text: 'Precios no incluyen impuestos',
              showCloseButton: true,
            ),
          ),

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
                    String orderBy = 'created_at';
                    bool ascending = false;
                    if (val == SortOption.nameAZ) {
                      orderBy = 'name';
                      ascending = true;
                    } else if (val == SortOption.nameZA) {
                      orderBy = 'name';
                      ascending = false;
                    } else if (val == SortOption.recent) {
                      orderBy = 'created_at';
                      ascending = false;
                    } else if (val == SortOption.quantityDesc) {
                      orderBy = 'inventory_quantity';
                      ascending = false;
                    } else if (val == SortOption.quantityAsc) {
                      orderBy = 'inventory_quantity';
                      ascending = true;
                    } else if (val == SortOption.highestPrice) {
                      orderBy = 'average_cost';
                      ascending = false;
                    } else if (val == SortOption.lowestPrice) {
                      orderBy = 'average_cost';
                      ascending = true;
                    }
                    ref
                        .read(paginatedProductsProvider.notifier)
                        .updateSort(orderBy, ascending);
                  },
                  options: const [
                    SortOption.recent,
                    SortOption.nameAZ,
                    SortOption.nameZA,
                    SortOption.quantityDesc,
                    SortOption.quantityAsc,
                    SortOption.highestPrice,
                    SortOption.lowestPrice,
                  ],
                ),
              ],
            ),
          ),

          // Inventory List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userProfileProvider);
                ref.read(dismissedBannerIdsProvider.notifier).state = {};
                ref.invalidate(adBannersProvider);
                await ref.read(paginatedProductsProvider.notifier).refresh();
              },
              child: Builder(
                builder: (context) {
                  final paginatedState = paginatedStateAsync.valueOrNull;
                  if (paginatedState == null ||
                      paginatedState.isInitialLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (paginatedStateAsync.hasError &&
                      paginatedState.items.isEmpty) {
                    return FriendlyErrorWidget(
                      error: paginatedStateAsync.error!,
                      onRetry: () => ref
                          .read(paginatedProductsProvider.notifier)
                          .refresh(),
                    );
                  }

                  if (paginatedState.items.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: EmptyListState(
                          icon: Icons.inventory_2_outlined,
                          message: 'No hay productos agregados a tu inventario',
                        ),
                      ),
                    );
                  }

                  return PaginatedListView(
                    items: paginatedState.items,
                    isLoadingMore: paginatedState.isLoadingMore,
                    hasReachedEnd: paginatedState.hasReachedEnd,
                    onLoadMore: () =>
                        ref.read(paginatedProductsProvider.notifier).loadMore(),
                    banners: adBannersAsync?.valueOrNull,
                    screenContext: 'own_inventory_list',
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Colors.transparent),
                    itemBuilder: (context, index, product) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: InventoryItemCard(
                          name: product.name,
                          brand: product.brand?.name ?? 'Sin marca',
                          model: product.model ?? 'Sin modelo',
                          stock: product.inventoryQuantity,
                          price: product.averageCost,
                          unit: product.uom,
                          uomIconName: product.uomModel?.iconName,
                          imageUrl: product.imageUrl,
                          onTap: () {
                            InventoryActionSheet.show(
                              context: context,
                              ref: ref,
                              product: product,
                              currentPrice: product.averageCost,
                              currentStock: product.inventoryQuantity,
                            );
                          },
                        ),
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
            context.push('/portfolio/own-inventory/add');
          },
          label: 'Agregar',
          icon: Icons.add,
        ),
      ),
    );
  }
}
