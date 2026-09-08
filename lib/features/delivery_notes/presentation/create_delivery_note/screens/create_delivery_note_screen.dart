import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/draft_toast.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/bottom_sheet_action_item.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import '../../../data/repositories/supabase_delivery_notes_repository.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../../view_delivery_note/widgets/confirm_delivery_note_reception_dialog.dart';
import '../../view_delivery_note/widgets/send_delivery_note_whatsapp_sheet.dart';
import '../../view_delivery_note/widgets/send_delivery_note_email_sheet.dart';
import '../providers/create_delivery_note_provider.dart';
import '../tabs/delivery_note_details_tab.dart';
import '../tabs/delivery_note_client_tab.dart';
import '../tabs/delivery_note_items_tab.dart';
import '../tabs/delivery_note_delivery_tab.dart';
import '../tabs/delivery_note_observations_tab.dart';
import '../tabs/delivery_note_summary_tab.dart';
import 'select_delivery_note_product_screen.dart';
import 'select_delivery_note_observation_screen.dart';

class CreateDeliveryNoteScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final String? quoteId;
  final String? supplierOrderId;

  const CreateDeliveryNoteScreen({
    super.key,
    this.noteId,
    this.quoteId,
    this.supplierOrderId,
  });

  @override
  ConsumerState<CreateDeliveryNoteScreen> createState() =>
      _CreateDeliveryNoteScreenState();
}

