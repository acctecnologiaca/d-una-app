import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/draft_toast.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import '../../../data/repositories/supabase_delivery_notes_repository.dart';
import '../providers/create_delivery_note_provider.dart';
import '../tabs/delivery_note_details_tab.dart';
import '../tabs/delivery_note_delivery_tab.dart';
import '../tabs/delivery_note_items_tab.dart';
import '../tabs/delivery_note_serials_tab.dart';
import '../tabs/delivery_note_conditions_tab.dart';
import '../tabs/delivery_note_reception_tab.dart';

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

class _CreateDeliveryNoteScreenState extends ConsumerState<CreateDeliveryNoteScreen>
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
            .autoSaveDraft(tabIndex: _tabController.index, noteId: widget.noteId);
      }
    });

    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        ref
            .read(createDeliveryNoteProvider.notifier)
            .autoSaveDraft(tabIndex: _tabController.index, noteId: widget.noteId);
      },
      onInactive: () {
        ref
            .read(createDeliveryNoteProvider.notifier)
            .autoSaveDraft(tabIndex: _tabController.index, noteId: widget.noteId);
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
        final details = await ocRepo.getSupplierOrderDetails(widget.supplierOrderId!);
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
      _tabController.animateTo(0);
      return;
    }

    if (state.items.isEmpty) {
      AppToast.error(context, message: 'Debe agregar al menos un producto.');
      _tabController.animateTo(2);
      return;
    }

    try {
      final savedNote = await notifier.saveDeliveryNote();
      if (mounted) {
        AppToast.success(context, message: 'Nota de entrega guardada exitosamente.');
        context.pushReplacement('/delivery_notes/view/${savedNote.id}');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Error: $e');
      }
    }
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
              const Tab(text: 'Despacho'),
              Tab(
                text: state.items.isNotEmpty
                    ? 'Productos (${state.items.length})'
                    : 'Productos',
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Seriales'),
                    if (state.hasMissingSerials) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade800,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Condiciones'),
              const Tab(text: 'Recepción'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const DeliveryNoteDetailsTab(),
            const DeliveryNoteDeliveryTab(),
            DeliveryNoteItemsTab(
              onManageSerialsPressed: () {
                _tabController.animateTo(3); // Go to serials tab
              },
            ),
            const DeliveryNoteSerialsTab(),
            const DeliveryNoteConditionsTab(),
            const DeliveryNoteReceptionTab(),
          ],
        ),
        floatingActionButton: _tabController.index == 5
            ? CustomExtendedFab(
                label: state.isLoading ? 'Guardando...' : 'Guardar Nota',
                icon: state.isLoading ? Icons.hourglass_empty : Icons.check,
                isEnabled: !state.isLoading,
                onPressed: _saveDeliveryNote,
              )
            : null,
      ),
    );
  }
}
