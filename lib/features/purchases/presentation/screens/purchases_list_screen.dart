import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';
import '../providers/purchases_providers.dart';
import '../widgets/purchase_list_item.dart';

class PurchasesListScreen extends ConsumerStatefulWidget {
  const PurchasesListScreen({super.key});

  @override
  ConsumerState<PurchasesListScreen> createState() =>
      _PurchasesListScreenState();
}

class _PurchasesListScreenState extends ConsumerState<PurchasesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _currentSort = SortOption.recent;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final purchasesAsync = ref.watch(purchasesProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: const StandardAppBar(title: 'Mis compras'),
      body: Column(
        children: [
          // Search & Filter Bar
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
                  onSortChanged: (val) => setState(() => _currentSort = val),
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

          // Purchases List
          Expanded(
            child: purchasesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (purchases) {
                // Filter List
                var filteredList = purchases.where((purchase) {
                  final normalizedQuery = _searchQuery.normalized;
                  final supplierName = (purchase.supplierName ?? '').normalized;
                  final documentNumber = purchase.documentNumber.normalized;
                  return supplierName.contains(normalizedQuery) ||
                      documentNumber.contains(normalizedQuery);
                }).toList();

                // Apply sort
                filteredList.sort((a, b) {
                  switch (_currentSort) {
                    case SortOption.oldest:
                      return a.date.compareTo(b.date);
                    case SortOption.highestPrice:
                      return b.subtotal.compareTo(a.subtotal);
                    case SortOption.lowestPrice:
                      return a.subtotal.compareTo(b.subtotal);
                    case SortOption.recent:
                    default:
                      return b.date.compareTo(a.date);
                  }
                });

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text(
                      'No tienes compras registradas',
                      style: TextStyle(
                        color: colors.outlineVariant,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(
                    bottom: 100,
                  ), // padding bottom for potential FAB in the future
                  itemCount: filteredList.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final purchase = filteredList[index];

                    return PurchaseListItem(
                      purchase: purchase,
                      onTap: () {
                        // TODO: Navigate to purchase details screen when ready
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                'Abriendo detalle de la compra: ${purchase.documentNumber}',
                              ),
                            ),
                          );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          onPressed: () {
            context.push('/my-purchases/add');
          },
          label: 'Registrar',
          icon: Icons.post_add,
        ),
      ),
    );
  }
}
