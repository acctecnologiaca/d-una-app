import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/products_provider.dart';
import 'widgets/inventory_item_card.dart';
import 'widgets/estimate_price_dialog.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../core/utils/string_extensions.dart';

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
      backgroundColor: colors.surfaceContainer,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Ordenar por',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSortOption(
                context,
                'Más reciente',
                SortOption.recent,
                colors,
              ),
              _buildSortOption(
                context,
                'Nombre (A-Z)',
                SortOption.nameAZ,
                colors,
              ),
              _buildSortOption(
                context,
                'Nombre (Z-A)',
                SortOption.nameZA,
                colors,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showProductActionSheet(
    BuildContext context,
    dynamic product,
    double currentPrice, // Add price argument
    ColorScheme colors,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: colors.surfaceContainer,
      builder: (context) {
        // Mock data for display consistency with image
        final randomPrice = 30 + Random().nextDouble() * 70;
        final randomStock = 5 + Random().nextInt(26);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Producto seleccionado',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info Summary (Mini Card)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InventoryItemCard(
                  name: product.name,
                  brand: product.brand?.name ?? 'Sin marca',
                  model: product.model ?? 'Sin modelo',
                  stock: randomStock, // Using same mock stock as before
                  price: randomPrice, // Using same mock price as before
                  imageUrl: product.imageUrl,
                  onTap: () {}, // No action when tapping the card in the sheet
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Actions
              BottomSheetActionItem(
                icon: Icons.local_offer_outlined,
                label: 'Estimar precio de venta',
                onTap: () {
                  context.pop();
                  showDialog(
                    context: context,
                    builder: (_) => EstimatePriceDialog(
                      basePrice: currentPrice,
                      productName: product.name,
                      productBrand: product.brand?.name,
                      productModel: product.model,
                    ),
                  );
                },
              ),
              BottomSheetActionItem(
                icon: Icons.request_quote_outlined,
                label: 'Cotizar a un cliente',
                onTap: () {
                  context.pop();
                  // TODO: Implement Quote to Client
                },
              ),
              BottomSheetActionItem(
                icon: 'assets/icons/add_request_quote.png',
                label: 'Agregar a cotización existente',
                onTap: () {
                  context.pop();
                  // TODO: Implement Add to Existing Quote
                },
              ),
              BottomSheetActionItem(
                icon: Icons.info_outline,
                label: 'Detalles del producto',
                onTap: () {
                  context.pop();
                  context.push(
                    '/portfolio/own-inventory/details/${product.id}',
                    extra: product,
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String label,
    SortOption option,
    ColorScheme colors,
  ) {
    final isSelected = _currentSort == option;
    return InkWell(
      onTap: () {
        setState(() {
          _currentSort = option;
        });
        context.pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? (option == SortOption.recent
                        ? Icons.arrow_downward
                        : (option == SortOption.nameAZ
                              ? Icons.arrow_upward
                              : Icons.arrow_downward))
                  : (option == SortOption.recent
                        ? Icons.arrow_downward
                        : (option == SortOption.nameAZ
                              ? Icons.arrow_upward
                              : Icons.arrow_downward)),
              color: colors.onSurface,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.recent:
        return 'Más reciente';
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
                      const Divider(height: 1),
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
                        _showProductActionSheet(
                          context,
                          product,
                          randomPrice,
                          colors,
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
