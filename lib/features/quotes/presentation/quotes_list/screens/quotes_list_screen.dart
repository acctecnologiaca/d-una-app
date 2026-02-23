import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../domain/models/quote_model.dart'; // New Import
import '../widgets/quote_card.dart'; // New Import

class QuotesListScreen extends ConsumerStatefulWidget {
  const QuotesListScreen({super.key});

  @override
  ConsumerState<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends ConsumerState<QuotesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  SortOption _currentSort = SortOption.recent;

  // Mock Data
  final List<Quote> _items = [
    Quote(
      id: '1',
      quoteNumber: '#C-00000010',
      clientName: 'Corporación Telemic, C.A.',
      date: DateTime(2025, 10, 6),
      amount: 2750.00,
      status: QuoteStatus.draft,
      stockStatus: StockStatus.available,
    ),
    Quote(
      id: '2',
      quoteNumber: '#C-00000009',
      clientName: 'ACC Tecnología, C.A.',
      date: DateTime(2025, 10, 2),
      amount: 150.00,
      status: QuoteStatus.rejected,
      stockStatus: StockStatus.unavailable,
    ),
    Quote(
      id: '3',
      quoteNumber: '#C-00000008',
      clientName: 'Agrovivar, C.A.',
      date: DateTime(2025, 10, 1),
      amount: 755.00,
      status: QuoteStatus.sent,
      stockStatus: StockStatus.available,
    ),
    Quote(
      id: '4',
      quoteNumber: '#C-00000007',
      clientName: 'Cauchos ND, C.A.',
      date: DateTime(2025, 9, 30),
      amount: 560.00,
      status: QuoteStatus.inReview, // mapped 'viewed' to 'inReview' or similar
      stockStatus: StockStatus.unavailable,
      isArchived: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final userProfileAsync = ref.watch(userProfileProvider);

    // Filter Logic (Search)
    var filteredItems = _items.where((quote) {
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
          return b.date.compareTo(a.date);
        case SortOption.nameAZ:
          return a.clientName.compareTo(b.clientName);
        case SortOption.nameZA:
          return b.clientName.compareTo(a.clientName);
      }
    });

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
                  IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
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
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredItems.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.transparent,
                ),
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return QuoteCard(
                    quote: item,
                    onTap: () {
                      // Navigate to details
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            context.push('/quotes/create');
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Nueva',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
