import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/utils/fab_scroll_padding.dart';
import 'package:d_una_app/shared/widgets/empty_list_state.dart';
import 'package:d_una_app/shared/widgets/paginated_list_view.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../providers/delivery_notes_providers.dart';
import '../widgets/delivery_note_card.dart';
import '../delivery_note_selection_actions.dart';
import '../../create_delivery_note/providers/create_delivery_note_provider.dart';

class DeliveryNotesListScreen extends ConsumerStatefulWidget {
  const DeliveryNotesListScreen({super.key});

  @override
  ConsumerState<DeliveryNotesListScreen> createState() =>
      _DeliveryNotesListScreenState();
}

class _DeliveryNotesListScreenState extends ConsumerState<DeliveryNotesListScreen>
    with WidgetsBindingObserver {
  SortOption _currentSort = SortOption.recent;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(paginatedDeliveryNotesProvider.notifier).refresh();
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
    final paginatedAsync = ref.watch(paginatedDeliveryNotesProvider);
    final selection = ref.watch(deliveryNotesSelectionProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    final allNotes = paginatedAsync.valueOrNull?.items ?? [];
    final selectedNotes = allNotes
        .where((n) => selection.selectedIds.contains(n.id))
        .toList();

    final isAllArchived =
        selectedNotes.isNotEmpty && selectedNotes.every((n) => n.isArchived);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Normal o Selección)
            selection.isSelectionMode
                ? _buildSelectionHeader(
                    context,
                    ref,
                    selection,
                    allNotes,
                    isAllArchived,
                  )
                : _buildNormalHeader(context, ref, userProfileAsync),
            const SizedBox(height: 16),

            // 2. Search Bar
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
                  context.push('/delivery-notes/search');
                },
              ),
            ),
            const SizedBox(height: 16),

            // 3. Sort Selector
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
                      ref
                          .read(paginatedDeliveryNotesProvider.notifier)
                          .setSortOption(val);
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

            // 4. Lista paginada de Notas de Entrega
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userProfileProvider);
                  await ref
                      .read(paginatedDeliveryNotesProvider.notifier)
                      .refresh();
                },
                child: Builder(
                  builder: (context) {
                    final state = paginatedAsync.valueOrNull;

                    if (paginatedAsync.isLoading && state == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (paginatedAsync.hasError && (state == null || state.items.isEmpty)) {
                      return FriendlyErrorWidget(
                        error: paginatedAsync.error!,
                        onRetry: () => ref
                            .read(paginatedDeliveryNotesProvider.notifier)
                            .refresh(),
                      );
                    }

                    if (state == null || state.isInitialLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = state.items;

                    if (items.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: const EmptyListState(
                            icon: Symbols.list_alt,
                            message: 'No hay notas de entrega registradas',
                          ),
                        ),
                      );
                    }

                    return PaginatedListView<DeliveryNoteModel>(
                      items: items,
                      isLoadingMore: state.isLoadingMore,
                      hasReachedEnd: state.hasReachedEnd,
                      onLoadMore: () => ref
                          .read(paginatedDeliveryNotesProvider.notifier)
                          .loadMore(),
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        8,
                        0,
                        FabScrollPadding.list,
                      ),
                      separatorBuilder: (context, index) =>
                          const Divider(height: 0, color: Colors.transparent),
                      itemBuilder: (context, index, note) {
                        final isSelected = selection.isSelected(note.id);
                        return DeliveryNoteCard(
                          note: note,
                          isSelectionMode: selection.isSelectionMode,
                          isSelected: isSelected,
                          onLongPress: () {
                            if (!selection.isSelectionMode) {
                              ref
                                  .read(deliveryNotesSelectionProvider.notifier)
                                  .enterSelectionMode(note.id);
                            }
                          },
                          onTap: () {
                            if (selection.isSelectionMode) {
                              ref
                                  .read(deliveryNotesSelectionProvider.notifier)
                                  .toggle(note.id);
                            } else {
                              context.push('/delivery-notes/view/${note.id}');
                            }
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
          : CustomExtendedFab(
              onPressed: () {
                ref.read(createDeliveryNoteProvider.notifier).reset();
                context.push('/delivery-notes/create');
              },
              label: 'Nueva',
              icon: Icons.add,
            ),
    );
  }

  Widget _buildNormalHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> userProfileAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/quotes');
              }
            },
          ),
          const SizedBox(width: 8),
          Text(
            'Notas de entrega',
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
    DeliveryNotesSelectionState selection,
    List<DeliveryNoteModel> allNotes,
    bool isAllArchived,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => ref
                .read(deliveryNotesSelectionProvider.notifier)
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
            onPressed: () async {
              await ref
                  .read(paginatedDeliveryNotesProvider.notifier)
                  .batchArchive(selection.selectedIds.toList(), !isAllArchived);
              ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Más acciones',
            onPressed: () => DeliveryNoteSelectionActions.showActionsSheet(
              context,
              ref,
              selection,
              allNotes,
            ),
          ),
        ],
      ),
    );
  }
}
