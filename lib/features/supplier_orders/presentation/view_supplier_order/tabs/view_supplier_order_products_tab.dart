import 'package:flutter/material.dart';
import '../../../domain/models/supplier_order.dart';
import '../../../domain/models/supplier_order_item.dart';
import '../../../domain/models/supplier_order_status.dart';
import '../../create_supplier_order/widgets/supplier_order_added_product_card.dart';

class ViewSupplierOrderProductsTab extends StatelessWidget {
  final SupplierOrder order;
  final List<SupplierOrderItem> items;

  const ViewSupplierOrderProductsTab({
    super.key,
    required this.order,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final canShowAlerts =
        order.status == SupplierOrderStatus.sent ||
        order.status == SupplierOrderStatus.resent;

    // Group items by product key: "${item.name}|${item.brand ?? ''}|${item.model ?? ''}"
    final Map<String, List<SupplierOrderItem>> groups = {};
    for (final item in items) {
      final key = "${item.name}|${item.brand ?? ''}|${item.model ?? ''}";
      groups.putIfAbsent(key, () => []).add(item);
    }

    final keysList = groups.keys.toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 100),
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

          final bool isCompleted =
              order.status == SupplierOrderStatus.finalized ||
              order.status == SupplierOrderStatus.cancelled;

          final double? totalAvailableStock =
              isCompleted ||
                  groupItems.any((item) => item.currentSupplierStock == null)
              ? null
              : groupItems.fold<double>(
                  0.0,
                  (sum, item) => sum + (item.currentSupplierStock ?? 0.0),
                );

          final hasPriceIncrease =
              canShowAlerts && groupItems.any((item) => item.hasPriceIncrease);
          final isOutOfStock =
              canShowAlerts && groupItems.any((item) => item.isOutOfStock);
          final hasLowStock =
              canShowAlerts && groupItems.any((item) => item.hasLowStock);

          return Padding(
            padding: const EdgeInsets.only(bottom: 0.0),
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
              isReadOnly: true,
              // Required callbacks (ignored in read-only mode)
              onDelete: () {},
              onEditSources: () {},
              onQuantityChanged: (_) {},
            ),
          );
        },
      ),
    );
  }
}
