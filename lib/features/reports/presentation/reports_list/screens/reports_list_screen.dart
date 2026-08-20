import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../features/profile/domain/models/user_profile.dart';
import '../../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../shared/widgets/user_profile_avatar.dart';
import '../../../../../shared/widgets/empty_list_state.dart';
import '../../../../../shared/widgets/paginated_list_view.dart';
import '../../../../../shared/widgets/friendly_error_widget.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../providers/reports_provider.dart';
import '../widgets/service_report_card.dart';
import '../report_selection_actions.dart';
import '../../create_report/providers/create_report_provider.dart';
import '../../../domain/models/service_report_model.dart';

class ReportsListScreen extends ConsumerStatefulWidget {
  const ReportsListScreen({super.key});

  @override
  ConsumerState<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends ConsumerState<ReportsListScreen>
    with WidgetsBindingObserver {
  SortOption _currentSort = SortOption.recent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(paginatedReportsListProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final userProfileAsync = ref.watch(userProfileProvider);
    final selection = ref.watch(reportSelectionProvider);
    final paginatedStateAsync = ref.watch(paginatedReportsListProvider);

    final allReports = paginatedStateAsync.valueOrNull?.items ?? [];
    final isError = paginatedStateAsync.hasError || userProfileAsync.hasError;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            selection.isSelectionMode
                ? _buildSelectionHeader(context, ref, selection, allReports)
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
                    context.push('/reports/search');
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
                        String orderBy = 'service_date';
                        bool ascending = false;
                        if (val == SortOption.recent) {
                          orderBy = 'service_date';
                          ascending = false;
                        } else if (val == SortOption.oldest) {
                          orderBy = 'service_date';
                          ascending = true;
                        } else if (val == SortOption.highestPrice) {
                          orderBy = 'total';
                          ascending = false;
                        } else if (val == SortOption.lowestPrice) {
                          orderBy = 'total';
                          ascending = true;
                        }
                        ref
                            .read(paginatedReportsListProvider.notifier)
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
              const SizedBox(height: 16),
            ],
            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userProfileProvider);
                  await ref
                      .read(paginatedReportsListProvider.notifier)
                      .refresh();
                },
                child: userProfileAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => FriendlyErrorWidget(
                    error: err,
                    onRetry: () {
                      ref.invalidate(userProfileProvider);
                      ref.read(paginatedReportsListProvider.notifier).refresh();
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
                            .read(paginatedReportsListProvider.notifier)
                            .refresh(),
                      );
                    }

                    if (paginatedState.items.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: const EmptyListState(
                            icon: Icons.assignment_outlined,
                            message:
                                'No hay reportes de servicios registrados.',
                          ),
                        ),
                      );
                    }

                    return PaginatedListView<ServiceReportSummary>(
                      items: paginatedState.items,
                      isLoadingMore: paginatedState.isLoadingMore,
                      hasReachedEnd: paginatedState.hasReachedEnd,
                      onLoadMore: () => ref
                          .read(paginatedReportsListProvider.notifier)
                          .loadMore(),
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 90),
                      separatorBuilder: (context, index) => const Divider(
                        height: 0,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.transparent,
                      ),
                      itemBuilder: (context, index, item) {
                        return ServiceReportCard(
                          report: item,
                          isSelectionMode: selection.isSelectionMode,
                          isSelected: selection.isSelected(item.id),
                          onLongPress: () => ref
                              .read(reportSelectionProvider.notifier)
                              .toggle(item.id),
                          onTap: selection.isSelectionMode
                              ? () => ref
                                    .read(reportSelectionProvider.notifier)
                                    .toggle(item.id)
                              : () => context.push('/reports/${item.id}'),
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
                  ref.read(createReportProvider.notifier).reset();
                  context.push('/reports/create');
                },
                icon: Icons.add,
                label: 'Nuevo',
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
            'Reportes de servicio',
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
    ReportSelectionState selection,
    List<ServiceReportSummary> allReports,
  ) {
    final selectedReports = allReports
        .where((r) => selection.selectedIds.contains(r.id))
        .toList();
    final isAllArchived =
        selectedReports.isNotEmpty &&
        selectedReports.every((r) => r.isArchived);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => ref.read(reportSelectionProvider.notifier).clear(),
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
            onPressed: () => ReportSelectionActions.handleBatchArchive(
              context,
              ref,
              selection,
              archive: !isAllArchived,
            ),
          ),
          IconButton(
            icon: const Icon(Symbols.conversion_path),
            tooltip: 'Cambiar estatus',
            onPressed: () => ReportSelectionActions.showStatusDialog(
              context,
              ref,
              selection,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => ReportSelectionActions.showActionsSheet(
              context,
              ref,
              selection,
              allReports,
            ),
          ),
        ],
      ),
    );
  }
}
