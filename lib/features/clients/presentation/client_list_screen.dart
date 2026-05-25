import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'providers/clients_provider.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'providers/add_client_provider.dart';
import '../../../../shared/widgets/friendly_error_widget.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../shared/widgets/sort_selector.dart';
import '../../../shared/widgets/custom_extended_fab.dart';
import '../../../shared/widgets/standard_list_item.dart';
import '../../../shared/widgets/user_profile_avatar.dart';
import '../../../../shared/widgets/empty_list_state.dart';
import '../../../../shared/widgets/paginated_list_view.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  SortOption _currentSort = SortOption.recent;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paginatedStateAsync = ref.watch(paginatedClientsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final colors = Theme.of(context).colorScheme;

    final isError = paginatedStateAsync.hasError || userProfileAsync.hasError;

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar Row (Always visible)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: isError
                        ? null
                        : () {
                            Scaffold.of(context).openDrawer();
                          },
                  ),
                  Text(
                    'Clientes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  UserProfileAvatar(enabled: !isError),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!isError) ...[
              // Search Bar
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
                    context.push('/clients/search');
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Sort Options Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    SortSelector(
                      currentSort: _currentSort,
                      options: const [
                        SortOption.recent,
                        SortOption.nameAZ,
                        SortOption.nameZA,
                        SortOption.type,
                      ],
                      onSortChanged: (val) {
                        setState(() => _currentSort = val);
                        // Map SortOption to API fields
                        String orderBy = 'created_at';
                        bool ascending = false;
                        if (val == SortOption.nameAZ) {
                          orderBy = 'name';
                          ascending = true;
                        } else if (val == SortOption.nameZA) {
                          orderBy = 'name';
                          ascending = false;
                        } else if (val == SortOption.type) {
                          orderBy = 'type';
                          ascending = true;
                        }
                        ref
                            .read(paginatedClientsProvider.notifier)
                            .updateSort(orderBy, ascending);
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userProfileProvider);
                  await ref.read(paginatedClientsProvider.notifier).refresh();
                },
                child: userProfileAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => FriendlyErrorWidget(
                    error: err,
                    onRetry: () {
                      ref.invalidate(userProfileProvider);
                      ref.invalidate(clientsProvider);
                    },
                  ),
                  data: (_) {
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
                            .read(paginatedClientsProvider.notifier)
                            .refresh(),
                      );
                    }

                    if (paginatedState.items.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: EmptyListState(
                            icon: Symbols.people,
                            message: 'No hay clientes agregados',
                          ),
                        ),
                      );
                    }

                    return PaginatedListView(
                      items: paginatedState.items,
                      isLoadingMore: paginatedState.isLoadingMore,
                      hasReachedEnd: paginatedState.hasReachedEnd,
                      onLoadMore: () => ref
                          .read(paginatedClientsProvider.notifier)
                          .loadMore(),
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 90),
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.transparent,
                      ),
                      itemBuilder: (context, index, client) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: StandardListItem(
                            leading: Icon(
                              client.type == 'company'
                                  ? Icons.domain_outlined
                                  : Icons.person_outlined,
                              size: 32,
                              color: colors.onSurfaceVariant,
                            ),
                            title: client.name,
                            subtitle: Text(client.taxId ?? 'Sin ID'),
                            onTap: () {
                              context.push(
                                '/clients/${client.id}',
                                extra: client,
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
      ),
      floatingActionButton: isError
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: CustomExtendedFab(
                onPressed: () {
                  // Reset provider state before starting new wizard
                  ref.read(addClientProvider.notifier).reset();
                  context.push('/clients/add?returnTo=/clients');
                },
                label: 'Agregar',
                icon: Icons.add,
              ),
            ),
    );
  }
}
