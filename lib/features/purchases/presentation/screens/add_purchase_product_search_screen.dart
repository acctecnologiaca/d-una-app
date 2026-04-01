import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/generic_search_screen.dart';
import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:d_una_app/shared/widgets/filter_bottom_sheet.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/features/portfolio/data/models/category_model.dart';
import 'package:d_una_app/features/portfolio/data/models/brand_model.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/purchase_product_list_item.dart';
import 'package:d_una_app/features/purchases/data/models/purchase_item_product.dart';
import 'package:d_una_app/features/purchases/presentation/providers/add_purchase_provider.dart';
import 'package:d_una_app/features/purchases/presentation/widgets/add_purchase_product_details_sheet.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';
import 'package:uuid/uuid.dart';

class AddPurchaseProductSearchScreen extends ConsumerStatefulWidget {
  const AddPurchaseProductSearchScreen({super.key});

  @override
  ConsumerState<AddPurchaseProductSearchScreen> createState() =>
      _AddPurchaseProductSearchScreenState();
}

class _AddPurchaseProductSearchScreenState
    extends ConsumerState<AddPurchaseProductSearchScreen> {
  Set<String> _selectedCategoryIds = {};
  Set<String> _selectedBrandIds = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final products = productsAsync.valueOrNull ?? [];

    final q = _searchQuery.normalized;
    final queryMatchedProducts = q.isEmpty
        ? products
        : products.where((p) {
          return p.name.normalized.contains(q) ||
              (p.brand?.name.normalized ?? '').contains(q) ||
              (p.model?.normalized ?? '').contains(q);
        }).toList();

    // Derive available categories from search results
    final categoryMap = queryMatchedProducts
        .map((p) => p.category)
        .whereType<Category>()
        .fold<Map<String, String>>({}, (map, cat) {
          map[cat.id] = cat.name.toTitleCase;
          return map;
        });

    // Derive available brands from search results
    final brandMap = queryMatchedProducts
        .map((p) => p.brand)
        .whereType<Brand>()
        .fold<Map<String, String>>({}, (map, brand) {
          map[brand.id] = brand.name.toTitleCase;
          return map;
        });

    return GenericSearchScreen<Product>(
      title: 'Buscar producto',
      hintText: 'Nombre, marca o modelo...',
      historyKey: 'purchase_product_selection_search_history',
      data: productsAsync,
      onQueryChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      filters: [
        FilterChipData(
          label: HorizontalFilterBar.formatLabel(
            defaultLabel: 'Categoría',
            selectedValues: _selectedCategoryIds.toList(),
            valueToLabelMap: categoryMap,
          ),
          isActive: _selectedCategoryIds.isNotEmpty,
          onTap: () {
            FilterBottomSheet.showMulti(
              context: context,
              title: 'Categorías',
              options: categoryMap.keys.toList(),
              labelBuilder: (id) => categoryMap[id] ?? 'Desconocida',
              selectedValues: _selectedCategoryIds,
              onApply: (selected) {
                setState(() {
                  _selectedCategoryIds = selected;
                });
              },
            );
          },
        ),
        FilterChipData(
          label: HorizontalFilterBar.formatLabel(
            defaultLabel: 'Marca',
            selectedValues: _selectedBrandIds.toList(),
            valueToLabelMap: brandMap,
          ),
          isActive: _selectedBrandIds.isNotEmpty,
          onTap: () {
            FilterBottomSheet.showMulti(
              context: context,
              title: 'Marcas',
              options: brandMap.keys.toList(),
              labelBuilder: (id) => brandMap[id] ?? 'Desconocida',
              selectedValues: _selectedBrandIds,
              onApply: (selected) {
                setState(() {
                  _selectedBrandIds = selected;
                });
              },
            );
          },
        ),
      ],
      onResetFilters: () {
        setState(() {
          _selectedCategoryIds.clear();
          _selectedBrandIds.clear();
          _searchQuery = '';
        });
      },
      filter: (product, query) {
        final q = query.normalized;
        final name = product.name.normalized;
        final brand = (product.brand?.name ?? '').normalized;
        final model = (product.model ?? '').normalized;

        final matchesQuery =
            name.contains(q) || brand.contains(q) || model.contains(q);

        final matchesCategory =
            _selectedCategoryIds.isEmpty ||
            (product.categoryId != null &&
                _selectedCategoryIds.contains(product.categoryId));

        final matchesBrand =
            _selectedBrandIds.isEmpty ||
            (product.brandId != null &&
                _selectedBrandIds.contains(product.brandId));

        return matchesQuery && matchesCategory && matchesBrand;
      },
      itemBuilder: (context, product) {
        final addedProducts = ref.watch(addPurchaseProvider).products;
        final isAlreadyAdded = addedProducts.any(
          (p) => p.productId == product.id,
        );

        return PurchaseProductListItem(
          brand: product.brand?.name ?? 'Sin marca',
          name: product.name,
          model: product.model ?? 'Sin modelo',
          uom: product.uomModel,
          imageUrl: product.imageUrl,
          enabled: !isAlreadyAdded,
          onDisabledTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'El producto "${product.name}" ya está agregado. Si deseas agregar más unidades, por favor modifica el ya existente.',
                ),
              ),
            );
          },
          onTap: () async {
            final result = await AddPurchaseProductDetailsSheet.show(
              context,
              product: product,
            );
            if (result != null) {
              final qty = (result['quantity'] as num).toDouble();
              final cost = (result['cost_price'] as num).toDouble();
              final wTime = (result['warranty_duration'] as num).toInt();
              final wPeriodStr = result['warranty_period'] as String;
              final usesSerials = result['uses_serials'] == true;

              // Map period to DB value
              final wUnit = wPeriodStr == 'Días'
                  ? 'days'
                  : wPeriodStr == 'Meses'
                  ? 'months'
                  : 'years';

              final item = PurchaseItemProduct(
                id: const Uuid().v4(),
                productId: product.id,
                name: product.name,
                brand: product.brand?.name,
                model: product.model,
                uom: product.uomModel?.symbol ?? 'ud.',
                quantity: qty,
                unitPrice: cost,
                warrantyTime: wTime,
                warrantyUnit: wUnit,
                requiresSerials: usesSerials,
              );

              final added = ref
                  .read(addPurchaseProvider.notifier)
                  .addProduct(item);

              if (!added) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'El producto "${product.name}" ya está agregado.',
                      ),
                    ),
                  );
                }
                return;
              }

              final bool registerNow = result['register_serials_now'] == true;
              if (registerNow) {
                if (context.mounted) {
                  final confirmed = await context.push<bool>(
                    '/my-purchases/add/select-product/manage-serials',
                    extra: <String, dynamic>{
                      'product': product,
                      'quantity': qty.toInt(),
                      'purchaseItemId': item.id,
                    },
                  );
                  if (confirmed == true && context.mounted) {
                    context.pop(); // Pop back from search
                    context.pop(); // Pop back to Add Purchase screen
                  }
                }
              } else {
                if (context.mounted) {
                  context.pop(); // Pop back from search
                  context.pop(); // Pop back to Add Purchase screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Producto agregado: ${product.name}'),
                    ),
                  );
                }
              }
            }
          },
        );
      },
    );
  }
}
