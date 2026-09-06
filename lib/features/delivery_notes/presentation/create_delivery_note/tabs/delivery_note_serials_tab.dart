import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/delivery_note_item_model.dart';
import '../providers/create_delivery_note_provider.dart';
import '../../manage_serials/screens/delivery_note_manage_serials_screen.dart';

class DeliveryNoteSerialsTab extends ConsumerWidget {
  const DeliveryNoteSerialsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createDeliveryNoteProvider);
    final itemsRequiringSerials = state.items
        .where((i) => i.requiresSerials && !i.isDropshipping)
        .toList();

    if (itemsRequiringSerials.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 56,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sin seriales pendientes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Los productos agregados no requieren seriales obligatorios o corresponden a despachos directos por dropshipping.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalRequired = itemsRequiringSerials.fold<int>(
      0,
      (sum, i) => sum + i.quantity.round(),
    );
    final totalAssigned = itemsRequiringSerials.fold<int>(
      0,
      (sum, i) => sum + i.serials.length,
    );
    final progress = totalRequired > 0 ? (totalAssigned / totalRequired) : 1.0;
    final isComplete = totalAssigned >= totalRequired;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Tarjeta resumen de progreso de seriales
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isComplete
                  ? Colors.green.shade300
                  : Colors.amber.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso de seriales',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    '$totalAssigned de $totalRequired asignados',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isComplete
                          ? Colors.green.shade800
                          : Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: colors.surfaceContainerHighest,
                color: isComplete ? Colors.green.shade600 : colors.primary,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Lista de ítems con sus seriales asignados
        ...itemsRequiringSerials.map((item) {
          final actualIndex = state.items.indexOf(item);
          final needed = item.quantity.round();
          final assigned = item.serials.length;
          final itemComplete = assigned >= needed;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: itemComplete
                    ? Colors.green.shade200
                    : colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                    .join(' · '),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          _openManageSerialsScreen(
                            context,
                            ref,
                            item,
                            actualIndex,
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                        label: Text(
                          itemComplete ? 'Editar' : 'Escanear',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Chips con seriales asignados
                  if (item.serials.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.serials.asMap().entries.map((e) {
                        final sIdx = e.key;
                        final serial = e.value;
                        return Chip(
                          label: Text(
                            serial.serialNumber,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            ref
                                .read(createDeliveryNoteProvider.notifier)
                                .removeSerialFromItem(actualIndex, sIdx);
                          },
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        );
                      }).toList(),
                    )
                  else
                    Text(
                      'No se han asignado números de serial aún ($needed requeridos).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _openManageSerialsScreen(
    BuildContext context,
    WidgetRef ref,
    DeliveryNoteItemModel item,
    int itemIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeliveryNoteManageSerialsScreen(
          item: item,
          onSerialsSaved: (newSerials) {
            ref
                .read(createDeliveryNoteProvider.notifier)
                .setSerialsForItem(itemIndex, newSerials);
          },
        ),
      ),
    );
  }
}
