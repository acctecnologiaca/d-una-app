import 'package:d_una_app/features/profile/domain/models/user_profile.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/widgets/quote_card.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../features/profile/presentation/providers/profile_provider.dart';
import '../providers/quotes_provider.dart';
import '../../../../../shared/widgets/friendly_error_widget.dart';
import '../../create_quote/providers/create_quote_provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../shared/widgets/user_profile_avatar.dart';
import '../../../../../shared/widgets/empty_list_state.dart';
import '../../../../../shared/widgets/paginated_list_view.dart';
import '../quote_selection_actions.dart';
import '../../../domain/models/quote_model.dart';

class QuotesListScreen extends ConsumerStatefulWidget {
  const QuotesListScreen({super.key});

  @override
  ConsumerState<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends ConsumerState<QuotesListScreen> {
  SortOption _currentSort = SortOption.recent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final userProfileAsync = ref.watch(userProfileProvider);
    final selection = ref.watch(quoteSelectionProvider);
    final paginatedStateAsync = ref.watch(paginatedQuotesListProvider);

    final allQuotes = paginatedStateAsync.valueOrNull?.items ?? [];
    final isError = paginatedStateAsync.hasError || userProfileAsync.hasError;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            selection.isSelectionMode
                ? _buildSelectionHeader(context, ref, selection, allQuotes)
                : _buildNormalHeader(context, ref, userProfileAsync, isError),
            const SizedBox(height: 16),

            if (!isError) ...[
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: CustomSearchBar(
                  hintText: 'Buscar...',
                  readOnly: true,
                  showFilterIcon: true,
                  onFilterTap: () {},
                  onTap: () {
                    context.push('/quotes/search');
                  },
                ),
              ),
              const SizedBox(height: 16),
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
                        String orderBy = 'date_issued';
                        bool ascending = false;
                        if (val == SortOption.recent || val == SortOption.frequency) {
                          orderBy = 'created_at';
                          ascending = false;
                        } else if (val == SortOption.dateIssued) {
                          orderBy = 'date_issued';
                          ascending = false;
                        } else if (val == SortOption.nameAZ) {
                          orderBy = 'clients(name)'; // Not possible out of the box in RPC but let's assume local handled or ignored if not supported
                          ascending = true;
                        } else if (val == SortOption.nameZA) {
                          orderBy = 'clients(name)';
                          ascending = false;
                        }
                        ref.read(paginatedQuotesListProvider.notifier).updateSort(orderBy, ascending);
                      },
                      options: const [
                        SortOption.recent,
                        SortOption.dateIssued,
                        SortOption.nameAZ,
                        SortOption.nameZA,
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userProfileProvider);
                  await ref.read(paginatedQuotesListProvider.notifier).refresh();
                },
                child: userProfileAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => FriendlyErrorWidget(
                    error: err,
                    onRetry: () {
                      ref.invalidate(userProfileProvider);
                      ref.read(paginatedQuotesListProvider.notifier).refresh();
                    },
                  ),
                  data: (_) {
                    final paginatedState = paginatedStateAsync.valueOrNull;
                    if (paginatedState == null || paginatedState.isInitialLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (paginatedStateAsync.hasError && paginatedState.items.isEmpty) {
                      return FriendlyErrorWidget(
                        error: paginatedStateAsync.error!,
                        onRetry: () => ref.read(paginatedQuotesListProvider.notifier).refresh(),
                      );
                    }

                    if (paginatedState.items.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: EmptyListState(
                            icon: Icons.description_outlined,
                            message: 'No hay cotizaciones registradas.',
                          ),
                        ),
                      );
                    }

                    return PaginatedListView(
                      items: paginatedState.items,
                      isLoadingMore: paginatedState.isLoadingMore,
                      hasReachedEnd: paginatedState.hasReachedEnd,
                      onLoadMore: () => ref.read(paginatedQuotesListProvider.notifier).loadMore(),
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 90),
                      separatorBuilder: (context, index) => const Divider(
                        height: 0,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.transparent,
                      ),
                      itemBuilder: (context, index, item) {
                        return QuoteCard(
                          quote: item,
                          isSelectionMode: selection.isSelectionMode,
                          isSelected: selection.isSelected(item.id),
                          onLongPress: () => ref
                              .read(quoteSelectionProvider.notifier)
                              .toggle(item.id),
                          onTap: selection.isSelectionMode
                              ? () => ref
                                    .read(quoteSelectionProvider.notifier)
                                    .toggle(item.id)
                              : () => context.push(
                                  '/quotes/view/${item.id}',
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
      floatingActionButton: selection.isSelectionMode || isError
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: CustomExtendedFab(
                onPressed: () {
                  ref.invalidate(createQuoteProvider);
                  context.push('/quotes/create');
                },
                icon: Icons.add,
                label: 'Nueva',
              ),
            ),
    );
  }

  Widget _buildNormalHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<UserProfile?> userProfileAsync,
    bool isError,
  ) {
    return Padding(
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
            'Cotizaciones',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          UserProfileAvatar(enabled: !isError),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
    List<Quote> allQuotes,
  ) {
    final selectedQuotes = allQuotes
        .where((q) => selection.selectedIds.contains(q.id))
        .toList();
    final isAllArchived = selectedQuotes.isNotEmpty &&
        selectedQuotes.every((q) => q.isArchived);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                ref.read(quoteSelectionProvider.notifier).clearSelection(),
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
            icon: Icon(isAllArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
            tooltip: isAllArchived ? 'Desarchivar' : 'Archivar',
            onPressed: () => _handleBatchArchive(
              context,
              ref,
              selection,
              archive: !isAllArchived,
            ),
          ),
          IconButton(
            icon: const Icon(Symbols.conversion_path),
            tooltip: 'Cambiar estatus',
            onPressed: () => _showStatusDialog(context, ref, selection),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showActionsSheet(context, ref, selection, allQuotes),
          ),
        ],
      ),
    );
  }

  void _showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
    List<Quote> allQuotes,
  ) {
    QuoteSelectionActions.showActionsSheet(context, ref, selection, allQuotes);
  }

  Future<void> _showStatusDialog(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
  ) async {
    await QuoteSelectionActions.showStatusDialog(context, ref, selection);
  }

  Future<void> _handleBatchArchive(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection, {
    bool archive = true,
  }) async {
    await QuoteSelectionActions.handleBatchArchive(
      context,
      ref,
      selection,
      archive: archive,
    );
  }
}
