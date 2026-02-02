import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import 'package:d_una_app/shared/widgets/filter_bottom_sheet.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';
import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';
import 'package:d_una_app/features/portfolio/domain/models/aggregated_product.dart';
import 'package:d_una_app/features/portfolio/presentation/suppliers_directory/widgets/compact_supplier_card.dart';
import 'package:d_una_app/features/portfolio/presentation/suppliers_directory/widgets/aggregated_product_card.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/product_search_provider.dart';

class SupplierSearchScreen extends ConsumerStatefulWidget {
  const SupplierSearchScreen({super.key});

  @override
  ConsumerState<SupplierSearchScreen> createState() =>
      _SupplierSearchScreenState();
}

class _SupplierSearchScreenState extends ConsumerState<SupplierSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';
  // View State
  bool _viewAllSuppliers = false;
  Timer? _debounce;

  // Suppliers Filter State (Kept for compatibility, though mainly for general list)
  final Set<String> _selectedTradeTypes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  // Reuse existing filter logic
  void _showTradeTypeFilter(List<Supplier> suppliers) {
    final availableTypes = suppliers
        .map((e) => e.tradeType)
        .where((e) => e != null)
        .cast<String>()
        .toSet()
        .toList();

    String getLabel(String value) {
      switch (value) {
        case 'WHOLESALE':
          return 'Mayorista';
        case 'RETAIL':
          return 'Minorista';
        case 'BOTH':
          return 'Mayorista / Minorista';
        default:
          return value;
      }
    }

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Tipo de Comercio',
      options: availableTypes,
      selectedValues: _selectedTradeTypes,
      labelBuilder: getLabel,
      onApply: (selected) {
        setState(() {
          _selectedTradeTypes.clear();
          _selectedTradeTypes.addAll(selected);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final suppliersAsync = ref.watch(suppliersProvider);
    final productsAsync = ref.watch(
      productSearchProvider(_searchQuery.normalized),
    );

    return PopScope(
      canPop: !_viewAllSuppliers,
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() {
          _viewAllSuppliers = false;
        });
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
            onPressed: () {
              if (_viewAllSuppliers) {
                setState(() {
                  _viewAllSuppliers = false;
                });
              } else {
                context.pop();
              }
            },
          ),
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _viewAllSuppliers
                ? Text(
                    'Proveedores',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : CustomSearchBar(
                    controller: _searchController,
                    focusNode: _focusNode,
                    hintText: 'Buscar proveedores, productos...',
                    onChanged: _onSearchChanged,
                    autoFocus: false, // Already focused in InitState
                  ),
          ),
        ),
        body: _buildBody(context, suppliersAsync, productsAsync),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<Supplier>> suppliersAsync,
    AsyncValue<List<AggregatedProduct>> productsAsync,
  ) {
    final colors = Theme.of(context).colorScheme;

    if (_searchQuery.isEmpty && !_viewAllSuppliers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              'Escribe para buscar...',
              style: TextStyle(color: colors.outline),
            ),
          ],
        ),
      );
    }

    // Filter Suppliers
    List<Supplier> matchedSuppliers = [];
    suppliersAsync.whenData((list) {
      matchedSuppliers = list.where((s) {
        final matchesName = s.name.normalized.contains(_searchQuery.normalized);
        final matchesType =
            _selectedTradeTypes.isEmpty ||
            (s.tradeType != null && _selectedTradeTypes.contains(s.tradeType));
        return matchesName && matchesType;
      }).toList();
    });

    if (_viewAllSuppliers) {
      // Full Supplier List View
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: matchedSuppliers.length,
        itemBuilder: (context, index) => CompactSupplierCard(
          supplier: matchedSuppliers[index],
          onTap: () {},
        ),
      );
    }

    // Unified Sectioned View
    return CustomScrollView(
      slivers: [
        // 1. Suppliers Section (if matches)
        if (matchedSuppliers.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Proveedores',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  if (matchedSuppliers.length > 3)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _viewAllSuppliers = true;
                        });
                      },
                      child: const Text('Ver todo'),
                    ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CompactSupplierCard(
                  supplier: matchedSuppliers[index],
                  onTap: () {},
                ),
              ),
              childCount: matchedSuppliers.length > 3
                  ? 3
                  : matchedSuppliers.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(
              height: 32,
              thickness: 1,
              color: colors.outlineVariant.withOpacity(0.5),
            ),
          ),
        ],

        // 2 & 3. Products Section (Title + List handled together)
        productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              // If both lists are empty, show "No results"
              if (matchedSuppliers.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: colors.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron resultados',
                          style: TextStyle(color: colors.outline),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // If only products are empty, hide the section
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            // Show Title + Products
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Index 0: Section Title
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'Productos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                    );
                  }
                  // Index > 0: Product Items
                  // Note: index is 1-based relative to this delegate, so we use index-1 for data
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AggregatedProductCard(
                      product: products[index - 1],
                      onTap: () {},
                    ),
                  );
                },
                childCount: products.length + 1, // +1 for Title
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (err, stack) =>
              SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
        ),

        // Bottom Padding
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
