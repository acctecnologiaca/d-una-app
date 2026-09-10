import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/draft_toast.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/bottom_sheet_action_item.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart'
    show deliveryNoteDetailProvider, paginatedDeliveryNotesProvider;
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
  bool _hasInitializedTab = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedTab && _tabController.index == 0) {
      final tabStr = GoRouterState.of(context).uri.queryParameters['tab'];
      if (tabStr != null) {
        final initialTab = int.tryParse(tabStr);
        if (initialTab != null && initialTab >= 0 && initialTab < 6) {
          _tabController.index = initialTab;
        }
      }
      _hasInitializedTab = true;
    }
  }

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
      final tabStr = GoRouterState.of(context).uri.queryParameters['tab'];
      final queryTab = tabStr != null ? int.tryParse(tabStr) : null;

      final repo = ref.read(deliveryNotesRepositoryProvider);
      final note = await repo.getDeliveryNoteById(widget.noteId!);
      if (note != null && mounted) {
        notifier.loadExistingDeliveryNote(note);

        final draft = await notifier.checkExistingDraft(noteId: widget.noteId);
        if (draft != null && mounted) {
          notifier.restoreDraft(draft, originalNote: note);
          if (queryTab != null && queryTab >= 0 && queryTab < 6) {
            _tabController.index = queryTab;
          } else if (draft.tabIndex >= 0 && draft.tabIndex < 6) {
            _tabController.index = draft.tabIndex;
          }
          DraftToast.show(
            context,
            message: 'Cambios restaurados automáticamente',
            onDiscard: () async {
              final shouldDiscard = await _showDiscardDialog();
              if (shouldDiscard && mounted) {
                await notifier.discardDraft(noteId: widget.noteId);
                notifier.loadExistingDeliveryNote(note);
                setState(() {
                  _tabController.index = 0;
                });
              }
            },
          );
        } else {
          if (queryTab != null && queryTab >= 0 && queryTab < 6) {
            _tabController.index = queryTab;
          }
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
        message: 'Cambios restaurados automáticamente',
        onDiscard: () async {
          final shouldDiscard = await _showDiscardDialog();
          if (shouldDiscard && mounted) {
            await notifier.discardDraft();
            notifier.reset();
            setState(() {
              _tabController.index = 0;
            });
          }
        },
      );
    }
  }

  Future<bool> _showDiscardDialog() async {
    final colors = Theme.of(context).colorScheme;
    final isEditing = widget.noteId != null && widget.noteId!.isNotEmpty;
    return await CustomDialog.show<bool>(
          context: context,
          dialog: CustomDialog.destructive(
            title: isEditing
                ? '¿Descartar cambios locales?'
                : '¿Descartar borrador?',
            contentText: isEditing
                ? 'Se eliminarán las modificaciones sin guardar y se recargarán los datos del servidor.'
                : 'Se eliminará el borrador guardado automáticamente y se limpiará el formulario.',
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                ),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePop() async {
    final state = ref.read(createDeliveryNoteProvider);
    final hasChanges = state.isDirty;

    if (hasChanges) {
      await ref
          .read(createDeliveryNoteProvider.notifier)
          .saveDraftNow(tabIndex: _tabController.index, noteId: widget.noteId);
    }

    ref.read(createDeliveryNoteProvider.notifier).reset();
    if (!mounted) return;

    if (hasChanges) {
      AppToast.info(
        context,
        message: 'Cambios guardados temporalmente',
        icon: Icons.bookmark_added_outlined,
      );
    }

    context.pop();
  }

  Future<void> _handleSaveInEditMode() async {
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
        ref.invalidate(deliveryNoteDetailProvider(savedNote.id));
        ref.invalidate(paginatedDeliveryNotesProvider);
        AppToast.success(
          context,
          message: 'Nota de entrega actualizada exitosamente.',
        );
        context.pushReplacement('/delivery-notes/view/${savedNote.id}');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Error al actualizar: $e');
      }
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
        ref.invalidate(deliveryNoteDetailProvider(savedNote.id));
        ref.invalidate(paginatedDeliveryNotesProvider);
        AppToast.success(
          context,
          message: widget.noteId != null
              ? 'Nota de entrega actualizada exitosamente.'
              : 'Nota de entrega guardada exitosamente.',
        );
        _showPostSaveOptions(savedNote);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Error: $e');
      }
    }
  }

  Future<void> _showPostSaveOptions(DeliveryNoteModel savedNote) async {
    final hasMissing = savedNote.hasMissingSerialsEffective;

    final result = await CustomActionSheet.show<bool>(
      context: context,
      title: 'Nota ${savedNote.deliveryNoteNumber} guardada',
      actions: [
        BottomSheetActionItem(
          icon: Symbols.signature,
          label: 'Confirmar recepción ahora',
          enabled: !hasMissing,
          subtitle: hasMissing
              ? 'Faltan seriales por asignar. No se puede confirmar recepción'
              : null,
          onTap: () async {
            if (hasMissing) return;
            context.pop(true);
            await ConfirmDeliveryNoteReceptionDialog.show(
              context,
              ref,
              savedNote,
            );
            if (mounted) {
              context.pushReplacement('/delivery-notes/view/${savedNote.id}');
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.send_outlined,
          label: 'Enviar ahora',
          enabled: !hasMissing,
          subtitle: hasMissing
              ? 'Faltan seriales por asignar. No se puede enviar'
              : null,
          onTap: () {
            if (hasMissing) return;
            context.pop(true);
            _showSendOptions(savedNote);
          },
        ),
        BottomSheetActionItem(
          icon: Icons.history_outlined,
          label: 'Enviar más tarde',
          onTap: () {
            context.pop(true);
            context.pushReplacement('/delivery-notes/view/${savedNote.id}');
          },
        ),
      ],
    );
    if (result != true && mounted) {
      context.pushReplacement('/delivery-notes/view/${savedNote.id}');
    }
  }

  Future<void> _showSendOptions(DeliveryNoteModel note) async {
    if (note.hasMissingSerialsEffective) {
      AppToast.error(
        context,
        message:
            'No se puede enviar la nota de entrega porque faltan seriales por asignar.',
      );
      return;
    }

    final result = await CustomActionSheet.show<bool>(
      context: context,
      title: 'Enviar Nota de Entrega',
      actions: [
        BottomSheetActionItem(
          icon: Icons.email_outlined,
          label: 'Enviar por correo electrónico',
          onTap: () async {
            context.pop(true);
            await SendDeliveryNoteEmailSheet.show(context, note);
            if (mounted) {
              context.pushReplacement('/delivery-notes/view/${note.id}');
            }
          },
        ),
        BottomSheetActionItem(
          icon: 'assets/icons/whatsapp_icon.png',
          label: 'Enviar por WhatsApp',
          onTap: () async {
            context.pop(true);
            await SendDeliveryNoteWhatsAppSheet.show(context, note);
            if (mounted) {
              context.pushReplacement('/delivery-notes/view/${note.id}');
            }
          },
        ),
      ],
    );
    if (result != true && mounted) {
      context.pushReplacement('/delivery-notes/view/${note.id}');
    }
  }

  void _showActionsMenu(WidgetRef ref) {
    final notifier = ref.read(createDeliveryNoteProvider.notifier);
    final isEditing = widget.noteId != null && widget.noteId!.isNotEmpty;

    CustomActionSheet.show(
      context: context,
      title: 'Opciones de nota de entrega',
      actions: [
        BottomSheetActionItem(
          icon: Icons.bookmark_add_outlined,
          label: 'Guardar y continuar luego',
          subtitle: 'Guarda un borrador local para continuar luego',
          onTap: () async {
            context.pop();
            await notifier.saveDraftNow(
              tabIndex: _tabController.index,
              noteId: widget.noteId,
            );
            notifier.reset();
            if (!mounted) return;
            AppToast.info(
              context,
              message: 'Cambios guardados temporalmente',
              icon: Icons.bookmark_added_outlined,
            );
            context.pop();
          },
        ),
        BottomSheetActionItem(
          icon: Icons.delete_outline,
          label: isEditing
              ? 'Descartar cambios locales'
              : 'Descartar borrador',
          subtitle: 'Elimina las modificaciones no guardadas',
          onTap: () async {
            context.pop();
            final shouldDiscard = await _showDiscardDialog();
            if (!shouldDiscard) return;
            await notifier.discardDraft(noteId: widget.noteId);
            notifier.reset();
            if (!mounted) return;
            context.pop();
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
            if (widget.noteId != null)
              IconButton(
                icon: Icon(
                  state.isLoading ? Icons.hourglass_empty : Icons.save_outlined,
                  color: (state.isDirty && !state.isLoading)
                      ? colors.onSurfaceVariant
                      : colors.onSurfaceVariant.withValues(alpha: 0.38),
                ),
                tooltip: state.isDirty ? 'Guardar cambios' : 'Sin modificaciones',
                onPressed: (state.isDirty && !state.isLoading)
                    ? _handleSaveInEditMode
                    : null,
              ),
            IconButton(
              icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
              onPressed: () => _showActionsMenu(ref),
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
      final isReadyToSave = state.isDetailsValid &&
          state.items.isNotEmpty &&
          state.isDeliveryValid;
      final canSave = !state.isLoading && state.isDirty && isReadyToSave;

      return Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          label: state.isLoading ? 'Guardando...' : 'Guardar',
          icon: state.isLoading ? Icons.hourglass_empty : Icons.save_outlined,
          isEnabled: canSave,
          onPressed: canSave ? _saveDeliveryNote : null,
        ),
      );
    }

    return null;
  }
}
