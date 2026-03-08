import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../shared/widgets/standard_list_item.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../providers/quote_service_selection_provider.dart';
import '../providers/create_quote_provider.dart';
import '../widgets/quote_service_sale_details_sheet.dart';

class SelectServiceScreen extends ConsumerStatefulWidget {
  const SelectServiceScreen({super.key});

  @override
  ConsumerState<SelectServiceScreen> createState() =>
      _SelectServiceScreenState();
}

class _SelectServiceScreenState extends ConsumerState<SelectServiceScreen> {
  SortOption _currentSort = SortOption.recent;

  String _getRateSuffix(String? rateName) {
    if (rateName == null) return '/ud.';
    final lower = rateName.toLowerCase();
    if (lower.contains('hora') || lower.contains('h')) return '/h';
    if (lower.contains('día') || lower.contains('dia')) return '/dia';
    if (lower.contains('mes')) return '/mes';
    if (lower.contains('serv')) return '/serv.';
    return '/ud.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final suggestionsAsync = ref.watch(quoteServiceSuggestionsProvider);

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Agregar servicio',
        subtitle: 'Cotización #C-00000011', // Should be dynamic
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar (Read-only -> Navigates to Search)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: InkWell(
              onTap: () {
                context.push('/quotes/create/select-service/search').then((
                  result,
                ) {
                  if (result == true) {
                    if (context.mounted) {
                      context.pop();
                    }
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: IgnorePointer(
                child: CustomSearchBar(
                  hintText: 'Buscar servicio...',
                  onChanged: (_) {}, // No-op, handled by onTap
                  readOnly: true,
                  showFilterIcon: true,
                ),
              ),
            ),
          ),

          // 2. Add Temporal Service Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              onPressed: () {
                context
                    .push('/quotes/create/select-service/temporal-service')
                    .then((result) {
                      if (result == true && context.mounted) {
                        context.pop(); // Go back to create quote if added
                      }
                    });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: colors.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                foregroundColor: colors.onSurface,
              ),
              child: const Text(
                'Agregar servicio temporal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // 3. Disclaimer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Precios no incluyen impuesto',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ),

          // 4. Sort Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SortSelector(
                  currentSort: _currentSort,
                  onSortChanged: (val) => setState(() => _currentSort = val),
                ),
              ],
            ),
          ),

          // 5. List
          Expanded(
            child: suggestionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: \$err')),
              data: (services) {
                // Determine sort list
                final sortedServices = List.of(services);
                sortedServices.sort((a, b) {
                  switch (_currentSort) {
                    case SortOption.recent:
                    case SortOption.frequency:
                      return b.createdAt.compareTo(
                        a.createdAt,
                      ); // Default to recent
                    case SortOption.nameAZ:
                      return a.name.toLowerCase().compareTo(
                        b.name.toLowerCase(),
                      );
                    case SortOption.nameZA:
                      return b.name.toLowerCase().compareTo(
                        a.name.toLowerCase(),
                      );
                    default:
                      return 0;
                  }
                });

                if (sortedServices.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay servicios disponibles',
                      style: TextStyle(color: colors.outline),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedServices.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Colors.transparent),
                  itemBuilder: (context, index) {
                    final service = sortedServices[index];
                    return StandardListItem(
                      onTap: () async {
                        final addedService =
                            await QuoteServiceSaleDetailsSheet.show(
                              context,
                              service: service,
                            );

                        if (addedService != null) {
                          ref
                              .read(createQuoteProvider.notifier)
                              .addService(addedService);
                          if (context.mounted) {
                            context.pop();
                          }
                        }
                      },
                      title: service.name,
                      subtitle: Text(service.category?.name ?? 'Sin categoría'),
                      trailing: Text(
                        '${CurrencyFormatter.format(service.price)}${_getRateSuffix(service.serviceRate?.name)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
