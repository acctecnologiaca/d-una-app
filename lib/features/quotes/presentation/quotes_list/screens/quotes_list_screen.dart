import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../features/profile/presentation/providers/profile_provider.dart';
//import '../../../domain/models/quote_model.dart'; // New Import
import '../widgets/quote_card.dart'; // New Import
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../providers/quotes_provider.dart';
import '../../../../../shared/widgets/friendly_error_widget.dart';

class QuotesListScreen extends ConsumerStatefulWidget {
  const QuotesListScreen({super.key});

  @override
  ConsumerState<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends ConsumerState<QuotesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  SortOption _currentSort = SortOption.recent;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
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
                  InkWell(
                    onTap: () => context.push('/profile'),
                    child: userProfileAsync.when(
                      data: (profile) {
                        final avatarUrl = profile?.avatarUrl;
                        return CircleAvatar(
                          radius: 18,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : const NetworkImage(
                                  'https://i.pravatar.cc/150?img=12',
                                ),
                        );
                      },
                      loading: () => const CircleAvatar(
                        radius: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, stack) => const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=12',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                    onSortChanged: (val) => setState(() => _currentSort = val),
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

            // List
            Expanded(
              child: ref
                  .watch(quotesListProvider)
                  .when(
                    data: (items) {
                      // Filter Logic (Search)
                      var filteredItems = items.where((quote) {
                        final query = _searchController.text.toLowerCase();
                        if (query.isEmpty) return true;
                        return quote.clientName.toLowerCase().contains(query) ||
                            quote.quoteNumber.toLowerCase().contains(query);
                      }).toList();

                      // Sort Logic
                      filteredItems.sort((a, b) {
                        switch (_currentSort) {
                          case SortOption.recent:
                          case SortOption.frequency:
                            return b.createdAt.compareTo(a.createdAt);
                          case SortOption.dateIssued:
                            return b.date.compareTo(a.date);
                          case SortOption.nameAZ:
                            return a.clientName.compareTo(b.clientName);
                          case SortOption.nameZA:
                            return b.clientName.compareTo(a.clientName);
                          default:
                            return 0;
                        }
                      });

                      if (filteredItems.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'No hay cotizaciones registradas.'
                                    : 'No se encontraron resultados.',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(quotesListProvider.notifier).refresh(),
                        child: ListView.separated(
                          //padding: const EdgeInsets.symmetric(horizontal: 0),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 0,
                            indent: 16,
                            endIndent: 16,
                            color: Colors.transparent,
                          ),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return QuoteCard(
                              quote: item,
                              onTap: () {
                                context.push('/quotes/view/${item.id}');
                              },
                            );
                          },
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => FriendlyErrorWidget(
                      error: err,
                      onRetry: () =>
                          ref.read(quotesListProvider.notifier).refresh(),
                    ),
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: CustomExtendedFab(
          onPressed: () {
            context.push('/quotes/create');
          },
          icon: Icons.add,
          label: 'Nueva',
        ),
      ),
    );
  }
}
