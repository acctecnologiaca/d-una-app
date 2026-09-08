import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/empty_list_state.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';
import '../../create_delivery_note/widgets/delivery_note_added_product_card.dart';
import '../widgets/view_delivery_note_product_details_sheet.dart';

class ViewDeliveryNoteItemsTab extends ConsumerWidget {
  final String noteId;
  final double bottomPadding;

  const ViewDeliveryNoteItemsTab({
    super.key,
    required this.noteId,
    this.bottomPadding = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final noteAsync = ref.watch(deliveryNoteDetailProvider(noteId));

    return noteAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error al cargar productos: $e'),
      ),
      data: (note) {
        if (note == null) {
          return const Center(
            child: Text('No se encontró la información de la nota de entrega'),
          );
        }

        if (note.items.isEmpty) {
          return const EmptyListState(
            icon: Symbols.package_2,
            message: 'No hay productos en esta nota de entrega',
          );
        }

        final hasMissing = note.hasMissingSerials;

        return ListView.builder(
          padding: EdgeInsets.only(top: 8, bottom: bottomPadding),
          itemCount: note.items.length + (hasMissing ? 1 : 0),
          itemBuilder: (context, index) {
            if (hasMissing && index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.errorContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.error.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colors.error,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Atención: Hay productos con seriales pendientes por asignar.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final itemIndex = hasMissing ? index - 1 : index;
            final item = note.items[itemIndex];

            return DeliveryNoteAddedProductCard(
              item: item,
              isReadOnly: true,
              onTap: () => ViewDeliveryNoteProductDetailsSheet.show(
                context,
                item: item,
              ),
            );
          },
        );
      },
    );
  }
}
