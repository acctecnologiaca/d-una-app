import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/bottom_sheet_action_item.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/utils/string_utils.dart';
import 'package:d_una_app/core/utils/contact_utils.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/core/theme/app_theme.dart';
import 'package:d_una_app/core/pdf/templates/delivery_note_pdf_template.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../../../domain/models/delivery_note_status.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';
import '../../delivery_notes_list/delivery_note_selection_actions.dart';
import '../../create_delivery_note/providers/create_delivery_note_provider.dart';
import '../tabs/view_delivery_note_details_tab.dart';
import '../tabs/view_delivery_note_client_tab.dart';
import '../tabs/view_delivery_note_items_tab.dart';
import '../tabs/view_delivery_note_delivery_tab.dart';
import '../tabs/view_delivery_note_observations_tab.dart';
import '../tabs/view_delivery_note_summary_tab.dart';
import '../widgets/send_delivery_note_whatsapp_sheet.dart';
import '../widgets/send_delivery_note_email_sheet.dart';
import '../widgets/confirm_delivery_note_reception_dialog.dart';

class ViewDeliveryNoteScreen extends ConsumerStatefulWidget {
  final String noteId;

  const ViewDeliveryNoteScreen({super.key, required this.noteId});

  @override
  ConsumerState<ViewDeliveryNoteScreen> createState() =>
      _ViewDeliveryNoteScreenState();
}

