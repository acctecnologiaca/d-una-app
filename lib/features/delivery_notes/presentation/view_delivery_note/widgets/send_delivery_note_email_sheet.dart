import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/send_document_email_sheet.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../../../domain/models/delivery_note_status.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';

class SendDeliveryNoteEmailSheet {
  SendDeliveryNoteEmailSheet._();

  static Future<void> show(BuildContext context, DeliveryNoteModel note) {
    return SendDocumentEmailSheet.show(
      context: context,
      documentId: note.id,
      documentType: 'delivery_note',
      documentNumber: note.deliveryNoteNumber,
      initialRecipient: note.contactEmail ?? note.clientEmail,
      sheetTitle: note.status == DeliveryNoteStatus.finalized
          ? 'Enviar copia de nota de entrega por correo'
          : 'Enviar nota de entrega por correo',
      tag: note.tag,
      clientDisplayName: note.contactName ?? note.clientName,
      generateToken: (ref) =>
          ref.read(deliveryNotesRepositoryProvider).generateActionToken(note.id),
      onStatusUpdate: (ref, _) async {
        if (note.status == DeliveryNoteStatus.finalized) {
          return;
        }
        final currentStatus = note.status;
        final newStatus = (currentStatus == DeliveryNoteStatus.sent ||
                currentStatus == DeliveryNoteStatus.resent ||
                currentStatus == DeliveryNoteStatus.opened)
            ? DeliveryNoteStatus.resent
            : DeliveryNoteStatus.sent;

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final currentDeliveryDate = note.deliveryDate;
        final shouldUpdateDeliveryDate = currentDeliveryDate == null ||
            DateTime(currentDeliveryDate.year, currentDeliveryDate.month, currentDeliveryDate.day).isBefore(today);

        await ref
            .read(deliveryNotesRepositoryProvider)
            .updateDeliveryNoteStatus(
              note.id,
              newStatus,
              deliveryDate: shouldUpdateDeliveryDate ? today : null,
            );
      },
      onSendSuccess: () {
        final container = ProviderScope.containerOf(context, listen: false);
        container.invalidate(deliveryNoteDetailProvider(note.id));
        container.read(paginatedDeliveryNotesProvider.notifier).refresh();
      },
    );
  }
}
