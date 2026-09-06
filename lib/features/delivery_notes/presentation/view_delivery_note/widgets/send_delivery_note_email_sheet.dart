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
      sheetTitle: 'Enviar nota de entrega por correo',
      tag: note.tag,
      clientDisplayName: note.contactName ?? note.clientName,
      generateToken: (ref) =>
          ref.read(deliveryNotesRepositoryProvider).generateActionToken(note.id),
      onStatusUpdate: (ref, _) async {
        final currentStatus = note.status;
        if (currentStatus == DeliveryNoteStatus.draft) {
          await ref
              .read(deliveryNotesRepositoryProvider)
              .updateDeliveryNoteStatus(note.id, DeliveryNoteStatus.sent);
        }
      },
      onSendSuccess: () {
        final container = ProviderScope.containerOf(context, listen: false);
        container.invalidate(deliveryNoteDetailProvider(note.id));
        container.read(paginatedDeliveryNotesProvider.notifier).refresh();
      },
    );
  }
}