class _ViewDeliveryNoteScreenState extends ConsumerState<ViewDeliveryNoteScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 6 pestañas homologadas, empezando en Resumen (índice 5)
    _tabController = TabController(length: 6, vsync: this, initialIndex: 5);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(deliveryNoteDetailProvider(widget.noteId));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  void _showSendOptions(
    BuildContext context,
    DeliveryNoteModel note,
    bool isSentOrResent,
  ) {
    if (note.hasMissingSerialsEffective) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede enviar la nota de entrega porque faltan seriales por asignar.',
          ),
        ),
      );
      return;
    }

    final isSendDisabled =
        note.status == DeliveryNoteStatus.finalized ||
        note.status == DeliveryNoteStatus.cancelled;

    if (isSendDisabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La nota de entrega está ${note.status.label.toLowerCase()} y no se puede enviar.',
          ),
        ),
      );
      return;
    }

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

  void _showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    DeliveryNoteModel note,
  ) {
    final isFinalized = note.status == DeliveryNoteStatus.finalized;

    CustomActionSheet.show(
      context: context,
      title: 'Opciones',
      actions: [
        // Bloque 1: Documento y Exportación
        BottomSheetActionItem(
          icon: Icons.picture_as_pdf_outlined,
          label: 'Descargar PDF',
          enabled: !note.hasMissingSerialsEffective,
          subtitle: note.hasMissingSerialsEffective
              ? 'Faltan seriales por asignar. No se puede descargar'
              : null,
          onTap: () async {
            if (note.hasMissingSerialsEffective) return;
            final userProfile = ref.read(userProfileProvider).value;
            final userEmail = Supabase.instance.client.auth.currentUser?.email;

            if (userProfile == null) return;
            context.pop();

            context.push(
              '/pdf-preview',
              extra: {
                'title': 'Previsualizar Nota de Entrega',
                'subtitle':
                    '${note.deliveryNoteNumber} (${note.clientName})',
                'fileName': StringUtils.sanitizeForFileName(
                  '${note.date.toIso8601String().substring(0, 10)}_${note.clientName}_${note.deliveryNoteNumber}.pdf',
                ),
                'buildPdf': (PdfPageFormat format) => DeliveryNotePdfTemplate(
                  note: note,
                  userProfile: userProfile,
                  userEmail: userEmail,
                ).generate(format),
              },
            );
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),

        // Bloque 2: Ciclo de Vida y Flujo Operativo
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus',
          enabled: !isFinalized,
          subtitle: isFinalized
              ? 'Nota de entrega finalizada. No se puede cambiar de estado'
              : null,
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            context.pop();

            final selected = await DeliveryNoteSelectionActions.showStatusDialog(
              context,
              note.status,
              hasMissingSerials: note.hasMissingSerialsEffective,
            );
            if (selected != null && selected != note.status) {
              try {
                await ref
                    .read(deliveryNotesRepositoryProvider)
                    .updateDeliveryNoteStatus(note.id, selected);

                ref.invalidate(deliveryNoteDetailProvider(widget.noteId));
                ref.read(paginatedDeliveryNotesProvider.notifier).refresh();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Estatus cambiado a "${selected.label}"',
                    ),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error al cambiar estatus: $e'),
                  ),
                );
              }
            }
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),

        // Bloque 3: Utilidades y Gestión Documental
        BottomSheetActionItem(
          icon: note.isArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
          label: note.isArchived ? 'Desarchivar' : 'Archivar',
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final router = GoRouter.of(context);

            context.pop();
            await ref
                .read(deliveryNotesRepositoryProvider)
                .archiveDeliveryNote(note.id, !note.isArchived);

            ref.invalidate(deliveryNoteDetailProvider(widget.noteId));
            ref.read(paginatedDeliveryNotesProvider.notifier).refresh();

            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  note.isArchived
                      ? 'Nota de entrega desarchivada exitosamente'
                      : 'Nota de entrega archivada exitosamente',
                ),
              ),
            );
            if (!note.isArchived) {
              router.pop();
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final noteAsync = ref.watch(deliveryNoteDetailProvider(widget.noteId));

    return noteAsync.when(
      loading: () => Scaffold(
        appBar: const StandardAppBar(
          title: 'Nota de Entrega',
          subtitle: 'Cargando...',
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: const StandardAppBar(
          title: 'Nota de Entrega',
          subtitle: 'Error',
        ),
        body: Center(
          child: Text('Error al cargar la nota: $e'),
        ),
      ),
      data: (note) {
        if (note == null) {
          return const Scaffold(
            appBar: StandardAppBar(
              title: 'Nota de Entrega',
              subtitle: 'No encontrada',
            ),
            body: Center(child: Text('La nota de entrega no existe')),
          );
        }

        final canEdit = note.status != DeliveryNoteStatus.finalized &&
            note.status != DeliveryNoteStatus.cancelled;
        final canSign = note.status != DeliveryNoteStatus.finalized &&
            note.status != DeliveryNoteStatus.cancelled;
        final hasPhone = (note.contactPhone != null &&
                note.contactPhone!.trim().isNotEmpty) ||
            (note.clientPhone != null && note.clientPhone!.trim().isNotEmpty);

        final showWhatsAppFab = hasPhone &&
            note.status != DeliveryNoteStatus.draft &&
            note.status != DeliveryNoteStatus.finalized &&
            note.status != DeliveryNoteStatus.cancelled;
        final showSignFab = canSign;
        final showEditFab = canEdit;

        int activeFabsCount = 0;
        if (showWhatsAppFab) activeFabsCount++;
        if (showSignFab) activeFabsCount++;
        if (showEditFab) activeFabsCount++;

        final double bottomPadding;
        switch (activeFabsCount) {
          case 3:
            bottomPadding = 256.0;
            break;
          case 2:
            bottomPadding = 184.0;
            break;
          case 1:
            bottomPadding = 112.0;
            break;
          default:
            bottomPadding = 24.0;
        }

        final isSentOrResent =
            note.status == DeliveryNoteStatus.sent ||
            note.status == DeliveryNoteStatus.resent ||
            note.status == DeliveryNoteStatus.opened;
        final isMissingSerials = note.hasMissingSerialsEffective;
        final isSendDisabled =
            note.status == DeliveryNoteStatus.finalized ||
            note.status == DeliveryNoteStatus.cancelled ||
            isMissingSerials;

        return Scaffold(
          appBar: StandardAppBar(
            title: 'Nota de Entrega',
            subtitle: '${note.deliveryNoteNumber} (${note.clientName})',
            actions: [
              IconButton(
                onPressed: isSendDisabled
                    ? null
                    : () => _showSendOptions(context, note, isSentOrResent),
                icon: Icon(
                  isSentOrResent ? Symbols.forward : Icons.send,
                  color: isSendDisabled
                      ? colors.outline
                      : colors.onSurfaceVariant,
                ),
                tooltip: isMissingSerials
                    ? 'Faltan seriales por asignar. No se puede enviar'
                    : (isSendDisabled
                        ? 'Nota de entrega ${note.status.label.toLowerCase()}. No se puede enviar'
                        : (isSentOrResent ? 'Reenviar' : 'Enviar')),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
                tooltip: 'Opciones',
                onPressed: () => _showActionsSheet(context, ref, note),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurfaceVariant,
              indicatorColor: colors.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                const Tab(text: 'Detalles'),
                const Tab(text: 'Cliente'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Productos'),
                      if (note.hasMissingSerials) ...[
                        const SizedBox(width: 6),
                        Badge(backgroundColor: colors.error, smallSize: 8),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Despacho'),
                const Tab(text: 'Observaciones'),
                const Tab(text: 'Resumen'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              ViewDeliveryNoteDetailsTab(
                noteId: widget.noteId,
                bottomPadding: bottomPadding,
              ),
              ViewDeliveryNoteClientTab(
                noteId: widget.noteId,
                bottomPadding: bottomPadding,
              ),
              ViewDeliveryNoteItemsTab(
                noteId: widget.noteId,
                bottomPadding: bottomPadding,
              ),
              ViewDeliveryNoteDeliveryTab(
                noteId: widget.noteId,
                bottomPadding: bottomPadding,
              ),
              ViewDeliveryNoteObservationsTab(
                noteId: widget.noteId,
                bottomPadding: bottomPadding,
              ),
              ViewDeliveryNoteSummaryTab(
                noteId: widget.noteId,
                onNavigateToTab: (index) => _tabController.animateTo(index),
                bottomPadding: bottomPadding,
              ),
            ],
          ),
          floatingActionButton: activeFabsCount == 0
              ? null
              : Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showWhatsAppFab) ...[
                        FloatingActionButton(
                          heroTag: 'fab_delivery_note_whatsapp',
                          tooltip: 'Contactar por WhatsApp',
                          onPressed: () {
                            final phone =
                                note.contactPhone ?? note.clientPhone!;
                            ContactUtils.launchWhatsApp(phone);
                          },
                          backgroundColor: colors.greenBase,
                          child: Image.asset(
                            'assets/icons/whatsapp_icon.png',
                            width: 28,
                            height: 28,
                            color: colors.greenBaseOn,
                          ),
                        ),
                        if (showSignFab || showEditFab)
                          const SizedBox(height: 16),
                      ],
                      if (showSignFab) ...[
                        FloatingActionButton(
                          heroTag: 'fab_delivery_note_sign',
                          tooltip: 'Firmar como recibido',
                          backgroundColor: colors.secondaryContainer,
                          onPressed: () {
                            if (note.hasMissingSerialsEffective) {
                              CustomDialog.show(
                                context: context,
                                dialog: CustomDialog.confirmation(
                                  icon: Symbols.warning,
                                  iconColor: Colors.amber.shade800,
                                  title: 'Seriales pendientes',
                                  contentText:
                                      'No se puede confirmar la recepción porque faltan seriales por asignar a uno o más productos.',
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context, rootNavigator: true)
                                              .pop(),
                                      child: const Text('Entendido'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            ConfirmDeliveryNoteReceptionDialog.show(
                              context,
                              ref,
                              note,
                            );
                          },
                          child: Icon(
                            Symbols.signature,
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                        if (showEditFab) const SizedBox(height: 16),
                      ],
                      if (showEditFab) ...[
                        FloatingActionButton(
                          heroTag: 'fab_delivery_note_edit',
                          tooltip: 'Editar Nota de Entrega',
                          onPressed: () async {
                            ref
                                .read(createDeliveryNoteProvider.notifier)
                                .loadExistingDeliveryNote(note);
                            await context.push(
                              '/delivery-notes/edit/${note.id}?tab=${_tabController.index}',
                            );
                            if (context.mounted) {
                              ref.invalidate(
                                deliveryNoteDetailProvider(widget.noteId),
                              );
                            }
                          },
                          child: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
