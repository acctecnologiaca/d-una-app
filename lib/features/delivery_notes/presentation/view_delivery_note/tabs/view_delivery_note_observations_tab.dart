import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';

class ViewDeliveryNoteObservationsTab extends ConsumerWidget {
  final String noteId;
  final double bottomPadding;

  const ViewDeliveryNoteObservationsTab({
    super.key,
    required this.noteId,
    this.bottomPadding = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final noteAsync = ref.watch(deliveryNoteDetailProvider(noteId));

    return noteAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error al cargar observaciones: $e'),
      ),
      data: (note) {
        if (note == null) {
          return const Center(
            child: Text('No se encontró la información de la nota de entrega'),
          );
        }

        if (note.observations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Symbols.notes,
                  size: 64,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay observaciones registradas en esta nota de entrega',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
          itemCount: note.observations.length,
          itemBuilder: (context, index) {
            final obs = note.observations[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Symbols.check_circle,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        obs.description,
                        style: textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
