import 'package:d_una_app/features/portfolio/domain/models/product_search_filters.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:d_una_app/features/profile/presentation/screens/verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/aggregated_product.dart';
import '../../../presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/shared/widgets/aggregated_product_card.dart';
import '../widgets/supplier_product_row.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../shared/widgets/horizontal_filter_bar.dart';
import '../../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../../shared/widgets/price_filter_sheet.dart';
import '../widgets/product_action_sheet.dart';
import '../../../../../../shared/widgets/sort_selector.dart';

// Create a simplified provider for this screen's data
final productSuppliersProvider =
    FutureProvider.family<
      List<Map<String, dynamic>>,
      ({AggregatedProduct product, ProductSearchFilters? filters})
    >((ref, params) async {
      final repository = ref.read(suppliersRepositoryProvider);
      return repository.getProductSuppliers(
        name: params.product.name,
        brand: params.product.brand,
        model: params.product.model,
        uom: params.product.uom,
        supplierIds: params.filters?.supplierIds,
        minPrice: params.filters?.minPrice,
        maxPrice: params.filters?.maxPrice,
      );
    });

class ProductSuppliersScreen extends ConsumerStatefulWidget {
  final AggregatedProduct product;
  final ProductSearchFilters? filters;

  const ProductSuppliersScreen({
    super.key,
    required this.product,
    this.filters,
  });

  @override
  ConsumerState<ProductSuppliersScreen> createState() =>
      _ProductSuppliersScreenState();
}

