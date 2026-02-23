import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/products_provider.dart';
import '../widgets/inventory_item_card.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../widgets/inventory_action_sheet.dart';
import '../../../../../shared/widgets/sort_selector.dart';

class OwnInventoryScreen extends ConsumerStatefulWidget {
  const OwnInventoryScreen({super.key});

  @override
  ConsumerState<OwnInventoryScreen> createState() => _OwnInventoryScreenState();
}

class _OwnInventoryScreenState extends ConsumerState<OwnInventoryScreen> {
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
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario propio'),
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
              onTap: () {
                context.push('/portfolio/own-inventory/search');
              },
            ),
          ),

          // Disclaimer (Updated text since price/stock are 0 for now)
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
                ),
              ],
            ),
          ),

          // Inventory List
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (products) {
                // Filter List
                var filteredList = products.where((product) {
                  final normalizedQuery = _searchQuery.normalized;
                  final name = product.name.normalized;
                  final brand = (product.brand?.name ?? '').normalized;
                  final model = (product.model ?? '').normalized;
                  return name.contains(normalizedQuery) ||
                      brand.contains(normalizedQuery) ||
                      model.contains(normalizedQuery);
                }).toList();

                // Apply sort
                filteredList.sort((a, b) {
                  switch (_currentSort) {
                    case SortOption.recent:
                    case SortOption.frequency:
                      return b.createdAt.compareTo(a.createdAt);
                    case SortOption.nameAZ:
                      return a.name.toLowerCase().compareTo(
                        b.name.toLowerCase(),
                      );
                    case SortOption.nameZA:
                      return b.name.toLowerCase().compareTo(
                        a.name.toLowerCase(),
                      );
                  }
                });

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay productos agregados a tu inventario',
                      style: TextStyle(color: colors.outline, fontSize: 16),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: filteredList.length,
                  separatorBuilder: (context, index) =>
                      //const SizedBox(height: 12),
                      const Divider(height: 1, color: Colors.transparent),
                  itemBuilder: (context, index) {
                    final product = filteredList[index];
                    // Random price between 30 and 100 for visual testing
                    final randomPrice = 30 + Random().nextDouble() * 70;
                    // Random stock between 5 and 30 for visual testing
                    final randomStock = 5 + Random().nextInt(26);

                    return InventoryItemCard(
                      name: product.name,
                      brand: product.brand?.name ?? 'Sin marca',
                      model: product.model ?? 'Sin modelo',
                      stock: randomStock, // Mock stock to see the color
                      price: randomPrice,
                      imageUrl: product.imageUrl,
                      onTap: () {
                        InventoryActionSheet.show(
                          context: context,
                          product: product,
                          currentPrice:
                              0.0, // Unavailable in filtered list (using mock inside sheet if needed, or pass 0)
                          currentStock: 0,
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
        child: FloatingActionButton.extended(
          onPressed: () {
            context.go('/portfolio/own-inventory/add');
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Agregar',
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
