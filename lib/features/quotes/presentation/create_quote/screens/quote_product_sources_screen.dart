import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../domain/models/quote_aggregated_product.dart';
import '../../../domain/models/quote_product_source.dart';
import '../../../data/models/quote_item_product.dart';
import '../providers/quote_product_selection_provider.dart';
import '../providers/create_quote_provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../shared/widgets/aggregated_product_card.dart';
import '../../../../../shared/widgets/horizontal_filter_bar.dart';
import '../../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../../shared/widgets/price_filter_sheet.dart';
import '../../../../portfolio/domain/models/product_sort_option.dart';
import '../../../../profile/presentation/screens/verification_screen.dart';

class QuoteProductSourcesScreen extends ConsumerStatefulWidget {
  final QuoteAggregatedProduct product;

  const QuoteProductSourcesScreen({super.key, required this.product});

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
  ProductSortOption _currentSort = ProductSortOption.priceAsc;

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

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              ...ProductSortOption.values.map(
                (option) => InkWell(
                  onTap: () {
                    setState(() => _currentSort = option);
                    context.pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _currentSort == option
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: _currentSort == option
                              ? colors.primary
                              : colors.onSurface,
                          size: 20,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option.label,
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final sourcesAsync = ref.watch(quoteProductSourcesProvider(widget.product));
    final selectionState = ref.watch(quoteSourceSelectionProvider);
    final selectionController = ref.read(quoteSourceSelectionProvider.notifier);

    double totalQuantity = 0;
    double totalCost = 0;

    // We need the data to calculate real totals based on selection
    final sourceList = sourcesAsync.valueOrNull ?? [];

    for (final source in sourceList) {
      if (selectionState.containsKey(source.id)) {
        final qty = selectionState[source.id]!;
        totalQuantity += qty;
        totalCost += (qty * source.price);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Origen'),
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
                  child: InkWell(
                    onTap: _showSortOptions,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentSort.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (sources) {
                // Client-side filtering
                var filteredSources = sources.where((item) {
                  // 1. Initial Product Sources Filter
                  // Only show suppliers that were included in the aggregated product
                  // (which respects any supplier filters chosen on the previous screen).
                  final allowedSuppliers = widget.product.sources
                      .map((s) => s.supplierName.toLowerCase())
                      .toSet();

                  if (!allowedSuppliers.contains(
                    item.sourceName.toLowerCase(),
                  )) {
                    return false;
                  }

                  // 2. User-Selected Supplier Filter (Local to this screen)
                  if (_selectedSupplierIds.isNotEmpty &&
                      !_selectedSupplierIds.contains(item.id) &&
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

                  return true;
                }).toList();

                // Client-side sorting
                filteredSources.sort((a, b) {
                  switch (_currentSort) {
                    case ProductSortOption.priceAsc:
                      return a.price.compareTo(b.price);
                    case ProductSortOption.priceDesc:
                      return b.price.compareTo(a.price);
                    case ProductSortOption.quantityAsc:
                      return a.maxStock.compareTo(b.maxStock);
                    case ProductSortOption.quantityDesc:
                      return b.maxStock.compareTo(a.maxStock);
                    case ProductSortOption.nameAZ:
                      return a.sourceName.toLowerCase().compareTo(
                        b.sourceName.toLowerCase(),
                      );
                    case ProductSortOption.nameZA:
                      return b.sourceName.toLowerCase().compareTo(
                        a.sourceName.toLowerCase(),
                      );
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
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredSources.length,
                  itemBuilder: (context, index) {
                    final source = filteredSources[index];
                    final isOwn = source.sourceType == ProductSourceType.own;
                    final maxToSelect = isOwn ? 1.0 : source.maxStock;
                    final selectedQty = selectionState[source.id] ?? 0.0;

                    return _SourceCard(
                      source: source,
                      selectedQty: selectedQty,
                      uom: widget.product.uom,
                      onSelectAll: () => selectionController.setSelection(
                        source.id,
                        maxToSelect,
                      ),
                      onDeselectAll: () =>
                          selectionController.setSelection(source.id, 0.0),
                      onQtyChanged: (qty) =>
                          selectionController.setSelection(source.id, qty),
                    );
                  },
                );
              },
            ),
          ),
          // Bottom Summary Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total a agregar',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${totalQuantity.toStringAsFixed(totalQuantity.truncateToDouble() == totalQuantity ? 0 : 2)} ${widget.product.uom}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(totalCost),
                              style: textTheme.titleMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: totalQuantity > 0
                        ? () {
                            final createQuoteNotifier = ref.read(
                              createQuoteProvider.notifier,
                            );
                            final quoteState = ref.read(createQuoteProvider);
                            final uuid = const Uuid();

                            // Ensure global margins/taxes are loaded
                            final margin = quoteState.globalMargin;
                            final taxRate = quoteState.globalTaxRate;

                            for (final source in sourceList) {
                              if (selectionState.containsKey(source.id)) {
                                final qty = selectionState[source.id]!;
                                if (qty <= 0) continue;

                                final costPrice = source.price;
                                // Simple unit price calculation: cost * (1 + margin)
                                final unitPrice = costPrice * (1 + margin);
                                final taxAmount = unitPrice * taxRate;
                                final totalPrice =
                                    (unitPrice + taxAmount) * qty;

                                final quoteItem = QuoteItemProduct(
                                  id: uuid.v4(),
                                  quoteId:
                                      'draft', // Placeholder until quote is saved
                                  productId:
                                      source.sourceType == ProductSourceType.own
                                      ? source.id
                                      : null,
                                  supplierProductId:
                                      source.sourceType ==
                                          ProductSourceType.supplier
                                      ? source.id
                                      : null,
                                  name: widget.product.name,
                                  brand: widget.product.brand,
                                  model: widget.product.model,
                                  uom: widget.product.uom,
                                  quantity: qty,
                                  costPrice: costPrice,
                                  profitMargin: margin,
                                  unitPrice: unitPrice,
                                  taxRate: taxRate,
                                  taxAmount: taxAmount,
                                  totalPrice: totalPrice,
                                );

                                createQuoteNotifier.addProduct(quoteItem);
                              }
                            }
                            // Pop true to indicate success to SelectProductScreen
                            context.pop(true);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(List<QuoteProductSource> items) {
    // Determine if any filters are active
    final bool isAnyFilterActive =
        _selectedSupplierIds.isNotEmpty ||
        _selectedCities.isNotEmpty ||
        _minPrice != null ||
        _maxPrice != null;

    // Extract suppliers map for labels
    final Map<String, String> suppliers = {};
    for (var item in items) {
      if (item.sourceType == ProductSourceType.supplier) {
        suppliers[item.id] = item.sourceName;
      }
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
    List<QuoteProductSource> items,
  ) {
    final Map<String, String> suppliers = {};
    for (var item in items) {
      if (item.sourceType == ProductSourceType.supplier) {
        suppliers[item.id] = item.sourceName;
      }
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

class _SourceCard extends StatefulWidget {
  final QuoteProductSource source;
  final double selectedQty;
  final String uom;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final ValueChanged<double> onQtyChanged;

  const _SourceCard({
    required this.source,
    required this.selectedQty,
    required this.uom,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onQtyChanged,
  });

  @override
  State<_SourceCard> createState() => _SourceCardState();
}

class _SourceCardState extends State<_SourceCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isOwn = widget.source.sourceType == ProductSourceType.own;
    final maxQty = isOwn ? 99999.0 : widget.source.maxStock;

    // Access Level Parsing
    final accessLevel = widget.source.accessLevel;
    final isRestricted = accessLevel == 'restricted'; // Locked + SnackBar
    final isPartial = accessLevel == 'partial'; // Unlocked + Blurred Price
    final shouldShowSnackBar = isRestricted || isPartial;

    // Determine the checkbox state
    bool? checkboxState;
    if (widget.selectedQty == 0) {
      checkboxState = false;
    } else if (isOwn || widget.selectedQty == widget.source.maxStock) {
      checkboxState = true;
    } else {
      checkboxState = null; // Indeterminate
    }

    // Always keep it expanded if there's a selected quantity,
    // or if the user actively expanded it
    final showStepper = _isExpanded || widget.selectedQty > 0;

    // Visual State Logic for Trade Type
    final isWholesale = widget.source.tradeType == 'WHOLESALE';
    final badgeColor = isWholesale ? Colors.blue.shade50 : Colors.green.shade50;
    final badgeTextColor = isWholesale
        ? Colors.blue.shade700
        : Colors.green.shade700;
    final badgeText = isOwn
        ? 'PROPIO'
        : (isWholesale ? 'MAYORISTA' : 'MINORISTA');

    // Stock Styling
    final hasStock = isOwn ? true : widget.source.maxStock > 0;
    final stockColor = hasStock
        ? colors.onSecondaryContainer
        : colors.onErrorContainer;
    final stockBgColor = hasStock
        ? colors.secondaryContainer
        : colors.errorContainer;
    final stockText = isOwn
        ? 'Stock Ilimitado'
        : (hasStock
              ? '${widget.source.maxStock.truncateToDouble() == widget.source.maxStock ? widget.source.maxStock.toInt() : widget.source.maxStock} ${widget.uom}'
              : 'Sin stock');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      child: InkWell(
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
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VerificationScreen(),
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
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ],
                ),
              ),
            );
            return;
          }

          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: isOwn
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: isOwn ? null : const EdgeInsets.only(top: 2),
                    child: Checkbox(
                      value: checkboxState,
                      tristate: true,
                      activeColor: colors.primary,
                      side: BorderSide(
                        color: checkboxState == false
                            ? colors.onSurfaceVariant
                            : colors.primary,
                        width: 2,
                      ),
                      onChanged: shouldShowSnackBar
                          ? null
                          : (bool? newValue) {
                              if (checkboxState == false) {
                                widget.onSelectAll();
                              } else {
                                widget.onDeselectAll();
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isOwn
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        if (!isOwn) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          widget.source.sourceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.source.location != null &&
                            widget.source.location!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.source.location!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: 13,
                                        color: colors.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: isOwn
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (shouldShowSnackBar)
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ImageFiltered(
                            imageFilter: shouldShowSnackBar
                                ? ImageFilter.blur(sigmaX: 4, sigmaY: 4)
                                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                            child: Text(
                              isOwn
                                  ? 'Costo Base'
                                  : CurrencyFormatter.format(
                                      widget.source.price,
                                    ),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: stockBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Symbols.package_2,
                              size: 14,
                              color: stockColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              stockText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: stockColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (showStepper) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Cantidad:',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _QuantitySelector(
                      value: widget.selectedQty,
                      min: 0,
                      max: maxQty,
                      onChanged: widget.onQtyChanged,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _QuantitySelector({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > min
              ? () => onChanged((value - 1).clamp(min, max))
              : null,
          icon: const Icon(Icons.remove),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          color: colors.primary,
        ),
        Container(
          width: 50,
          alignment: Alignment.center,
          child: Text(
            value.truncateToDouble() == value
                ? value.toInt().toString()
                : value.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        IconButton(
          onPressed: value < max
              ? () => onChanged((value + 1).clamp(min, max))
              : null,
          icon: const Icon(Icons.add),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          color: colors.primary,
        ),
      ],
    );
  }
}
