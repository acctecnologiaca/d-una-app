import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/friendly_error_widget.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../../portfolio/domain/models/aggregated_product.dart';
import '../../../domain/models/supplier_order_item.dart';
import '../providers/create_supplier_order_provider.dart';
import '../providers/supplier_order_product_selection_provider.dart';
import '../widgets/supplier_order_branch_card.dart';

class SupplierOrderProductBranchesScreen extends ConsumerStatefulWidget {
  final AggregatedProduct product;
  final Map<String, double>? initialSelections;
  final bool isEditing;

  const SupplierOrderProductBranchesScreen({
    super.key,
    required this.product,
    this.initialSelections,
    this.isEditing = false,
  });

  @override
  ConsumerState<SupplierOrderProductBranchesScreen> createState() =>
      _SupplierOrderProductBranchesScreenState();
}

class _SupplierOrderProductBranchesScreenState
    extends ConsumerState<SupplierOrderProductBranchesScreen> {
  // Maps supplier_branch_stock_id to selected quantity
  final Map<String, double> _selectedQuantities = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSelections != null) {
      _selectedQuantities.addAll(widget.initialSelections!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final orderState = ref.watch(createSupplierOrderProvider);
    final supplierId = orderState.supplierId ?? '';

    final branchesAsync = ref.watch(
      supplierOrderProductBranchesProvider(
        supplierId: supplierId,
        product: widget.product,
      ),
    );

    double totalQuantity = _selectedQuantities.values.fold(
      0.0,
      (sum, val) => sum + val,
    );

    return Scaffold(
      appBar: const StandardAppBar(title: 'Seleccionar sucursal y cantidad'),
      body: Column(
        children: [
          // Product header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colors.surfaceContainerLowest,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.product.brand.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      widget.product.brand,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                Text(
                  widget.product.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                if (widget.product.model.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.product.model.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Precios no incluyen impuesto y pueden variar sin previo aviso',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: branchesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => FriendlyErrorWidget(
                error: error,
                onRetry: () =>
                    ref.invalidate(supplierOrderProductBranchesProvider),
              ),
              data: (branches) {
                if (branches.isEmpty) {
                  return const Center(
                    child: Text('No hay sucursales disponibles.'),
                  );
                }
                return ListView.builder(
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    final branchData = branches[index];
                    final stockId =
                        branchData['supplier_branch_stock_id'] as String;
                    final price = ((branchData['price'] ?? 0.0) as num)
                        .toDouble();
                    final stock =
                        ((branchData['stock_quantity'] ??
                                    branchData['stock'] ??
                                    0)
                                as num)
                            .toInt();
                    final cityName =
                        (branchData['branch_city'] ?? branchData['city_name'])
                            as String? ??
                        'Ciudad Desconocida';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: SupplierOrderBranchCard(
                        branchCity: cityName,
                        price: price,
                        stock: stock,
                        uom: widget.product.uom,
                        uomIconName: widget.product.uomIconName,
                        selectedQty: _selectedQuantities[stockId] ?? 0.0,
                        onQtyChanged: (val) {
                          setState(() {
                            if (val == 0) {
                              _selectedQuantities.remove(stockId);
                            } else {
                              _selectedQuantities[stockId] = val;
                            }
                          });
                        },
                        onSelectAll: () {
                          setState(() {
                            _selectedQuantities[stockId] = stock.toDouble();
                          });
                        },
                        onDeselectAll: () {
                          setState(() {
                            _selectedQuantities.remove(stockId);
                          });
                        },
                      ),
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
          onPressed: () {
            final branchesList = branchesAsync.valueOrNull ?? [];
            final notifier = ref.read(createSupplierOrderProvider.notifier);
            final productKey =
                "${widget.product.name}|${widget.product.brand}|${widget.product.model}";

            final newItems = <SupplierOrderItem>[];
            for (final entry in _selectedQuantities.entries) {
              if (entry.value > 0) {
                final branch = branchesList.firstWhere(
                  (b) => b['supplier_branch_stock_id'] == entry.key,
                );
                final price = (branch['price'] as num).toDouble();
                final stock = ((branch['stock_quantity'] ??
                            branch['stock'] ??
                            0) as num)
                    .toDouble();
                final supplierProductId = branch['product_id'] as String?;

                newItems.add(
                  SupplierOrderItem(
                    id: const Uuid().v4(),
                    supplierOrderId: orderState.id ?? '',
                    productId: supplierProductId,
                    name: widget.product.name,
                    brand: widget.product.brand.isEmpty
                        ? null
                        : widget.product.brand,
                    model: widget.product.model.isEmpty
                        ? null
                        : widget.product.model,
                    uom: widget.product.uom,
                    uomIconName: widget.product.uomIconName,
                    quantity: entry.value,
                    unitPrice: price,
                    supplierBranchStockId: entry.key,
                    currentSupplierStock: stock,
                  ),
                );
              }
            }

            if (widget.isEditing) {
              notifier.replaceProductItems(productKey, newItems);
            } else {
              for (final item in newItems) {
                notifier.addItem(
                  productId: item.productId,
                  name: item.name,
                  brand: item.brand,
                  model: item.model,
                  uom: item.uom,
                  uomIconName: item.uomIconName,
                  quantity: item.quantity,
                  unitPrice: item.unitPrice,
                  supplierBranchStockId: item.supplierBranchStockId,
                  currentSupplierStock: item.currentSupplierStock,
                );
              }
            }

            context.pop(true);
          },
          icon: Icons.check,
          label:
              'Confirmar (${totalQuantity.toStringAsFixed(totalQuantity.truncateToDouble() == totalQuantity ? 0 : 2)} ${widget.product.uom})',
          isEnabled: totalQuantity > 0,
        ),
      ),
    );
  }
}
