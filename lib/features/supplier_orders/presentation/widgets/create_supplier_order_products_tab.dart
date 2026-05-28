import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../providers/create_supplier_order_provider.dart';
import 'add_order_product_sheet.dart';

class CreateSupplierOrderProductsTab extends ConsumerWidget {
  const CreateSupplierOrderProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createSupplierOrderProvider);
    final colors = Theme.of(context).colorScheme;

    if (state.items.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_basket_outlined,
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
          padding: const EdgeInsets.only(bottom: 16.0),
          child: CustomExtendedFab(
            onPressed: () => _addProduct(context, ref),
            icon: Icons.add,
            label: 'Agregar',
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: colors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.brand ?? "Sin marca"} • ${item.model ?? "Sin modelo"}',
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${CurrencyFormatter.format(item.unitPrice)} x ${item.quantity} ${item.uom}',
                          style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(item.total),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _editItem(context, ref, item.id, item.quantity, item.unitPrice),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: colors.error, size: 20),
                            onPressed: () {
                              ref.read(createSupplierOrderProvider.notifier).removeItem(item.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: CustomExtendedFab(
          onPressed: () => _addProduct(context, ref),
          icon: Icons.add,
          label: 'Agregar',
        ),
      ),
    );
  }

  Future<void> _addProduct(BuildContext context, WidgetRef ref) async {
    final result = await AddOrderProductSheet.show(context);
    if (result != null) {
      ref.read(createSupplierOrderProvider.notifier).addItem(
            productId: result['productId'] as String?,
            name: result['name'] as String,
            brand: result['brand'] as String?,
            model: result['model'] as String?,
            uom: result['uom'] as String,
            quantity: result['quantity'] as double,
            unitPrice: result['unitPrice'] as double,
          );
    }
  }

  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    String itemId,
    double initialQty,
    double initialPrice,
  ) async {
    final formKey = GlobalKey<FormState>();
    final qtyController = TextEditingController(text: initialQty.toString());
    final priceController = TextEditingController(text: initialPrice.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Item'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: qtyController,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || double.tryParse(val) == null || double.parse(val) <= 0) {
                      return 'Cantidad inválida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Precio Unitario'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || double.tryParse(val) == null || double.parse(val) < 0) {
                      return 'Precio inválido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      ref.read(createSupplierOrderProvider.notifier).updateItem(
            itemId,
            quantity: double.parse(qtyController.text),
            unitPrice: double.parse(priceController.text),
          );
    }
  }
}
