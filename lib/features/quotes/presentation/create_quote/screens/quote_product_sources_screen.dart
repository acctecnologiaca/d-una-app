import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/quote_aggregated_product.dart';
import '../../../domain/models/quote_product_source.dart';
import '../../../data/models/quote_item_product.dart';
import '../providers/quote_product_selection_provider.dart';
import '../providers/create_quote_provider.dart';
import '../../../../../shared/widgets/aggregated_product_card.dart';
import '../../../../../shared/widgets/horizontal_filter_bar.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/price_filter_sheet.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../widgets/quote_product_sale_details_sheet.dart';
import '../widgets/quote_product_source_card.dart';

class QuoteProductSourcesScreen extends ConsumerStatefulWidget {
  final QuoteAggregatedProduct product;
  final Map<String, double>? initialSelections;
  final double? externalCostPrice;
  final String? externalProviderName;

  const QuoteProductSourcesScreen({
    super.key,
    required this.product,
    this.initialSelections,
    this.externalCostPrice,
    this.externalProviderName,
  });

  @override
  ConsumerState<QuoteProductSourcesScreen> createState() =>
      _QuoteProductSourcesScreenState();
}

class _QuoteProductSourcesScreenState
    extends ConsumerState<QuoteProductSourcesScreen> {
  bool _isFiltersVisible = false;
  Set<String> _selectedSupplierIds = {};
  Set<String> _selectedCities = {};
  double? _minPrice;
  double? _maxPrice;
  SortOption _currentSort = SortOption.lowestPrice;

  // Gestión Externa: cost price entered by user
  double? _externalCostPrice;
  String? _externalProviderName;

  @override
  void initState() {
    super.initState();
    _externalCostPrice = widget.externalCostPrice;
    _externalProviderName = widget.externalProviderName;

    if (widget.initialSelections != null &&
        widget.initialSelections!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final entry in widget.initialSelections!.entries) {
          ref
              .read(quoteSourceSelectionProvider.notifier)
              .setSelection(entry.key, entry.value);
        }
      });
    }
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
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final sourcesAsync = ref.watch(quoteProductSourcesProvider(widget.product));
    final selectionState = ref.watch(quoteSourceSelectionProvider);
    final selectionController = ref.read(quoteSourceSelectionProvider.notifier);

    double totalQuantity = 0;

    // We need the data to calculate real totals based on selection
    final rawSourceList = sourcesAsync.valueOrNull ?? [];

    // Inject virtual "Gestión Externa" source
    final externalSource = QuoteProductSource.externalManagement(
      suggestedPrice: _externalCostPrice ?? widget.product.minPrice,
    );

    // Build the full source list with dynamic position
    final sourceList = <QuoteProductSource>[externalSource, ...rawSourceList];

    bool hasConflicts = false;
    for (final source in sourceList) {
      if (selectionState.containsKey(source.id)) {
        final qty = selectionState[source.id]!;
        totalQuantity += qty;

        // Track conflicts: selection > maxStock (skip externalManagement and own)
        if (source.sourceType == ProductSourceType.supplier &&
            qty > source.maxStock) {
          hasConflicts = true;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedor y cantidades'),
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
        children: [
          // Filter Bar (Conditional Visibility)
          if (_isFiltersVisible)
            Align(
              alignment: Alignment.centerLeft,
              child: sourcesAsync.when(
                data: (allItems) => _buildFilterBar(allItems),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),

          // Product header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: colors.surface,
            width: double.infinity,
            child: AggregatedProductCard(
              name: widget.product.name,
              brand: widget.product.brand,
              model: widget.product.model,
              minPrice: widget.product.minPrice,
              totalQuantity: widget.product.totalQuantity,
              supplierCount: widget.product.supplierCount,
              uom: widget.product.uom,
              uomIconName: widget.product.uomIconName,
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
          const SizedBox(height: 16),
          // Sources List
          Expanded(
            child: sourcesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => FriendlyErrorWidget(error: err),
              data: (sources) {
                // Client-side filtering
                // Use the full sourceList (with injected externalManagement) instead of raw sources
                var filteredSources = sourceList.where((item) {
                  // Always show External Management card (skip all filters)
                  if (item.sourceType == ProductSourceType.externalManagement) {
                    return true;
                  }

                  // 1. Initial Product Sources Filter
                  if (widget.product.suppliersInfo.isNotEmpty) {
                    if (item.sourceType == ProductSourceType.own) {
                      if (!widget.product.hasOwnInventory) return false;
                    } else {
                      final allowedSuppliers = widget.product.suppliersInfo
                          .map((info) => info['name']!.toLowerCase())
                          .toSet();

                      if (!allowedSuppliers.contains(
                        item.sourceName.toLowerCase(),
                      )) {
                        return false;
                      }
                    }
                  }

                  // 2. User-Selected Supplier Filter (Local to this screen)
                  if (_selectedSupplierIds.isNotEmpty &&
                      !_selectedSupplierIds.contains(item.sourceName) &&
                      item.sourceType == ProductSourceType.supplier) {
                    return false;
                  }

                  // City Filter
                  final city = item.location ?? '';
                  if (_selectedCities.isNotEmpty &&
                      !_selectedCities.contains(city) &&
                      item.sourceType == ProductSourceType.supplier) {
                    return false;
                  }

                  // Price Filter
                  final price = item.price;
                  if (_minPrice != null && price < _minPrice!) return false;
                  if (_maxPrice != null && price > _maxPrice!) return false;

                  // Intelligent Stock Filter:
                  // Hide items with 0 stock UNLESS they were previously selected by the user.
                  final isInitiallySelected =
                      widget.initialSelections?.containsKey(item.id) ?? false;
                  if (item.maxStock <= 0 && !isInitiallySelected) {
                    return false;
                  }

                  return true;
                }).toList();

                // Client-side sorting con PRIORIDADES FIJAS
                filteredSources.sort((a, b) {
                  // 1. Inventario Propio SIEMPRE de primero
                  if (a.sourceType == ProductSourceType.own) return -1;
                  if (b.sourceType == ProductSourceType.own) return 1;

                  // 2. Gestión Externa SIEMPRE de segundo
                  if (a.sourceType == ProductSourceType.externalManagement) {
                    return 1;
                  }
                  if (b.sourceType == ProductSourceType.externalManagement) {
                    return -1;
                  }

                  // 3. El resto de proveedores obedecen el selector de orden
                  switch (_currentSort) {
                    case SortOption.lowestPrice:
                      return a.price.compareTo(b.price);
                    case SortOption.highestPrice:
                      return b.price.compareTo(a.price);
                    case SortOption.quantityAsc:
                      return a.maxStock.compareTo(b.maxStock);
                    case SortOption.quantityDesc:
                      return b.maxStock.compareTo(a.maxStock);
                    case SortOption.nameAZ:
                      return a.sourceName.toLowerCase().compareTo(
                        b.sourceName.toLowerCase(),
                      );
                    case SortOption.nameZA:
                      return b.sourceName.toLowerCase().compareTo(
                        a.sourceName.toLowerCase(),
                      );
                    default:
                      return 0;
                  }
                });

                if (filteredSources.isEmpty) {
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
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 120),
                  itemCount: filteredSources.length,
                  itemBuilder: (context, index) {
                    final item = filteredSources[index];
                    return QuoteProductSourceCard(
                      key: ValueKey(item.id),
                      source: item,
                      selectedQty: selectionState[item.id] ?? 0.0,
                      uom: widget.product.uom,
                      externalCostPrice:
                          item.sourceType ==
                              ProductSourceType.externalManagement
                          ? _externalCostPrice
                          : null,
                      externalProviderName:
                          item.sourceType ==
                              ProductSourceType.externalManagement
                          ? _externalProviderName
                          : null,
                      onSelectAll: () {
                        final isExternal =
                            item.sourceType ==
                            ProductSourceType.externalManagement;
                        final maxQty = (isExternal)
                            ? 1.0 // Default to 1 for own/external
                            : item.maxStock;
                        selectionController.toggleSelection(item.id, maxQty);
                      },
                      onDeselectAll: () {
                        selectionController.setSelection(item.id, 0);
                      },
                      onQtyChanged: (qty) {
                        selectionController.setSelection(item.id, qty);
                      },
                      onProviderNameChanged:
                          item.sourceType ==
                              ProductSourceType.externalManagement
                          ? (name) {
                              _externalProviderName = name;
                            }
                          : null,
                      onCostChanged:
                          item.sourceType ==
                              ProductSourceType.externalManagement
                          ? (cost) {
                              _externalCostPrice = cost;
                            }
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          onPressed: () async {
            final createQuoteNotifier = ref.read(createQuoteProvider.notifier);
            final quoteState = ref.read(createQuoteProvider);
            final uuid = const Uuid();

            final taxRate = quoteState.globalTaxRate;

            // Gather selected sources
            final selectedSources = <QuoteProductSource, double>{};
            double totalCostSum = 0;
            double totalQtySelected = 0;

            for (final source in sourceList) {
              if (selectionState.containsKey(source.id)) {
                final qty = selectionState[source.id]!;
                if (qty <= 0) continue;

                // For external management, use the user-entered cost
                final effectivePrice =
                    source.sourceType == ProductSourceType.externalManagement
                    ? (_externalCostPrice ?? source.price)
                    : source.price;

                selectedSources[source] = qty;
                totalQtySelected += qty;
                totalCostSum += (effectivePrice * qty);
              }
            }

            if (selectedSources.isEmpty) return;

            final averageCost = totalCostSum / totalQtySelected;

            // Show Selling Price Sheet
            final result = await QuoteProductSaleDetailsSheet.show(
              context,
              averageCost: averageCost,
              productName: widget.product.name,
              uom: widget.product.uom,
              brand: widget.product.brand,
              model: widget.product.model,
            );

            if (result == null) return; // User cancelled

            final double sellingPrice = result['sellingPrice'];
            final double profitMargin = result['profitMargin'];
            final String? deliveryTimeId = result['deliveryTimeId'];

            // 1. Remove previously added items for this product to prevent duplication
            createQuoteNotifier.removeProductGroup(widget.product.name);

            // 2. Add the newly selected sizes/sources
            for (final entry in selectedSources.entries) {
              final source = entry.key;
              final qty = entry.value;
              final isExternal =
                  source.sourceType == ProductSourceType.externalManagement;

              final costPrice = isExternal
                  ? (_externalCostPrice ?? source.price)
                  : source.price;
              final unitPrice = sellingPrice;
              final taxAmount = unitPrice * (taxRate / 100);
              final totalPrice = (unitPrice + taxAmount) * qty;

              final quoteItem = QuoteItemProduct(
                id: uuid.v4(),
                quoteId: 'draft', // Placeholder until quote is saved
                // External Management: use productId for analytics, no supplierBranchStockId
                productId: (source.sourceType == ProductSourceType.own)
                    ? source.id
                    : null,
                supplierBranchStockId:
                    (source.sourceType == ProductSourceType.supplier)
                    ? source.id
                    : null,
                deliveryTimeId: deliveryTimeId,
                name: widget.product.name,
                brand: widget.product.brand,
                model: widget.product.model,
                uom: widget.product.uom,
                description: null,
                availableStock: isExternal
                    ? -1.0
                    : source.maxStock, // -1 flags external
                quantity: qty,
                costPrice: costPrice,
                profitMargin: profitMargin,
                unitPrice: unitPrice,
                taxRate: taxRate,
                taxAmount: taxAmount,
                totalPrice: totalPrice,
                externalProviderName: isExternal ? _externalProviderName : null,
              );

              createQuoteNotifier.addProduct(quoteItem);
            }
            if (context.mounted) {
              context.pop(true);
            }
          },
          icon: Icons.check,
          label:
              'Confirmar (${totalQuantity.toStringAsFixed(totalQuantity.truncateToDouble() == totalQuantity ? 0 : 2)} ${widget.product.uom})',
          isEnabled: totalQuantity > 0 && !hasConflicts,
        ),
      ),
    );
  }

  Widget _buildFilterBar(List<QuoteProductSource> items) {
    final bool isAnyFilterActive =
        _selectedSupplierIds.isNotEmpty ||
        _selectedCities.isNotEmpty ||
        _minPrice != null ||
        _maxPrice != null;
    final Set<String> supplierNames = {};
    for (var item in items) {
      if (item.sourceType == ProductSourceType.supplier) {
        supplierNames.add(item.sourceName);
      }
    }
    return HorizontalFilterBar(
      onResetFilters: isAnyFilterActive ? _resetFilters : null,
      filters: [
        FilterChipData(
          label: HorizontalFilterBar.formatLabel(
            defaultLabel: 'Proveedor',
            selectedValues: _selectedSupplierIds.toList(),
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
    List<QuoteProductSource> items,
  ) {
    // Obtenemos nombres únicos y los ordenamos alfabéticamente
    final Set<String> supplierNames = {};
    for (var item in items) {
      if (item.sourceType == ProductSourceType.supplier) {
        supplierNames.add(item.sourceName);
      }
    }
    final options = supplierNames.toList()..sort();
    FilterBottomSheet.showMulti(
      context: context,
      title: 'Proveedor',
      options: options, // Ahora las opciones son los Nombres
      selectedValues: _selectedSupplierIds,
      labelBuilder: (name) => name, // El label es el mismo nombre
      onApply: (selected) {
        setState(() {
          _selectedSupplierIds = selected;
        });
      },
    );
  }

  void _showCityFilter(BuildContext context, List<QuoteProductSource> items) {
    final Set<String> cities = {};
    for (var item in items) {
      if (item.sourceType == ProductSourceType.supplier &&
          item.location != null &&
          item.location!.isNotEmpty) {
        cities.add(item.location!);
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

  void _showPriceFilter(BuildContext context, List<QuoteProductSource> items) {
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
