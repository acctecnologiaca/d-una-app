import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/bottom_sheet_action_item.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/utils/string_utils.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/core/pdf/templates/delivery_note_pdf_template.dart';
import '../../domain/models/delivery_note_model.dart';
import '../../domain/models/delivery_note_status.dart';
import 'providers/delivery_notes_providers.dart';
import '../create_delivery_note/providers/create_delivery_note_provider.dart';
import '../view_delivery_note/widgets/send_delivery_note_whatsapp_sheet.dart';
import '../view_delivery_note/widgets/send_delivery_note_email_sheet.dart';
import '../view_delivery_note/widgets/confirm_delivery_note_reception_dialog.dart';

class DeliveryNoteSelectionActions {
  DeliveryNoteSelectionActions._();

  static void showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    DeliveryNotesSelectionState selection,
    List<DeliveryNoteModel> allNotes,
  ) {
    if (selection.isSingle) {
      final note = allNotes.firstWhere(
        (n) => n.id == selection.selectedIds.first,
      );
      _showSingleActionsSheet(context, ref, selection, note);
    } else {
      _showMultiActionsSheet(context, ref, selection, allNotes);
    }
  }

  static void _showSingleActionsSheet(
    BuildContext context,
    WidgetRef ref,
    DeliveryNotesSelectionState selection,
    DeliveryNoteModel note,
  ) {
    final isFinalized =
        note.status == DeliveryNoteStatus.delivered ||
        note.status == DeliveryNoteStatus.cancelled;

    CustomActionSheet.show(
      context: context,
      title: '${note.deliveryNoteNumber} (${note.clientName})',
      actions: [
        BottomSheetActionItem(
          icon: Icons.edit_outlined,
          label: 'Modificar',
          enabled: !isFinalized,
          subtitle: isFinalized
              ? 'Nota finalizada o cancelada. No se puede modificar'
              : null,
          onTap: () async {
            context.pop();
            // Cargar con detalles
            final detailedNote = await ref
                .read(deliveryNotesRepositoryProvider)
                .getDeliveryNoteWithDetails(note.id);
            if (detailedNote != null && context.mounted) {
              ref
                  .read(createDeliveryNoteProvider.notifier)
                  .loadExistingDeliveryNote(detailedNote);
              ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
              context.push('/delivery-notes/edit/${note.id}');
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.picture_as_pdf_outlined,
          label: 'Descargar PDF',
          onTap: () async {
            final userProfile = ref.read(userProfileProvider).value;
            final userEmail = Supabase.instance.client.auth.currentUser?.email;

            if (userProfile == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cargando perfil... Por favor espere.'),
                ),
              );
              return;
            }

            context.pop();

            final detailedNote = await ref
                .read(deliveryNotesRepositoryProvider)
                .getDeliveryNoteWithDetails(note.id);

            if (detailedNote != null && context.mounted) {
              ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
              context.push(
                '/pdf-preview',
                extra: {
                  'title': 'Previsualizar Nota de Entrega',
                  'subtitle':
                      '${detailedNote.deliveryNoteNumber} (${detailedNote.clientName})',
                  'fileName': StringUtils.sanitizeForFileName(
                    '${detailedNote.date.toIso8601String().substring(0, 10)}_${detailedNote.clientName}_${detailedNote.deliveryNoteNumber}.pdf',
                  ),
                  'buildPdf': (PdfPageFormat format) =>
                      DeliveryNotePdfTemplate(
                        note: detailedNote,
                        userProfile: userProfile,
                        userEmail: userEmail,
                      ).generate(format),
                },
              );
            }
          },
        ),
        if (note.status != DeliveryNoteStatus.delivered)
          BottomSheetActionItem(
            icon: Symbols.signature,
            label: 'Confirmar recepción y firma',
            subtitle: 'Registrar la firma del cliente al momento de la entrega',
            onTap: () async {
              context.pop();
              final detailedNote = await ref
                  .read(deliveryNotesRepositoryProvider)
                  .getDeliveryNoteWithDetails(note.id);
              if (detailedNote != null && context.mounted) {
                ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
                ConfirmDeliveryNoteReceptionDialog.show(context, ref, detailedNote);
              }
            },
          ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Symbols.chat,
          label: 'Enviar por WhatsApp',
          onTap: () async {
            context.pop();
            final detailedNote = await ref
                .read(deliveryNotesRepositoryProvider)
                .getDeliveryNoteWithDetails(note.id);
            if (detailedNote != null && context.mounted) {
              ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
              SendDeliveryNoteWhatsAppSheet.show(context, detailedNote);
            }
          },
        ),
        BottomSheetActionItem(
          icon: Symbols.mail,
          label: 'Enviar por Correo',
          onTap: () async {
            context.pop();
            final detailedNote = await ref
                .read(deliveryNotesRepositoryProvider)
                .getDeliveryNoteWithDetails(note.id);
            if (detailedNote != null && context.mounted) {
              ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
              SendDeliveryNoteEmailSheet.show(context, detailedNote);
            }
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus',
          enabled: !isFinalized,
          subtitle: isFinalized
              ? 'Nota finalizada. No se puede cambiar de estado'
              : null,
          onTap: () async {
            context.pop();
            final selected = await _showStatusDialog(context, note.status);
            if (selected != null && selected != note.status) {
              await ref
                  .read(paginatedDeliveryNotesProvider.notifier)
                  .updateDeliveryNoteStatus(note.id, selected);
              ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Estatus cambiado a "${selected.label}"')),
                );
              }
            }
          },
        ),
        BottomSheetActionItem(
          icon: note.isArchived ? Symbols.unarchive : Symbols.archive,
          label: note.isArchived ? 'Desarchivar' : 'Archivar',
          onTap: () async {
            context.pop();
            await ref
                .read(paginatedDeliveryNotesProvider.notifier)
                .archiveDeliveryNote(note.id, !note.isArchived);
            ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
          },
        ),
        BottomSheetActionItem(
          icon: Icons.delete_outline,
          label: 'Eliminar',
          enabled: note.status == DeliveryNoteStatus.draft,
          subtitle: note.status != DeliveryNoteStatus.draft
              ? 'Solo se pueden eliminar notas en borrador'
              : null,
          onTap: () async {
            context.pop();
            final confirm = await CustomDialog.show<bool>(
              context: context,
              dialog: CustomDialog.destructive(
                title: '¿Eliminar nota de entrega?',
                contentText:
                    'Se eliminará la nota de entrega "${note.deliveryNoteNumber}". Esta acción no se puede deshacer.',
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await ref
                  .read(paginatedDeliveryNotesProvider.notifier)
                  .deleteDeliveryNote(note.id);
              ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
            }
          },
        ),
      ],
    );
  }

  static void _showMultiActionsSheet(
    BuildContext context,
    WidgetRef ref,
    DeliveryNotesSelectionState selection,
    List<DeliveryNoteModel> allNotes,
  ) {
    final selectedIds = selection.selectedIds.toList();

    CustomActionSheet.show(
      context: context,
      title: '${selection.count} notas seleccionadas',
      actions: [
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus en lote',
          onTap: () async {
            context.pop();
            final selectedStatus = await _showStatusDialog(
              context,
              DeliveryNoteStatus.draft,
            );
            if (selectedStatus != null) {
              await ref
                  .read(paginatedDeliveryNotesProvider.notifier)
                  .batchUpdateStatus(selectedIds, selectedStatus);
              ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Se actualizó el estatus de ${selectedIds.length} notas a "${selectedStatus.label}"',
                    ),
                  ),
                );
              }
            }
          },
        ),
        BottomSheetActionItem(
          icon: Symbols.archive,
          label: 'Archivar seleccionadas',
          onTap: () async {
            context.pop();
            await ref
                .read(paginatedDeliveryNotesProvider.notifier)
                .batchArchive(selectedIds, true);
            ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Se archivaron ${selectedIds.length} notas'),
                ),
              );
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.delete_outline,
          label: 'Eliminar seleccionadas (solo borradores)',
          onTap: () async {
            context.pop();
            final confirm = await CustomDialog.show<bool>(
              context: context,
              dialog: CustomDialog.destructive(
                title: '¿Eliminar notas seleccionadas?',
                contentText:
                    'Se eliminarán las notas de entrega en borrador seleccionadas. Las notas emitidas o entregadas no se eliminarán.',
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await ref
                  .read(paginatedDeliveryNotesProvider.notifier)
                  .batchDelete(selectedIds);
              ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
            }
          },
        ),
      ],
    );
  }

  static Future<DeliveryNoteStatus?> _showStatusDialog(
    BuildContext context,
    DeliveryNoteStatus currentStatus,
  ) {
    return showDialog<DeliveryNoteStatus>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cambiar Estatus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: DeliveryNoteStatus.values.map((status) {
              return ListTile(
                leading: Icon(
                  status.iconData,
                  color: status.statusColor(Theme.of(context).colorScheme),
                ),
                title: Text(status.label),
                selected: status == currentStatus,
                onTap: () => Navigator.pop(ctx, status),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}
