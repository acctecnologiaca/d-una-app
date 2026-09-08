import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';

class ViewDeliveryNoteDetailsTab extends ConsumerWidget {
  final String noteId;
  final double bottomPadding;

  const ViewDeliveryNoteDetailsTab({
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
        child: Text('Error al cargar detalles: $e'),
      ),
      data: (note) {
        if (note == null) {
          return const Center(
            child: Text('No se encontró la información de la nota de entrega'),
          );
        }

        final dateFormat = DateFormat('dd/MM/yyyy');

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Información general',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.calendar_today_outlined,
                label: 'Fecha de Emisión',
                value: dateFormat.format(note.date),
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.receipt_long_outlined,
                label: 'Orden de Compra del Cliente (O/C)',
                value: note.clientPoNumber ?? 'No especificada',
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.tag,
                label: 'Etiqueta',
                value: note.tag ?? 'Sin etiqueta',
              ),
            ],
          ),
        );
      },
    );
  }
}
