import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/empty_list_state.dart';
import '../../../domain/models/delivery_note_item_model.dart';
import '../providers/create_delivery_note_provider.dart';
import '../widgets/edit_delivery_note_item_dialog.dart';

class DeliveryNoteItemsTab extends ConsumerWidget {
  final VoidCallback? onManageSerialsPressed;

  const DeliveryNoteItemsTab({
    super.key,
    this.onManageSerialsPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createDeliveryNoteProvider);
    final items = state.items;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmptyListState(
                    icon: Icons.inventory_2_outlined,
                    message: 'No hay productos agregados a la nota de entrega.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddItemDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar producto'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Tarjeta resumen de totales y estado de seriales
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${items.length} ${items.length == 1 ? "producto" : "productos"} (${state.items.fold<int>(0, (sum, i) => sum + i.quantity.round())} unidades)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Subtotal: ${currencyFormat.format(state.subtotal)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.hasMissingSerials)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade400),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade900),
                              const SizedBox(width: 6),
                              Text(
                                '${state.missingSerialsCount} sin serial',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Lista de productos
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildItemCard(context, ref, item, index, colors, currencyFormat);
                }),
                const SizedBox(height: 12),

                // 3. Botón para agregar más productos
                OutlinedButton.icon(
                  onPressed: () => _showAddItemDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar otro producto'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    WidgetRef ref,
    DeliveryNoteItemModel item,
    int index,
    ColorScheme colors,
    NumberFormat currencyFormat,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Nombre y Menú de acciones
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.brand != null || item.model != null)
                        Text(
                          [item.brand, item.model]
                              .whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .join(' · '),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: colors.error,
                  tooltip: 'Eliminar producto',
                  onPressed: () {
                    ref.read(createDeliveryNoteProvider.notifier).removeItem(index);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Badges de origen, dropshipping y seriales
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildSourceBadge(item.sourceType, colors),
                if (item.isDropshipping)
                  _buildBadge(
                    label: 'Dropshipping',
                    color: Colors.teal.shade800,
                    bgColor: Colors.teal.shade50,
                    borderColor: Colors.teal.shade200,
                    icon: Icons.local_shipping_outlined,
                  ),
                if (item.requiresSerials && !item.isDropshipping)
                  if (item.hasMissingSerials)
                    _buildBadge(
                      label: 'Faltan ${item.missingSerialsCount} seriales',
                      color: Colors.amber.shade900,
                      bgColor: Colors.amber.shade50,
                      borderColor: Colors.amber.shade300,
                      icon: Icons.warning_amber_rounded,
                    )
                  else
                    _buildBadge(
                      label: '${item.serials.length} seriales asignados',
                      color: Colors.green.shade800,
                      bgColor: Colors.green.shade50,
                      borderColor: Colors.green.shade300,
                      icon: Icons.check_circle_outline,
                    ),
              ],
            ),
            const Divider(height: 20),

            // Cantidades, precio y botón de seriales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity} ${item.uom} × ${currencyFormat.format(item.unitPrice)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      currencyFormat.format(item.totalPrice),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                if (item.requiresSerials && !item.isDropshipping)
                  TextButton.icon(
                    onPressed: () {
                      onManageSerialsPressed?.call();
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: const Text('Seriales', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge(String sourceType, ColorScheme colors) {
    switch (sourceType) {
      case 'affiliated':
        return _buildBadge(
          label: 'Proveedor afiliado',
          color: Colors.blue.shade800,
          bgColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade200,
          icon: Icons.verified_outlined,
        );
      case 'external':
        return _buildBadge(
          label: 'Proveedor externo',
          color: Colors.orange.shade800,
          bgColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade200,
          icon: Icons.store_outlined,
        );
      default:
        return _buildBadge(
          label: 'Inventario propio',
          color: colors.primary,
          bgColor: colors.primaryContainer.withValues(alpha: 0.5),
          borderColor: colors.primary.withValues(alpha: 0.3),
          icon: Icons.inventory_2_outlined,
        );
    }
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => EditDeliveryNoteItemDialog(
        onSave: (newItem) {
          ref.read(createDeliveryNoteProvider.notifier).addItem(newItem);
        },
      ),
    );
  }
}
