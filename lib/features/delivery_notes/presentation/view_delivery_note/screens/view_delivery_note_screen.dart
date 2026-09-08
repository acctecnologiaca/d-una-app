import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/bottom_sheet_action_item.dart';
import 'package:d_una_app/shared/utils/string_utils.dart';
import 'package:d_una_app/core/utils/contact_utils.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/core/pdf/templates/delivery_note_pdf_template.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../../../domain/models/delivery_note_status.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';
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

  void _showSendOptions(BuildContext context, DeliveryNoteModel note) {
    CustomActionSheet.show(
      context: context,
      title: 'Enviar Nota de Entrega',
      actions: [
        BottomSheetActionItem(
          icon: Symbols.chat,
          label: 'Enviar por WhatsApp',
          subtitle:
              'Envía un enlace con token seguro para visualización y firma',
          onTap: () {
            context.pop();
            SendDeliveryNoteWhatsAppSheet.show(context, note);
          },
        ),
        BottomSheetActionItem(
          icon: Symbols.mail,
          label: 'Enviar por Correo Electrónico',
          subtitle: 'Envía la plantilla oficial con enlace directo a la nota',
          onTap: () {
            context.pop();
            SendDeliveryNoteEmailSheet.show(context, note);
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
    final isDelivered = note.status == DeliveryNoteStatus.delivered;
    final canEdit = note.status != DeliveryNoteStatus.delivered &&
        note.status != DeliveryNoteStatus.cancelled;

    CustomActionSheet.show(
      context: context,
      title: 'Opciones',
      actions: [
        BottomSheetActionItem(
          icon: Icons.picture_as_pdf_outlined,
          label: 'Descargar / Ver PDF',
          onTap: () async {
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
        if (!isDelivered)
          BottomSheetActionItem(
            icon: Symbols.signature,
            label: 'Confirmar recepción y firma',
            onTap: () {
              context.pop();
              ConfirmDeliveryNoteReceptionDialog.show(context, ref, note);
            },
          ),
        if (canEdit)
          BottomSheetActionItem(
            icon: Icons.edit_outlined,
            label: 'Modificar nota',
            onTap: () async {
              context.pop();
              ref
                  .read(createDeliveryNoteProvider.notifier)
                  .loadExistingDeliveryNote(note);
              await context.push(
                '/delivery-notes/edit/${note.id}',
              );
              if (context.mounted) {
                ref.invalidate(deliveryNoteDetailProvider(widget.noteId));
              }
            },
          ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Symbols.chat,
          label: 'Enviar por WhatsApp',
          onTap: () {
            context.pop();
            SendDeliveryNoteWhatsAppSheet.show(context, note);
          },
        ),
        BottomSheetActionItem(
          icon: Symbols.mail,
          label: 'Enviar por Correo',
          onTap: () {
            context.pop();
            SendDeliveryNoteEmailSheet.show(context, note);
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

        final canEdit = note.status != DeliveryNoteStatus.delivered &&
            note.status != DeliveryNoteStatus.cancelled;
        final hasPhone = (note.contactPhone != null &&
                note.contactPhone!.trim().isNotEmpty) ||
            (note.clientPhone != null && note.clientPhone!.trim().isNotEmpty);

        final showWhatsAppFab = hasPhone;
        final showEditFab = canEdit;

        final hasTwoFabs = showWhatsAppFab && showEditFab;
        final hasOneFab = showWhatsAppFab ^ showEditFab;
        final double bottomPadding =
            hasTwoFabs ? 184.0 : (hasOneFab ? 112.0 : 24.0);

        return Scaffold(
          appBar: StandardAppBar(
            title: 'Nota de Entrega',
            subtitle: '${note.deliveryNoteNumber} (${note.clientName})',
            actions: [
              IconButton(
                icon: const Icon(Icons.send_outlined),
                tooltip: 'Enviar',
                onPressed: () => _showSendOptions(context, note),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
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
          floatingActionButton: (!showWhatsAppFab && !showEditFab)
              ? null
              : Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showWhatsAppFab) ...[
                        FloatingActionButton.small(
                          heroTag: 'fab_delivery_note_whatsapp',
                          tooltip: 'Contactar por WhatsApp',
                          onPressed: () {
                            final phone = note.contactPhone ?? note.clientPhone!;
                            ContactUtils.launchWhatsApp(phone);
                          },
                          backgroundColor: colors.surfaceContainerHigh,
                          child: Icon(
                            Symbols.chat,
                            color: colors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                              '/delivery-notes/edit/${note.id}',
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
