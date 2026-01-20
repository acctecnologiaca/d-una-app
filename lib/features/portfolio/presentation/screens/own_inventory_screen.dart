import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/products_provider.dart';
import 'widgets/inventory_item_card.dart';
import '../../../../shared/widgets/custom_search_bar.dart';

// Sort Option Enum
enum SortOption { recent, nameAZ, nameZA }

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

  void _showSortOptions(BuildContext context, ColorScheme colors) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.access_time,
                  color: _currentSort == SortOption.recent
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
                title: Text(
                  'Más recientes',
                  style: TextStyle(
                    color: _currentSort == SortOption.recent
                        ? colors.primary
                        : colors.onSurface,
                    fontWeight: _currentSort == SortOption.recent
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: _currentSort == SortOption.recent
                    ? Icon(Icons.check, color: colors.primary)
                    : null,
                onTap: () {
                  setState(() => _currentSort = SortOption.recent);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.sort_by_alpha,
                  color: _currentSort == SortOption.nameAZ
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
                title: Text(
                  'Nombre (A-Z)',
                  style: TextStyle(
                    color: _currentSort == SortOption.nameAZ
                        ? colors.primary
                        : colors.onSurface,
                    fontWeight: _currentSort == SortOption.nameAZ
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: _currentSort == SortOption.nameAZ
                    ? Icon(Icons.check, color: colors.primary)
                    : null,
                onTap: () {
                  setState(() => _currentSort = SortOption.nameAZ);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.sort_by_alpha,
                  color: _currentSort == SortOption.nameZA
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
                title: Text(
                  'Nombre (Z-A)',
                  style: TextStyle(
                    color: _currentSort == SortOption.nameZA
                        ? colors.primary
                        : colors.onSurface,
                    fontWeight: _currentSort == SortOption.nameZA
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: _currentSort == SortOption.nameZA
                    ? Icon(Icons.check, color: colors.primary)
                    : null,
                onTap: () {
                  setState(() => _currentSort = SortOption.nameZA);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.recent:
        return 'Más recientes';
      case SortOption.nameAZ:
        return 'Nombre (A-Z)';
      case SortOption.nameZA:
        return 'Nombre (Z-A)';
    }
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
              onFilterTap: () {
                // Filter action
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
                GestureDetector(
                  onTap: () => _showSortOptions(context, colors),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getSortLabel(_currentSort),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: colors.onSurface,
                      ),
                    ],
                  ),
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
                  final name = product.name.toLowerCase();
                  final brand = (product.brand ?? '').toLowerCase();
                  final model = (product.model ?? '').toLowerCase();
                  return name.contains(_searchQuery) ||
                      brand.contains(_searchQuery) ||
                      model.contains(_searchQuery);
                }).toList();

                // Apply sort
                filteredList.sort((a, b) {
                  switch (_currentSort) {
                    case SortOption.recent:
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

                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final product = filteredList[index];
                    // Random price between 30 and 100 for visual testing
                    final randomPrice = 30 + Random().nextDouble() * 70;
                    // Random stock between 5 and 30 for visual testing
                    final randomStock = 5 + Random().nextInt(26);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InventoryItemCard(
                        name: product.name,
                        brand: product.brand ?? 'Sin marca',
                        model: product.model ?? 'Sin modelo',
                        stock: randomStock, // Mock stock to see the color
                        price: randomPrice,
                        imageUrl: product.imageUrl,
                        onTap: () {},
                      ),
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
