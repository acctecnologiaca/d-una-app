import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../shared/widgets/aggregated_product_card.dart';
import '../../../../portfolio/presentation/providers/product_search_provider.dart';
import '../providers/quote_product_selection_provider.dart';
import '../providers/create_quote_provider.dart';

class SelectProductScreen extends ConsumerStatefulWidget {
  const SelectProductScreen({super.key});

  @override
  ConsumerState<SelectProductScreen> createState() =>
      _SelectProductScreenState();
}

class _SelectProductScreenState extends ConsumerState<SelectProductScreen> {
  SortOption _currentSort = SortOption.recent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final suggestionsAsync = ref.watch(
      quoteProductSuggestionsProvider(const ProductSearchParams(query: '')),
    );

    final quoteProducts = ref.watch(createQuoteProvider).products;

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Agregar producto',
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
                context.push('/quotes/create/select-product/search').then((
                  result,
                ) {
                  if (result == true) {
                    // Passed back from search (which means a product was added)
                    if (context.mounted) {
                      context.pop();
                    }
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: IgnorePointer(
                child: CustomSearchBar(
                  hintText: 'Buscar producto...',
                  onChanged: (_) {}, // No-op, handled by onTap
                  readOnly: true,
                  showFilterIcon: true,
                ),
              ),
            ),
          ),

          // 2. Add Temporal Product Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              onPressed: () {
                context
                    .push('/quotes/create/select-product/temporal-product')
                    .then((result) {
                      if (result == true) {
                        if (context.mounted) {
                          context.pop();
                        }
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
                'Agregar producto temporal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // 3. Disclaimer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Precios no incluyen impuesto y pueden variar sin previo aviso',
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
                  options: const [
                    SortOption.frequency,
                    SortOption.recent,
                    SortOption.nameAZ,
                    SortOption.nameZA,
                  ],
                ),
              ],
            ),
          ),

          // 5. List
          Expanded(
            child: suggestionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => FriendlyErrorWidget(error: err),
              data: (products) {
                // Determine sort list
                final sortedProducts = List.of(products);
                sortedProducts.sort((a, b) {
                  switch (_currentSort) {
                    case SortOption.frequency:
                      // De mayor a menor puntuación
                      return b.frequencyScore.compareTo(a.frequencyScore);
                    case SortOption.recent:
                      // De más nueva a más antigua
                      return b.lastAddedAt.compareTo(a.lastAddedAt);
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

                if (sortedProducts.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay sugerencias disponibles',
                      style: TextStyle(color: colors.outline),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedProducts.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Colors.transparent),
                  itemBuilder: (context, index) {
                    final product = sortedProducts[index];
                    final isAlreadyInQuote = quoteProducts.any(
                      (p) =>
                          (p.brand ?? '').trim().toUpperCase() ==
                              product.brand.trim().toUpperCase() &&
                          (p.model ?? '').trim().toUpperCase() ==
                              product.model.trim().toUpperCase() &&
                          (p.uom).trim().toUpperCase() ==
                              product.uom.trim().toUpperCase(),
                    );

                    return AggregatedProductCard(
                      name: product.name,
                      brand: product.brand,
                      model: product.model,
                      minPrice: product.minPrice,
                      totalQuantity: product.totalQuantity,
                      supplierCount: product.supplierCount,
                      uom: product.uom,
                      uomIconName: product.uomIconName,
                      showPriceAndStock: true,
                      isLocked: product.isLocked,
                      isAlreadyAdded: isAlreadyInQuote,
                      onTap: () {
                        if (isAlreadyInQuote) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Este producto ya se encuentra en la cotización',
                              ),
                            ),
                          );
                          return;
                        }

                        context
                            .push(
                              '/quotes/create/select-product/product-sources',
                              extra: product,
                            )
                            .then((result) {
                              if (result == true) {
                                // Re-fetch or close? Just close for now
                                if (context.mounted) {
                                  context.pop();
                                }
                              }
                            });
                      },
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
