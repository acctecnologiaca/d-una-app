import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../data/models/service_model.dart';
import '../../providers/services_provider.dart';
import '../../../../../shared/widgets/service_list_item.dart';
import '../widgets/service_action_sheet.dart';
import '../../../../../shared/widgets/empty_list_state.dart';
import '../../../../../shared/widgets/paginated_list_view.dart';

class OwnServicesScreen extends ConsumerStatefulWidget {
  const OwnServicesScreen({super.key});

  @override
  ConsumerState<OwnServicesScreen> createState() => _OwnServicesScreenState();
}

class _OwnServicesScreenState extends ConsumerState<OwnServicesScreen> {
  SortOption _currentSort = SortOption.recent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final paginatedAsync = ref.watch(paginatedServicesProvider);

    final isError = paginatedAsync.hasError;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios propios'),
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
          if (!isError) ...[
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: CustomSearchBar(
                hintText: 'Buscar servicio...',
                readOnly: true,
                showFilterIcon: true,
                onTap: () {
                  context.push('/portfolio/own-services/search');
                },
              ),
            ),

            // Disclaimer
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Precios no incluyen impuesto',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ),

            // Sort Header
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
                      }
                      ref.read(paginatedServicesProvider.notifier).updateSort(orderBy, ascending);
                    },
                    options: const [
                      SortOption.recent,
                      SortOption.nameAZ,
                      SortOption.nameZA,
                    ],
                  ),
                ],
              ),
            ),
          ],

          Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(paginatedServicesProvider.notifier).refresh();
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
                        onRetry: () => ref.read(paginatedServicesProvider.notifier).refresh(),
                      );
                    }

                    if (state.items.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: const EmptyListState(
                            icon: Icons.handyman_outlined,
                            message: 'No tienes servicios registrados',
                          ),
                        ),
                      );
                    }

                    return PaginatedListView(
                      items: state.items,
                      isLoadingMore: state.isLoadingMore,
                      hasReachedEnd: state.hasReachedEnd,
                      onLoadMore: () => ref.read(paginatedServicesProvider.notifier).loadMore(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Colors.transparent),
                      itemBuilder: (context, index, service) {
                        return ServiceListItem(
                          service: service,
                          onTap: () {
                            _showServiceActionSheet(context, service);
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
      floatingActionButton: isError
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: CustomExtendedFab(
                onPressed: () {
                  // Navigate to Add Service Wizard
                  context.push('/portfolio/own-services/add');
                },
                label: 'Agregar',
                icon: Icons.add,
              ),
            ),
    );
  }

  void _showServiceActionSheet(BuildContext context, ServiceModel service) {
    ServiceActionSheet.show(context, service);
  }
}
