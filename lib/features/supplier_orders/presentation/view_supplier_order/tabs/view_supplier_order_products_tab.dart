import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/supplier_order.dart';
import '../../../domain/models/supplier_order_item.dart';
import '../../../domain/models/supplier_order_status.dart';
import '../../create_supplier_order/widgets/supplier_order_added_product_card.dart';
import '../../create_supplier_order/providers/supplier_order_validation_provider.dart';
import '../../supplier_orders_list/providers/supplier_orders_providers.dart';

class ViewSupplierOrderProductsTab extends ConsumerStatefulWidget {
  final SupplierOrder order;
  final List<SupplierOrderItem> items;
  final double bottomPadding;

  const ViewSupplierOrderProductsTab({
    super.key,
    required this.order,
    required this.items,
    this.bottomPadding = 112.0,
  });

  @override
  ConsumerState<ViewSupplierOrderProductsTab> createState() =>
      _ViewSupplierOrderProductsTabState();
}

class _ViewSupplierOrderProductsTabState
    extends ConsumerState<ViewSupplierOrderProductsTab> {
  bool _showRefreshHint = true;
  Timer? _hintTimer;

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canShowAlerts = widget.order.canShowAlerts;
    final validationState = ref.watch(supplierOrderValidationProvider(widget.items));

    if (widget.items.isNotEmpty &&
        canShowAlerts &&
        _showRefreshHint &&
        _hintTimer == null) {
      _hintTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _showRefreshHint = false);
        }
      });
    }

    // Group items by product key: "${item.name}|${item.brand ?? ''}|${item.model ?? ''}"
    final Map<String, List<SupplierOrderItem>> groups = {};
    for (final item in widget.items) {
      final key = "${item.name}|${item.brand ?? ''}|${item.model ?? ''}";
      groups.putIfAbsent(key, () => []).add(item);
    }

    final keysList = groups.keys.toList();

    return Column(
      children: [
        if (canShowAlerts && validationState.isValidating)
          const LinearProgressIndicator(minHeight: 2)
        else
          const SizedBox(height: 2),
        if (canShowAlerts)
          AnimatedSize(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: _showRefreshHint
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Desliza hacia abajo para actualizar disponibilidad y precios actuales',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(supplierOrderDetailProvider(widget.order.id));
              await ref
                  .read(supplierOrderValidationProvider(widget.items).notifier)
                  .validate();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(left: 0, right: 0, top: 0, bottom: widget.bottomPadding),
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
                    widget.order.status == SupplierOrderStatus.finalized ||
                    widget.order.status == SupplierOrderStatus.cancelled;

                double? totalAvailableStock;
                if (!isCompleted) {
                  double stockSum = 0.0;
                  bool hasStockData = false;
                  for (final item in groupItems) {
                    final valItem = validationState.items[item.id];
                    if (valItem != null) {
                      stockSum += valItem.currentStock;
                      hasStockData = true;
                    } else if (item.currentSupplierStock != null) {
                      stockSum += item.currentSupplierStock!;
                      hasStockData = true;
                    }
                  }
                  if (hasStockData) {
                    totalAvailableStock = stockSum;
                  }
                }

                bool hasPriceIncrease = false;
                bool isOutOfStock = false;
                bool hasLowStock = false;

                if (canShowAlerts) {
                  for (final item in groupItems) {
                    final valItem = validationState.items[item.id];
                    if (valItem != null) {
                      if (valItem.statuses.contains(SupplierOrderValidationStatus.priceIncreased)) {
                        hasPriceIncrease = true;
                      }
                      if (valItem.statuses.contains(SupplierOrderValidationStatus.outOfStock)) {
                        isOutOfStock = true;
                      } else if (valItem.statuses.contains(SupplierOrderValidationStatus.lowStock)) {
                        hasLowStock = true;
                      }
                    } else {
                      if (item.hasPriceIncrease) {
                        hasPriceIncrease = true;
                      }
                      if (item.isOutOfStock) {
                        isOutOfStock = true;
                      } else if (item.hasLowStock) {
                        hasLowStock = true;
                      }
                    }
                  }
                }

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
          ),
        ),
      ],
    );
  }
}