class _CreateDeliveryNoteScreenState
    extends ConsumerState<CreateDeliveryNoteScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AppLifecycleListener _lifecycleListener;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        ref
            .read(createDeliveryNoteProvider.notifier)
            .autoSaveDraft(
              tabIndex: _tabController.index,
              noteId: widget.noteId,
            );
      }
    });

    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        ref
            .read(createDeliveryNoteProvider.notifier)
            .autoSaveDraft(
              tabIndex: _tabController.index,
              noteId: widget.noteId,
            );
      },
      onInactive: () {
        ref
            .read(createDeliveryNoteProvider.notifier)
            .autoSaveDraft(
              tabIndex: _tabController.index,
              noteId: widget.noteId,
            );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (_hasInitialized) return;
    _hasInitialized = true;

    final notifier = ref.read(createDeliveryNoteProvider.notifier);

    // 1. Modo Edición
    if (widget.noteId != null && widget.noteId!.isNotEmpty) {
      final draft = await notifier.checkExistingDraft(noteId: widget.noteId);
      if (draft != null && mounted) {
        notifier.restoreDraft(draft);
        if (draft.tabIndex >= 0 && draft.tabIndex < 6) {
          _tabController.index = draft.tabIndex;
        }
        DraftToast.show(
          context,
          message: 'Borrador recuperado automáticamente',
          onDiscard: () async {
            await notifier.discardDraft(noteId: widget.noteId);
            final repo = ref.read(deliveryNotesRepositoryProvider);
            final note = await repo.getDeliveryNoteById(widget.noteId!);
            if (note != null && mounted) {
              notifier.loadExistingDeliveryNote(note);
              _tabController.index = 0;
            }
          },
        );
      } else {
        final repo = ref.read(deliveryNotesRepositoryProvider);
        final note = await repo.getDeliveryNoteById(widget.noteId!);
        if (note != null && mounted) {
          notifier.loadExistingDeliveryNote(note);
        }
      }
      return;
    }

    // 2. Modo Creado desde Cotización
    if (widget.quoteId != null && widget.quoteId!.isNotEmpty) {
      try {
        final quoteRepo = ref.read(quotesRepositoryProvider);
        final quote = await quoteRepo.getQuoteWithDetails(widget.quoteId!);
        if (mounted) {
          notifier.loadFromQuote(quote);
          return;
        }
      } catch (e) {
        debugPrint('Error cargando cotización para nota de entrega: $e');
      }
    }

    // 3. Modo Creado desde Orden de Compra
    if (widget.supplierOrderId != null && widget.supplierOrderId!.isNotEmpty) {
      try {
        final ocRepo = ref.read(supplierOrdersRepositoryProvider);
        final details = await ocRepo.getSupplierOrderDetails(
          widget.supplierOrderId!,
        );
        if (mounted) {
          notifier.loadFromSupplierOrder(details.order, details.items);
          return;
        }
      } catch (e) {
        debugPrint('Error cargando OC para nota de entrega: $e');
      }
    }

    // 4. Modo Creación desde cero con verificación de borrador
    final draft = await notifier.checkExistingDraft();
    if (draft != null && mounted) {
      notifier.restoreDraft(draft);
      if (draft.tabIndex >= 0 && draft.tabIndex < 6) {
        _tabController.index = draft.tabIndex;
      }
      DraftToast.show(
        context,
        message: 'Borrador recuperado automáticamente',
        onDiscard: () async {
          await notifier.discardDraft();
          notifier.reset();
          _tabController.index = 0;
        },
      );
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePop() async {
    final state = ref.read(createDeliveryNoteProvider);
    if (state.isDirty) {
      await ref
          .read(createDeliveryNoteProvider.notifier)
          .saveDraftNow(tabIndex: _tabController.index, noteId: widget.noteId);
      if (mounted) {
        AppToast.info(
          context,
          message: 'Borrador guardado localmente',
          icon: Icons.bookmark_added_outlined,
        );
      }
    }
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _saveDeliveryNote() async {
    final notifier = ref.read(createDeliveryNoteProvider.notifier);
    final state = ref.read(createDeliveryNoteProvider);

    if (!state.isDetailsValid) {
      AppToast.error(context, message: 'Debe seleccionar un cliente.');
      _tabController.animateTo(1);
      return;
    }

    if (state.items.isEmpty) {
      AppToast.error(context, message: 'Debe agregar al menos un producto.');
      _tabController.animateTo(2);
      return;
    }

    if (!state.isDeliveryValid) {
      AppToast.error(
        context,
        message: 'Por favor complete la información de despacho.',
      );
      _tabController.animateTo(3);
      return;
    }

    try {
      final savedNote = await notifier.saveDeliveryNote();
      if (mounted) {
        AppToast.success(
          context,
          message: 'Nota de entrega guardada exitosamente.',
        );
        _showPostSaveOptions(savedNote);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Error: $e');
      }
    }
  }

  void _showPostSaveOptions(DeliveryNoteModel savedNote) {
    CustomActionSheet.show(
      context: context,
      title: 'Nota ${savedNote.deliveryNoteNumber} guardada',
      actions: [
        BottomSheetActionItem(
          icon: Icons.draw_outlined,
          label: 'Registrar recepción / firma',
          onTap: () async {
            context.pop();
            await ConfirmDeliveryNoteReceptionDialog.show(
              context,
              ref,
              savedNote,
            );
            if (mounted) {
              context.pushReplacement('/delivery_notes/view/${savedNote.id}');
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.chat_bubble_outline,
          label: 'Enviar por WhatsApp',
          onTap: () async {
            context.pop();
            await SendDeliveryNoteWhatsAppSheet.show(context, savedNote);
            if (mounted) {
              context.pushReplacement('/delivery_notes/view/${savedNote.id}');
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.email_outlined,
          label: 'Enviar por correo',
          onTap: () async {
            context.pop();
            await SendDeliveryNoteEmailSheet.show(context, savedNote);
            if (mounted) {
              context.pushReplacement('/delivery_notes/view/${savedNote.id}');
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.visibility_outlined,
          label: 'Ver nota de entrega',
          onTap: () {
            context.pop();
            context.pushReplacement('/delivery_notes/view/${savedNote.id}');
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createDeliveryNoteProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        appBar: StandardAppBar(
          title: widget.noteId != null
              ? 'Editar nota de entrega'
              : 'Nueva nota de entrega',
          subtitle: state.clientName != null
              ? '${state.deliveryNoteNumber ?? "NE-..."} (${state.clientName})'
              : (state.deliveryNoteNumber ?? 'NE-...'),
          actions: [
            IconButton(
              icon: Icon(
                Icons.save_outlined,
                color: state.isDirty
                    ? colors.onSurfaceVariant
                    : colors.onSurfaceVariant.withValues(alpha: 0.38),
              ),
              tooltip: state.isDirty ? 'Guardar borrador' : 'Sin cambios',
              onPressed: state.isDirty
                  ? () async {
                      await ref
                          .read(createDeliveryNoteProvider.notifier)
                          .saveDraftNow(
                            tabIndex: _tabController.index,
                            noteId: widget.noteId,
                          );
                      if (context.mounted) {
                        AppToast.success(context, message: 'Borrador guardado');
                      }
                    }
                  : null,
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
                    if (state.hasMissingSerials) ...[
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
            const DeliveryNoteDetailsTab(),
            const DeliveryNoteClientTab(),
            const DeliveryNoteItemsTab(),
            const DeliveryNoteDeliveryTab(),
            const DeliveryNoteObservationsTab(),
            DeliveryNoteSummaryTab(
              onNavigateToTab: (index) => _tabController.animateTo(index),
            ),
          ],
        ),
        floatingActionButton: _buildFab(state),
      ),
    );
  }

  Widget? _buildFab(DeliveryNoteCreateState state) {
    if (_tabController.index == 2) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          label: 'Agregar',
          icon: Icons.add,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SelectDeliveryNoteProductScreen(),
              ),
            );
          },
        ),
      );
    }

    if (_tabController.index == 4) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          label: 'Agregar',
          icon: Icons.add,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SelectDeliveryNoteObservationScreen(),
              ),
            );
          },
        ),
      );
    }

    if (_tabController.index == 5) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          label: state.isLoading ? 'Guardando...' : 'Guardar',
          icon: state.isLoading ? Icons.hourglass_empty : Icons.save,
          isEnabled: !state.isLoading,
          onPressed: _saveDeliveryNote,
        ),
      );
    }

    return null;
  }
}
