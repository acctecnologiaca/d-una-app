import 'package:d_una_app/features/portfolio/domain/models/product_search_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/aggregated_product.dart';
import '../../../presentation/providers/suppliers_provider.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../widgets/aggregated_product_card.dart';
import 'package:go_router/go_router.dart';

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

class ProductSuppliersScreen extends ConsumerWidget {
  final AggregatedProduct product;
  final ProductSearchFilters? filters;

  const ProductSuppliersScreen({
    super.key,
    required this.product,
    this.filters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(
      productSuppliersProvider((product: product, filters: filters)),
    );
    final userProfileAsync = ref.watch(userProfileProvider);
    final userProfile = userProfileAsync.valueOrNull;

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Proveedores y sucursales disponibles'),
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
          // Product Summary Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: colors.surface,
            child: AggregatedProductCard(
              product: product,
              onTap: () {},
              showPriceAndStock: false,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Precios no incluyen impuesto y pueden variar sin previo aviso',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: suppliersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (items) {
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
                          'No hay proveedores disponibles',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colors.outlineVariant.withOpacity(0.2),
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final supplierName = item['supplier_name'] as String;
                    final tradeType =
                        item['supplier_trade_type'] as String? ?? 'RETAIL';
                    final branchCity = item['branch_city'] as String? ?? '';
                    final price = (item['price'] as num).toDouble();
                    final stock = item['stock_quantity'] as int;
                    final uom = item['uom'] as String? ?? 'Unidad';

                    final isVerifyRequired = tradeType == 'WHOLESALE';

                    // Access Logic
                    bool isLocked = false;
                    if (userProfile != null) {
                      final isBusiness =
                          userProfile.verificationType == 'business';
                      if (!isBusiness && isVerifyRequired) {
                        isLocked = true;
                      }
                    }

                    return InkWell(
                      onTap: isLocked ? null : () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Side: Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: tradeType == 'WHOLESALE'
                                              ? Colors.blue.shade50
                                              : Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          tradeType == 'WHOLESALE'
                                              ? 'MAYORISTA'
                                              : 'MINORISTA',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                            color: tradeType == 'WHOLESALE'
                                                ? Colors.blue.shade700
                                                : Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          supplierName,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: colors.onSurface,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isLocked)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 6,
                                          ),
                                          child: Icon(
                                            Icons.lock_outline,
                                            size: 14,
                                            color: colors.outline,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: colors.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        branchCity,
                                        style: textTheme.bodySmall?.copyWith(
                                          fontSize: 13,
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Right Side: Price & Stock
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${price.toStringAsFixed(2)}',
                                  style: textTheme.titleLarge?.copyWith(
                                    // Consistent large price
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: colors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    stock > 0 ? '$stock $uom' : 'Sin stock',
                                    style: textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: stock > 0
                                          ? colors.onSurfaceVariant
                                          : colors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
