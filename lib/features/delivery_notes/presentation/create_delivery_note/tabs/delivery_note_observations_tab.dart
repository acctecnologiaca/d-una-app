import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/create_delivery_note_provider.dart';

class DeliveryNoteObservationsTab extends ConsumerWidget {
  const DeliveryNoteObservationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createDeliveryNoteProvider);

    if (state.observations.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.notes,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay observaciones agregadas',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(
        top: 12,
        left: 0,
        right: 0,
        bottom: 88,
      ),
      itemCount: state.observations.length,
      onReorder: (oldIndex, newIndex) {
        ref
            .read(createDeliveryNoteProvider.notifier)
            .reorderObservations(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final observation = state.observations[index];
        return Card(
          key: ValueKey(
            (observation.id != null && observation.id!.isNotEmpty)
                ? observation.id!
                : (observation.observationId ?? 'obs_$index'),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide.none,
          ),
          child: ListTile(
            leading: Icon(
              Icons.drag_handle,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(observation.description),
            trailing: IconButton(
              icon: Icon(
                Symbols.close_small,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                ref
                    .read(createDeliveryNoteProvider.notifier)
                    .removeObservation(index);
              },
            ),
          ),
        );
      },
    );
  }
}
