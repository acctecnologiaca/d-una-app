import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/bottom_sheet_action_item.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/utils/string_utils.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/core/pdf/templates/delivery_note_pdf_template.dart';
import '../../domain/models/delivery_note_model.dart';
import '../../domain/models/delivery_note_status.dart';
import 'providers/delivery_notes_providers.dart';
import '../create_delivery_note/providers/create_delivery_note_provider.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import 'package:d_una_app/features/supplier_orders/domain/models/supplier_order_status.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
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
    final isFinalized = note.status == DeliveryNoteStatus.finalized;
    final isCancelled = note.status == DeliveryNoteStatus.cancelled;
    final isSentOrResent =
        note.status == DeliveryNoteStatus.sent ||
        note.status == DeliveryNoteStatus.resent ||
        note.status == DeliveryNoteStatus.opened;
    final isSendDisabled = isCancelled;
    final isMissingSerials = note.hasMissingSerialsEffective;

    CustomActionSheet.show(
      context: context,
      title: '${note.deliveryNoteNumber} (${note.clientName})',
      actions: [
        BottomSheetActionItem(
          icon: Icons.edit_outlined,
          label: 'Modificar',
          enabled: note.status.canEdit,
          subtitle: !note.status.canEdit
              ? 'Nota ${note.status.label.toLowerCase()}. No se puede modificar'
              : null,
          onTap: !note.status.canEdit
              ? null
              : () async {
            context.pop();
            // Cargar con detalles
            final detailedNote = await ref
                .read(deliveryNotesRepositoryProvider)
                .getDeliveryNoteWithDetails(note.id);
            if (detailedNote != null && context.mounted) {
              ref
                  .read(createDeliveryNoteProvider.notifier)
                  .loadExistingDeliveryNote(detailedNote);
              ref
                  .read(deliveryNotesSelectionProvider.notifier)
                  .clearSelection();
              context.push('/delivery-notes/edit/${note.id}');
            }
          },
        ),
        BottomSheetActionItem(
          icon: isSentOrResent ? Symbols.forward : Icons.send,
          label: isFinalized
              ? 'Enviar copia'
              : (isSentOrResent ? 'Reenviar' : 'Enviar'),
          enabled: !isSendDisabled && !isMissingSerials,
          subtitle: isMissingSerials
              ? 'Faltan seriales por asignar. No se puede enviar'
              : (isSendDisabled
                  ? 'Nota cancelada. No se puede enviar'
                  : null),
          onTap: () async {
            if (isMissingSerials) return;
            context.pop();
            final detailedNote = await ref
                .read(deliveryNotesRepositoryProvider)
                .getDeliveryNoteWithDetails(note.id);
            if (detailedNote != null && context.mounted) {
              ref
                  .read(deliveryNotesSelectionProvider.notifier)
                  .clearSelection();
              _showSendOptions(context, detailedNote);
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.picture_as_pdf_outlined,
          label: 'Descargar PDF',
          enabled: !isMissingSerials,
          subtitle: isMissingSerials
              ? 'Faltan seriales por asignar. No se puede descargar'
              : null,
          onTap: () async {
            if (isMissingSerials) return;
            final userProfile = ref.read(userProfileProvider).value;
            final userEmail = Supabase.instance.client.auth.currentUser?.email;

            if (userProfile == null) {
              AppToast.info(
                context,
                message: 'Cargando perfil... Por favor espere.',
              );
              return;
            }

            context.pop();

            final detailedNote = await ref
                .read(deliveryNotesRepositoryProvider)
                .getDeliveryNoteWithDetails(note.id);

            if (detailedNote != null && context.mounted) {
              ref
                  .read(deliveryNotesSelectionProvider.notifier)
                  .clearSelection();
              context.push(
                '/pdf-preview',
                extra: {
                  'title': 'Previsualizar Nota de Entrega',
                  'subtitle':
                      '${detailedNote.deliveryNoteNumber} (${detailedNote.clientName})',
                  'fileName': StringUtils.sanitizeForFileName(
                    '${detailedNote.date.toIso8601String().substring(0, 10)}_${detailedNote.clientName}_${detailedNote.deliveryNoteNumber}.pdf',
                  ),
                  'buildPdf': (PdfPageFormat format) => DeliveryNotePdfTemplate(
                    note: detailedNote,
                    userProfile: userProfile,
                    userEmail: userEmail,
                  ).generate(format),
                },
              );
            }
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus',
          enabled: !isCancelled,
          subtitle: isCancelled
              ? 'Nota cancelada. No se puede cambiar de estado'
              : null,
          onTap: () async {
            context.pop();
            final selected = await showStatusDialog(
              context,
              note.status,
              hasMissingSerials: isMissingSerials,
            );
            if (selected != null && selected != note.status) {
              await ref
                  .read(paginatedDeliveryNotesProvider.notifier)
                  .updateDeliveryNoteStatus(note.id, selected);
              if (selected == DeliveryNoteStatus.finalized ||
                  selected == DeliveryNoteStatus.cancelled) {
                ref.invalidate(productsProvider);
                ref.invalidate(paginatedProductsProvider);
              }

              // Cascada a OC vinculada al finalizar
              if (selected == DeliveryNoteStatus.finalized &&
                  note.supplierOrderId != null &&
                  note.supplierOrderId!.isNotEmpty) {
                try {
                  await ref
                      .read(supplierOrdersRepositoryProvider)
                      .updateSupplierOrderStatus(
                        note.supplierOrderId!,
                        SupplierOrderStatus.finalized.dbValue,
                      );
                  ref.invalidate(paginatedSupplierOrdersProvider);
                } catch (e) {
                  debugPrint('Error auto-finalizando orden de compra vinculada: $e');
                }
              }

              ref
                  .read(deliveryNotesSelectionProvider.notifier)
                  .clearSelection();
              if (context.mounted) {
                AppToast.success(
                  context,
                  message: 'Estatus cambiado a "${selected.label}"',
                );
              }
            }
          },
        ),
        if (note.status != DeliveryNoteStatus.delivered)
          BottomSheetActionItem(
            icon: Symbols.signature,
            label: 'Confirmar recepción',
            enabled: !isMissingSerials,
            subtitle: isMissingSerials
                ? 'Faltan seriales por asignar. No se puede confirmar recepción'
                : null,
            onTap: () async {
              if (isMissingSerials) return;
              context.pop();
              final detailedNote = await ref
                  .read(deliveryNotesRepositoryProvider)
                  .getDeliveryNoteWithDetails(note.id);
              if (detailedNote != null && context.mounted) {
                ref
                    .read(deliveryNotesSelectionProvider.notifier)
                    .clearSelection();
                ConfirmDeliveryNoteReceptionDialog.show(
                  context,
                  ref,
                  detailedNote,
                );
              }
            },
          ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: note.isArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
          label: note.isArchived ? 'Desarchivar' : 'Archivar',
          onTap: () async {
            context.pop();
            await ref
                .read(paginatedDeliveryNotesProvider.notifier)
                .archiveDeliveryNote(note.id, !note.isArchived);
            ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
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
    final selectedNotes = allNotes
        .where((n) => selection.selectedIds.contains(n.id))
        .toList();
    final isAllArchived =
        selectedNotes.isNotEmpty && selectedNotes.every((n) => n.isArchived);
    final anyHasMissing =
        selectedNotes.any((n) => n.hasMissingSerialsEffective);

    CustomActionSheet.show(
      context: context,
      title: '${selection.count} seleccionados',
      actions: [
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus',
          onTap: () async {
            context.pop();
            final initialStatus = selectedNotes.isNotEmpty &&
                    selectedNotes
                        .every((n) => n.status == selectedNotes.first.status)
                ? selectedNotes.first.status
                : null;
            final selectedStatus = await showStatusDialog(
              context,
              initialStatus,
              hasMissingSerials: anyHasMissing,
            );
            if (selectedStatus != null) {
              if (selectedStatus == DeliveryNoteStatus.finalized) {
                final notesWithMissing = selectedNotes
                    .where((n) => n.hasMissingSerialsEffective)
                    .toList();
                if (notesWithMissing.isNotEmpty) {
                  if (context.mounted) {
                    CustomDialog.show(
                      context: context,
                      dialog: CustomDialog.confirmation(
                        icon: Symbols.warning,
                        iconColor: Colors.amber.shade800,
                        title: 'Seriales pendientes',
                        contentText:
                            'No se pueden finalizar las notas seleccionadas porque ${notesWithMissing.length} nota(s) tienen seriales pendientes por asignar.',
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context, rootNavigator: true).pop(),
                            child: const Text('Entendido'),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }
              }

              await ref
                  .read(paginatedDeliveryNotesProvider.notifier)
                  .batchUpdateStatus(selectedIds, selectedStatus);
              if (selectedStatus == DeliveryNoteStatus.finalized ||
                  selectedStatus == DeliveryNoteStatus.cancelled) {
                ref.invalidate(productsProvider);
                ref.invalidate(paginatedProductsProvider);
              }
              ref
                  .read(deliveryNotesSelectionProvider.notifier)
                  .clearSelection();
              if (context.mounted) {
                AppToast.success(
                  context,
                  message:
                      'Se actualizó el estatus de ${selectedIds.length} notas a "${selectedStatus.label}"',
                );
              }
            }
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: isAllArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
          label: isAllArchived ? 'Desarchivar' : 'Archivar',
          onTap: () async {
            context.pop();
            await ref
                .read(paginatedDeliveryNotesProvider.notifier)
                .batchArchive(selectedIds, !isAllArchived);
            ref.read(deliveryNotesSelectionProvider.notifier).clearSelection();
            if (context.mounted) {
              final actionWord = !isAllArchived
                  ? 'archivaron'
                  : 'desarchivaron';
              AppToast.success(
                context,
                message: 'Se $actionWord ${selectedIds.length} notas',
              );
            }
          },
        ),
      ],
    );
  }

  static Future<DeliveryNoteStatus?> showStatusDialog(
    BuildContext context,
    DeliveryNoteStatus? currentStatus, {
    bool hasMissingSerials = false,
  }) async {
    final colors = Theme.of(context).colorScheme;
    final isCurrentFinalized = currentStatus == DeliveryNoteStatus.finalized;

    final allowedStatuses = [
      DeliveryNoteStatus.sent,
      DeliveryNoteStatus.finalized,
      DeliveryNoteStatus.cancelled,
    ];

    return await CustomDialog.show<DeliveryNoteStatus>(
      context: context,
      dialog: CustomDialog.vertical(
        icon: Symbols.conversion_path,
        title: 'Cambiar estatus',
        contentWidget: Builder(
          builder: (dialogContext) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: allowedStatuses.map((status) {
                final isSelected =
                    currentStatus != null && status == currentStatus;
                final isFinalizedDisabled =
                    status == DeliveryNoteStatus.finalized && hasMissingSerials;
                final isReversionDisabled =
                    isCurrentFinalized && status == DeliveryNoteStatus.sent;
                final isDisabled = isFinalizedDisabled || isReversionDisabled;

                final textColor = isDisabled
                    ? colors.onSurfaceVariant.withValues(alpha: 0.4)
                    : (isSelected ? colors.primary : colors.onSurface);

                String? subtitle;
                Color? subtitleColor;

                if (isFinalizedDisabled) {
                  subtitle = 'Faltan seriales por asignar';
                  subtitleColor = colors.error.withValues(alpha: 0.8);
                } else if (isCurrentFinalized) {
                  if (status == DeliveryNoteStatus.sent) {
                    subtitle = 'Al enviarse no cambia de estatus';
                    subtitleColor = colors.outline;
                  } else if (status == DeliveryNoteStatus.finalized) {
                    subtitle = 'Estatus actual';
                    subtitleColor = colors.primary.withValues(alpha: 0.8);
                  } else if (status == DeliveryNoteStatus.cancelled) {
                    subtitle = 'Cancelar entrega y reponer inventario';
                    subtitleColor = colors.primary;
                  }
                } else if (isSelected) {
                  subtitle = 'Estatus actual';
                  subtitleColor = colors.primary.withValues(alpha: 0.8);
                }

                return ListTile(
                  leading: Opacity(
                    opacity: (isDisabled && !isSelected) ? 0.4 : 1.0,
                    child: Image.asset(status.iconPath, width: 24, height: 24),
                  ),
                  title: Text(
                    status.label,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                  subtitle: subtitle != null
                      ? Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor ??
                                (isSelected
                                    ? colors.primary.withValues(alpha: 0.8)
                                    : colors.outline),
                          ),
                        )
                      : null,
                  trailing: isSelected
                      ? Icon(Icons.check, color: colors.primary, size: 20)
                      : null,
                  enabled: !isDisabled || isSelected,
                  onTap: isDisabled
                      ? null
                      : () async {
                          if (status == DeliveryNoteStatus.finalized &&
                              currentStatus != DeliveryNoteStatus.finalized) {
                            final confirm = await CustomDialog.show<bool>(
                              context: dialogContext,
                              dialog: CustomDialog.confirmation(
                                title: 'Finalizar entrega',
                                contentText:
                                    'Al finalizar la nota de entrega se descontará el inventario correspondiente. ¿Deseas continuar?',
                                actions: [
                                  Builder(
                                    builder: (c) => TextButton(
                                      onPressed: () =>
                                          Navigator.of(c).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                  ),
                                  Builder(
                                    builder: (c) => FilledButton(
                                      onPressed: () =>
                                          Navigator.of(c).pop(true),
                                      child: const Text('Finalizar'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true) return;
                          } else if (isCurrentFinalized &&
                              status == DeliveryNoteStatus.cancelled) {
                            final confirm = await CustomDialog.show<bool>(
                              context: dialogContext,
                              dialog: CustomDialog.destructive(
                                title: 'Cancelar Entrega e Inventario',
                                contentText:
                                    'Al cancelar esta nota finalizada se repondrá el inventario y los seriales a stock disponible. ¿Deseas cancelar la entrega?',
                                actions: [
                                  Builder(
                                    builder: (c) => TextButton(
                                      onPressed: () =>
                                          Navigator.of(c).pop(false),
                                      child: const Text('Volver'),
                                    ),
                                  ),
                                  Builder(
                                    builder: (c) => FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(c).colorScheme.error,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(c).pop(true),
                                      child:
                                          const Text('Confirmar Cancelación'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true) return;
                          }
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(status);
                          }
                        },
                );
              }).toList(),
            );
          },
        ),
        actions: [
          Builder(
            builder: (dialogContext) => TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  static void _showSendOptions(BuildContext context, DeliveryNoteModel note) {
    if (note.hasMissingSerialsEffective) {
      AppToast.warning(
        context,
        message:
            'No se puede enviar la nota de entrega porque faltan seriales por asignar.',
      );
      return;
    }

    final isSentOrResent =
        note.status == DeliveryNoteStatus.sent ||
        note.status == DeliveryNoteStatus.resent ||
        note.status == DeliveryNoteStatus.opened;

    CustomActionSheet.show(
      context: context,
      title: isSentOrResent
          ? 'Reenviar Nota de Entrega'
          : 'Enviar Nota de Entrega',
      actions: [
        BottomSheetActionItem(
          icon: Icons.email_outlined,
          label: isSentOrResent
              ? 'Reenviar por correo electrónico'
              : 'Enviar por correo electrónico',
          onTap: () {
            context.pop();
            SendDeliveryNoteEmailSheet.show(context, note);
          },
        ),
        BottomSheetActionItem(
          icon: 'assets/icons/whatsapp_icon.png',
          label: isSentOrResent
              ? 'Reenviar por WhatsApp'
              : 'Enviar por WhatsApp',
          onTap: () {
            context.pop();
            SendDeliveryNoteWhatsAppSheet.show(context, note);
          },
        ),
      ],
    );
  }
}