class _ProductSuppliersScreenState
    extends ConsumerState<ProductSuppliersScreen> {
  bool _isFiltersVisible = false;
  Set<String> _selectedSupplierIds = {};
  Set<String> _selectedCities = {};
  double? _minPrice;
  double? _maxPrice;
  SortOption _currentSort = SortOption.lowestPrice; // Added State

  @override
  void initState() {
    super.initState();
    // Initialize filters from passed params if any
    final initialSupplierIds = widget.filters?.supplierIds;
    if (initialSupplierIds != null) {
      _selectedSupplierIds = Set.from(initialSupplierIds);
    }
    _minPrice = widget.filters?.minPrice;
    _maxPrice = widget.filters?.maxPrice;
  }

  void _toggleFilters() {
    setState(() {
      _isFiltersVisible = !_isFiltersVisible;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedSupplierIds.clear();
      _selectedCities.clear();
      _minPrice = null;
      _maxPrice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider with initial params (fetched once)
    final suppliersAsync = ref.watch(
      productSuppliersProvider((
        product: widget.product,
        filters: widget.filters,
      )),
    );

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores y sucursales'),
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
        actions: [
          IconButton(
            icon: Icon(
              _isFiltersVisible ? Icons.filter_list_off : Icons.filter_list,
              color: colors.onSurface,
            ),
            onPressed: _toggleFilters,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Bar (Conditional Visibility)
          if (_isFiltersVisible)
            suppliersAsync.when(
              data: (allItems) => _buildFilterBar(allItems),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

          // Product Summary Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: colors.surface,
            child: AggregatedProductCard(
              name: widget.product.name,
              brand: widget.product.brand,
              model: widget.product.model,
              minPrice: widget.product.minPrice,
              totalQuantity: widget.product.totalQuantity,
              supplierCount: widget.product.supplierCount,
              uom: widget.product.uom,
              onTap: () {},
              showPriceAndStock: false,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  'Precios no incluyen impuesto y pueden variar sin previo aviso',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SortSelector(
                    currentSort: _currentSort,
                    options: const [
                      SortOption.nameAZ,
                      SortOption.nameZA,
                      SortOption.highestPrice,
                      SortOption.lowestPrice,
                      SortOption.quantityDesc,
                      SortOption.quantityAsc,
                    ],
                    onSortChanged: (val) => setState(() => _currentSort = val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: suppliersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => FriendlyErrorWidget(error: err),
              data: (allItems) {
                // Client-side filtering
                var items = allItems.where((item) {
                  // Supplier Filter
                  final supplierId = item['supplier_id'] as String;
                  if (_selectedSupplierIds.isNotEmpty &&
                      !_selectedSupplierIds.contains(supplierId)) {
                    return false;
                  }

                  // City Filter
                  final city = item['branch_city'] as String? ?? '';
                  if (_selectedCities.isNotEmpty &&
                      !_selectedCities.contains(city)) {
                    return false;
                  }

                  // Price Filter
                  final price = (item['price'] as num).toDouble();
                  if (_minPrice != null && price < _minPrice!) return false;
                  if (_maxPrice != null && price > _maxPrice!) return false;

                  return true;
                }).toList();

                // Sort Items
                items.sort((a, b) {
                  // Helper to safely parse numbers from JSON
                  double parseDouble(dynamic value) {
                    if (value is num) return value.toDouble();
                    if (value is String) return double.tryParse(value) ?? 0.0;
                    return 0.0;
                  }

                  int parseInt(dynamic value) {
                    if (value is num) return value.toInt();
                    if (value is String) return int.tryParse(value) ?? 0;
                    return 0;
                  }

                  switch (_currentSort) {
                    case SortOption.lowestPrice:
                      final priceA = parseDouble(a['price']);
                      final priceB = parseDouble(b['price']);
                      return priceA.compareTo(priceB);
                    case SortOption.highestPrice:
                      final priceA = parseDouble(a['price']);
                      final priceB = parseDouble(b['price']);
                      return priceB.compareTo(priceA);
                    case SortOption.quantityAsc:
                      final stockA = parseInt(a['stock_quantity']);
                      final stockB = parseInt(b['stock_quantity']);
                      return stockA.compareTo(stockB);
                    case SortOption.quantityDesc:
                      final stockA = parseInt(a['stock_quantity']);
                      final stockB = parseInt(b['stock_quantity']);
                      return stockB.compareTo(stockA);
                    case SortOption.nameAZ:
                      final nameA = (a['supplier_name'] as String)
                          .toLowerCase();
                      final nameB = (b['supplier_name'] as String)
                          .toLowerCase();
                      return nameA.compareTo(nameB);
                    case SortOption.nameZA:
                      final nameA = (a['supplier_name'] as String)
                          .toLowerCase();
                      final nameB = (b['supplier_name'] as String)
                          .toLowerCase();
                      return nameB.compareTo(nameA);
                    default:
                      return 0;
                  }
                });

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: colors.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay resultados con estos filtros',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Limpiar filtros'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.transparent,
                  ),
                  itemBuilder: (context, index) {
                    // Helper to safely parse numbers from JSON
                    double parseDouble(dynamic value) {
                      if (value is num) return value.toDouble();
                      if (value is String) return double.tryParse(value) ?? 0.0;
                      return 0.0;
                    }

                    int parseInt(dynamic value) {
                      if (value is num) return value.toInt();
                      if (value is String) return int.tryParse(value) ?? 0;
                      return 0;
                    }

                    final item = items[index];
                    final supplierName = item['supplier_name'] as String;
                    final tradeType =
                        item['supplier_trade_type'] as String? ?? 'RETAIL';
                    final branchCity = item['branch_city'] as String? ?? '';
                    final price = parseDouble(item['price']);
                    final stock = parseInt(item['stock_quantity']);
                    final uom =
                        item['uom_label'] as String? ??
                        item['uom'] as String? ??
                        'Unidad';
                    final uomIconName = item['uom_icon_name'] as String?;

                    // Parse Access Level from Backend
                    final isRestricted =
                        !(item['is_accessible'] as bool? ??
                            false); // Locked + SnackBar
                    final isPartial =
                        false; // We only have binary access currently

                    // Logic for SnackBar (OnTap)
                    // Restricted OR Partial items block navigation/action and show SnackBar
                    final shouldShowSnackBar = isRestricted || isPartial;

                    return SupplierProductRow(
                      supplierName: supplierName,
                      locationName: branchCity,
                      price: price,
                      stock: stock,
                      uom: uom,
                      uomIconName: uomIconName,
                      isWholesale: tradeType == 'WHOLESALE',
                      isLocked: isRestricted,
                      isPartial: isPartial,
                      onTap: () {
                        if (shouldShowSnackBar) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 5),
                              content: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Requiere que estés verificado con una compañía o firma personal',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentSnackBar();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const VerificationScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Verificar',
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentSnackBar();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                          return;
                        }

                        // Show Action Sheet for valid selection
                        ProductActionSheet.show(
                          context,
                          supplierName: supplierName,
                          productName: widget.product.name,
                          price: price,
                          stock: stock,
                          uom: uom,
                          location: branchCity,
                          isWholesale: tradeType == 'WHOLESALE',
                          brand: widget.product.brand,
                          model: widget.product.model,
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
    );
  }

  Widget _buildFilterBar(List<Map<String, dynamic>> items) {
    // Determine if any filters are active
    final bool isAnyFilterActive =
        _selectedSupplierIds.isNotEmpty ||
        _selectedCities.isNotEmpty ||
        _minPrice != null ||
        _maxPrice != null;

    // Extract suppliers map for labels
    final Map<String, String> suppliers = {};
    for (var item in items) {
      final id = item['supplier_id'] as String;
      final name = item['supplier_name'] as String;
      suppliers[id] = name;
    }

    return HorizontalFilterBar(
      onResetFilters: isAnyFilterActive ? _resetFilters : null,
      filters: [
        FilterChipData(
          label: HorizontalFilterBar.formatLabel(
            defaultLabel: 'Proveedor',
            selectedValues: _selectedSupplierIds.toList(),
            valueToLabelMap: suppliers,
          ),
          isActive: _selectedSupplierIds.isNotEmpty,
          onTap: () => _showSupplierFilter(context, items),
        ),
        FilterChipData(
          label: HorizontalFilterBar.formatLabel(
            defaultLabel: 'Ciudad',
            selectedValues: _selectedCities.toList(),
          ),
          isActive: _selectedCities.isNotEmpty,
          onTap: () => _showCityFilter(context, items),
        ),
        FilterChipData(
          label: _minPrice == null && _maxPrice == null
              ? 'Precio'
              : 'Precio (Activo)',
          isActive: _minPrice != null || _maxPrice != null,
          onTap: () => _showPriceFilter(context, items),
        ),
      ],
    );
  }

  void _showSupplierFilter(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    // Extract unique suppliers from the *full list* of items
    final Map<String, String> suppliers = {};
    for (var item in items) {
      final id = item['supplier_id'] as String;
      final name = item['supplier_name'] as String;
      suppliers[id] = name;
    }

    final options = suppliers.keys.toList();

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Proveedor',
      options: options,
      selectedValues: _selectedSupplierIds,
      labelBuilder: (id) => suppliers[id] ?? 'Desconocido',
      onApply: (selected) {
        setState(() {
          _selectedSupplierIds = selected;
        });
      },
    );
  }

  void _showCityFilter(BuildContext context, List<Map<String, dynamic>> items) {
    final Set<String> cities = {};
    for (var item in items) {
      final city = item['branch_city'] as String?;
      if (city != null && city.isNotEmpty) {
        cities.add(city);
      }
    }

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Ciudad',
      options: cities.toList()..sort(),
      selectedValues: _selectedCities,
      onApply: (selected) {
        setState(() {
          _selectedCities = selected;
        });
      },
    );
  }

  void _showPriceFilter(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PriceFilterSheet(
        initialMin: _minPrice,
        initialMax: _maxPrice,
        onApply: (min, max) {
          setState(() {
            _minPrice = min;
            _maxPrice = max;
          });
        },
      ),
    );
  }
}
