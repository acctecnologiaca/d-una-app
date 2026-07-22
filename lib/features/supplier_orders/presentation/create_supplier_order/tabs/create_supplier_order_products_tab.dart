import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../../portfolio/domain/models/aggregated_product.dart';
import '../../../domain/models/supplier_order_item.dart';
import '../providers/create_supplier_order_provider.dart';
import '../widgets/supplier_order_added_product_card.dart';

class CreateSupplierOrderProductsTab extends ConsumerWidget {
  const CreateSupplierOrderProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createSupplierOrderProvider);
    final colors = Theme.of(context).colorScheme;

    final hasSupplier =
        state.supplierId != null && state.supplierId!.isNotEmpty;

    if (state.items.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.package_2,
                size: 64,
                color: colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay productos agregados',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
              ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: CustomExtendedFab(
            onPressed: () => _addProduct(context),
            icon: Icons.add,
            label: 'Agregar',
            isEnabled: hasSupplier,
          ),
        ),
      );
    }

    // Group items by product key: "${item.name}|${item.brand ?? ''}|${item.model ?? ''}"
    final Map<String, List<SupplierOrderItem>> groups = {};
    for (final item in state.items) {
      final key = "${item.name}|${item.brand ?? ''}|${item.model ?? ''}";
      groups.putIfAbsent(key, () => []).add(item);
    }

    final keysList = groups.keys.toList();

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
        itemCount: keysList.length,
        itemBuilder: (context, index) {
          final productKey = keysList[index];
          final groupItems = groups[productKey]!;
          final firstItem = groupItems.first;

          final totalQuantity = groupItems.fold(
            0.0,
            (sum, item) => sum + item.quantity,
          );
          final totalCost = groupItems.fold(
            0.0,
            (sum, item) => sum + item.total,
          );
          final averageUnitPrice = totalQuantity > 0
              ? totalCost / totalQuantity
              : 0.0;

          final double? totalAvailableStock = groupItems.every((item) => item.currentSupplierStock == null)
              ? null
              : groupItems.fold<double>(
                  0.0,
                  (sum, item) => sum + (item.currentSupplierStock ?? 0.0),
                );

          final hasPriceIncrease = groupItems.any(
            (item) => item.hasPriceIncrease,
          );
          final isOutOfStock = groupItems.any((item) => item.isOutOfStock);
          final hasLowStock = groupItems.any((item) => item.hasLowStock);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SupplierOrderAddedProductCard(
              name: firstItem.name,
              brand: firstItem.brand,
              model: firstItem.model,
              totalQuantity: totalQuantity,
              averageUnitPrice: averageUnitPrice,
              totalCost: totalCost,
              uom: firstItem.uom,
              uomIconName: firstItem.uomIconName,
              totalAvailableStock: totalAvailableStock,
              hasPriceIncrease: hasPriceIncrease,
              isOutOfStock: isOutOfStock,
              hasLowStock: hasLowStock,
              onDelete: () {
                final notifier = ref.read(createSupplierOrderProvider.notifier);
                for (final item in groupItems) {
                  notifier.removeItem(item.id);
                }
              },
              onEditSources: () {
                final initialSelections = <String, double>{};
                for (final item in groupItems) {
                  if (item.supplierBranchStockId != null) {
                    initialSelections[item.supplierBranchStockId!] =
                        item.quantity;
                  }
                }

                final product = AggregatedProduct(
                  name: firstItem.name,
                  brand: firstItem.brand ?? '',
                  model: firstItem.model ?? '',
                  category: 'Sin Categoría',
                  minPrice: groupItems
                      .map((e) => e.unitPrice)
                      .fold(
                        double.infinity,
                        (min, price) => price < min ? price : min,
                      ),
                  totalQuantity: 0,
                  supplierCount: 1,
                  uom: firstItem.uom,
                  uomIconName: firstItem.uomIconName,
                );

                context.push(
                  '/supplier-orders/create/select-product/branches',
                  extra: {
                    'product': product,
                    'initialSelections': initialSelections,
                    'isEditing': true,
                  },
                );
              },
              onQuantityChanged: (newQty) {
                ref
                    .read(createSupplierOrderProvider.notifier)
                    .updateGroupQuantity(productKey, newQty);
              },
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          onPressed: () => _addProduct(context),
          icon: Icons.add,
          label: 'Agregar',
          isEnabled: hasSupplier,
        ),
      ),
    );
  }

  void _addProduct(BuildContext context) {
    context.push('/supplier-orders/create/select-product');
  }
}
