import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/draft_toast.dart';
import 'package:d_una_app/features/quotes/presentation/create_quote/providers/create_quote_provider.dart';
import 'package:d_una_app/features/quotes/presentation/view_quote/providers/view_quote_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../tabs/quote_products_tab.dart';
import '../tabs/quote_services_tab.dart';
import '../tabs/quote_client_tab.dart';
import '../tabs/quote_details_tab.dart';
import '../tabs/quote_conditions_tab.dart';
import '../tabs/quote_summary_tab.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../supplier_orders/domain/models/supplier_order_status.dart';
import '../../../../supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import '../../../domain/models/quote_model.dart' show QuoteStatus;
import '../../quotes_list/providers/quotes_provider.dart';

class CreateQuoteScreen extends ConsumerStatefulWidget {
  final String? quoteId;
  const CreateQuoteScreen({super.key, this.quoteId});

  @override
  ConsumerState<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends ConsumerState<CreateQuoteScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AppLifecycleListener _lifecycleListener;
  bool _hasInitializedTab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        ref
            .read(createQuoteProvider.notifier)
            .autoSaveDraft(
              tabIndex: _tabController.index,
              quoteId: widget.quoteId,
            );
      }
    });

    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        ref
            .read(createQuoteProvider.notifier)
            .autoSaveDraft(
              tabIndex: _tabController.index,
              quoteId: widget.quoteId,
            );
      },
      onInactive: () {
        ref
            .read(createQuoteProvider.notifier)
            .autoSaveDraft(
              tabIndex: _tabController.index,
              quoteId: widget.quoteId,
            );
      },
    );

    // Initialize state only if needed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentState = ref.read(createQuoteProvider);

      if (widget.quoteId != null) {
        // Modo EDICIÓN:
        if (currentState.quote?.id == widget.quoteId) {
          // La cotización ya está cargada en memoria (p. ej. producto/servicio agregado desde Action Sheet).
          // Verificamos si hay borrador para sincronizar el tabIndex sin destruir el estado en memoria.
          final draft = await ref
              .read(createQuoteProvider.notifier)
              .checkAndRestoreDraft(quoteId: widget.quoteId);
          if (draft != null && mounted) {
            setState(() {
              if (draft.tabIndex >= 0 && draft.tabIndex < 6) {
                _tabController.index = draft.tabIndex;
              }
            });
          }
        } else {
          // La cotización no está en memoria (ej. apertura directa desde listado o detalle).
          // 1. Buscar si existen cambios locales no guardados para esta cotización
          final draft = await ref
              .read(createQuoteProvider.notifier)
              .checkAndRestoreDraft(quoteId: widget.quoteId);

          if (draft != null && mounted) {
            setState(() {
              if (draft.tabIndex >= 0 && draft.tabIndex < 6) {
                _tabController.index = draft.tabIndex;
              }
            });

            DraftToast.show(
              context,
              message: 'Cambios restaurados automáticamente',
              onDiscard: () async {
                final colors = Theme.of(context).colorScheme;
                final shouldDiscard = await CustomDialog.show<bool>(
                  context: context,
                  dialog: CustomDialog.destructive(
                    title: '¿Descartar cambios locales?',
                    contentText:
                        'Se eliminarán las modificaciones sin guardar y se recargarán los datos del servidor.',
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.error,
                          foregroundColor: colors.onError,
                        ),
                        child: const Text('Descartar'),
                      ),
                    ],
                  ),
                );

                if (shouldDiscard == true && mounted) {
                  await ref
                      .read(createQuoteProvider.notifier)
                      .clearDraft(quoteId: widget.quoteId);
                  await ref
                      .read(createQuoteProvider.notifier)
                      .loadQuote(widget.quoteId!);
                  setState(() {
                    _tabController.index = 0;
                  });
                }
              },
            );
          } else {
            // No hay borrador local, cargar datos frescos desde la base de datos
            ref.read(createQuoteProvider.notifier).loadQuote(widget.quoteId!);
          }
        }
      } else {
        // Modo CREACIÓN (nueva cotización):
        if (currentState.quote != null && currentState.quote!.id.isNotEmpty) {
          ref
              .read(createQuoteProvider.notifier)
              .reset(clearPersistedDraft: false);
        }

        final draft = await ref
            .read(createQuoteProvider.notifier)
            .checkAndRestoreDraft();
        if (draft != null && mounted) {
          setState(() {
            if (draft.tabIndex >= 0 && draft.tabIndex < 6) {
              _tabController.index = draft.tabIndex;
            }
          });

          DraftToast.show(
            context,
            message: 'Cambios restaurados automáticamente',
            onDiscard: () async {
              final shouldDiscard = await _showDiscardDialog();
              if (shouldDiscard && mounted) {
                await ref.read(createQuoteProvider.notifier).clearDraft();
                ref
                    .read(createQuoteProvider.notifier)
                    .reset(clearPersistedDraft: true);
                ref.read(createQuoteProvider.notifier).initQuote();
                setState(() {
                  _tabController.index = 0;
                });
              }
            },
          );
        } else {
          final currentNum = ref.read(createQuoteProvider).currentQuoteNumber;
          if (currentNum == null || currentNum.isEmpty) {
            ref.read(createQuoteProvider.notifier).initQuote();
          }
        }
      }

      if (widget.quoteId != null &&
          currentState.quote?.status == QuoteStatus.finalized.dbValue) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'La cotización está finalizada y no se puede editar.',
              ),
            ),
          );
          context.pop();
        }
      }
    });
  }

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
  void dispose() {
    _lifecycleListener.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePop() async {
    final state = ref.read(createQuoteProvider);
    final hasDataOrChanges = state.hasChanges;

    await ref
        .read(createQuoteProvider.notifier)
        .saveDraftNow(tabIndex: _tabController.index, quoteId: widget.quoteId);
    ref
        .read(createQuoteProvider.notifier)
        .reset(clearPersistedDraft: false, quoteId: widget.quoteId);
    if (!mounted) return;

    if (hasDataOrChanges) {
      AppToast.info(
        context,
        message: 'Cambios guardados temporalmente',
        icon: Icons.bookmark_added_outlined,
      );
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createQuoteProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        appBar: StandardAppBar(
          title: widget.quoteId != null
              ? 'Editar cotización'
              : 'Nueva cotización',
          subtitle: state.clientName != null
              ? '${state.currentQuoteNumber} (${state.clientName})'
              : (state.currentQuoteNumber != null
                    ? '${state.currentQuoteNumber}'
                    : 'Cargando...'),
          actions: [
            if (widget.quoteId != null)
              IconButton(
                icon: Icon(
                  Icons.save_outlined,
                  color: state.hasChanges
                      ? colors.onSurfaceVariant
                      : colors.onSurfaceVariant.withValues(alpha: 0.38),
                ),
                tooltip: state.hasChanges
                    ? 'Guardar cambios'
                    : 'Sin modificaciones',
                onPressed: state.hasChanges
                    ? () => _handleSaveInEditMode(ref)
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
            tabs: const [
              Tab(text: 'Productos'),
              Tab(text: 'Servicios'),
              Tab(text: 'Cliente'),
              Tab(text: 'Detalles'),
              Tab(text: 'Condiciones'),
              Tab(text: 'Resúmen'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const QuoteProductsTab(),
            const QuoteServicesTab(),
            const QuoteClientTab(),
            const QuoteDetailsTab(),
            const QuoteConditionsTab(),
            QuoteSummaryTab(
              onNavigateToTab: (index) {
                _tabController.animateTo(index);
              },
            ),
          ],
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget? _buildFab() {
    final state = ref.watch(createQuoteProvider);

    // Only show FAB on Products (0), Services (1), Conditions (4), and Summary (5) tabs
    if (_tabController.index != 0 &&
        _tabController.index != 1 &&
        _tabController.index != 4 &&
        _tabController.index != 5) {
      return null;
    }

    if (_tabController.index == 5) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          label: state.isLoading ? 'Guardando...' : 'Guardar',
          icon: state.isLoading ? Icons.hourglass_empty : Icons.save_outlined,
          isEnabled:
              state.isReadyToFinalize && state.hasChanges && !state.isLoading,
          onPressed: () async {
            if (widget.quoteId != null) {
              try {
                final repo = ref.read(supplierOrdersRepositoryProvider);
                final linked = await repo.getSupplierOrdersByQuoteId(
                  widget.quoteId!,
                );
                final draftOrders = linked
                    .where((o) => o.status == SupplierOrderStatus.draft)
                    .toList();

                if (draftOrders.isNotEmpty) {
                  if (!mounted) return;
                  final confirm = await CustomDialog.show<bool>(
                    context: context,
                    dialog: CustomDialog.confirmation(
                      icon: Icons.warning_amber_rounded,
                      iconColor: Colors.amber.shade800,
                      title: 'Actualizar Cotización',
                      contentText:
                          'Al guardar las modificaciones, las Órdenes de Compra en borrador previas (${draftOrders.map((e) => e.orderNumber).join(', ')}) cambiarán a estatus "Cancelada" para permitir generar órdenes actualizadas. ¿Deseas continuar?',
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Continuar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  await repo.cancelDraftOrdersByQuoteId(widget.quoteId!);
                  ref.invalidate(linkedSupplierOrdersProvider(widget.quoteId!));
                }
              } catch (_) {}
            }

            final success = await ref
                .read(createQuoteProvider.notifier)
                .createQuote();

            if (!mounted) return;

            if (success) {
              final quote = ref.read(createQuoteProvider).quote;
              if (quote != null) {
                ref.invalidate(viewQuoteProvider(quote.id));
                ref.invalidate(linkedSupplierOrdersProvider(quote.id));
              }
              final savedQuoteNumber =
                  ref.read(createQuoteProvider).quote?.quoteNumber ?? '';
              _showPostSaveOptions(ref, savedQuoteNumber);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ref.read(createQuoteProvider).error ?? 'Error al guardar',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: CustomExtendedFab(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/quotes/create/select-product');
          } else if (_tabController.index == 1) {
            context.push('/quotes/create/select-service');
          } else if (_tabController.index == 4) {
            final currentUri = GoRouterState.of(
              context,
            ).uri.replace(queryParameters: {'tab': '4'});
            final encodedUri = Uri.encodeComponent(currentUri.toString());
            context.push('/quotes/create/conditions?returnTo=$encodedUri');
          }
        },
        icon: Icons.add,
        label: 'Agregar',
      ),
    );
  }

  void _showActionsMenu(WidgetRef ref) {
    final state = ref.read(createQuoteProvider);
    final notifier = ref.read(createQuoteProvider.notifier);

    CustomActionSheet.show(
      context: context,
      title: 'Opciones de cotización',
      actions: [
        BottomSheetActionItem(
          icon: Icons.save_outlined,
          label: 'Guardar y continuar luego',
          enabled: state.isReadyToSaveDraft && state.hasChanges,
          onTap: () async {
            context.pop(); // Close sheet
            final success = await notifier.saveAsDraft();
            if (!mounted) return;
            if (success) {
              final quote = ref.read(createQuoteProvider).quote;
              if (quote != null) {
                ref.invalidate(viewQuoteProvider(quote.id));
              }
              context.pop(); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cotización guardada exitosamente'),
                ),
              );
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.delete_outline,
          label: widget.quoteId != null
              ? 'Descartar cambios locales'
              : 'Descartar borrador',
          onTap: () async {
            context.pop(); // Close sheet
            final shouldDiscard = await _showDiscardDialog();
            if (!shouldDiscard) return;
            await ref
                .read(createQuoteProvider.notifier)
                .clearDraft(quoteId: widget.quoteId);
            ref
                .read(createQuoteProvider.notifier)
                .reset(clearPersistedDraft: true, quoteId: widget.quoteId);
            if (!mounted) return;
            context.pop();
          },
        ),
      ],
    );
  }

  Future<bool> _showDiscardDialog() async {
    final colors = Theme.of(context).colorScheme;
    final isEditing = widget.quoteId != null;
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
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

  void _showPostSaveOptions(WidgetRef ref, String quoteNumber) {
    CustomActionSheet.show(
      context: context,
      title: 'Cotización $quoteNumber guardada',
      actions: [
        BottomSheetActionItem(
          icon: Icons.send_outlined,
          label: 'Enviar ahora',
          onTap: () {
            final savedQuote = ref.read(createQuoteProvider).quote;
            final quoteId = savedQuote?.id;
            ref.read(createQuoteProvider.notifier).reset();
            ref.invalidate(paginatedQuotesListProvider);
            ref.invalidate(paginatedQuoteSearchProvider);
            context.pop(); // Close sheet
            if (quoteId != null) {
              context.pushReplacement(
                '/quotes/view/$quoteId',
                extra: {'triggerSend': true},
              );
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.history_outlined,
          label: 'Enviar más tarde',
          onTap: () {
            context.pop(); // Close sheet
            ref.read(createQuoteProvider.notifier).reset();
            ref.invalidate(paginatedQuotesListProvider);
            ref.invalidate(paginatedQuoteSearchProvider);
            context.pop(); // Back to list
          },
        ),
      ],
    );
  }

  Future<void> _handleSaveInEditMode(WidgetRef ref) async {
    final state = ref.read(createQuoteProvider);
    final currentStatus = state.quote?.status;

    if (currentStatus != null && currentStatus != QuoteStatus.draft.dbValue) {
      final confirm =
          await CustomDialog.show<bool>(
            context: context,
            dialog: CustomDialog.confirmation(
              icon: Icons.warning_amber_rounded,
              title: 'Cambio a estatus Borrador',
              contentText:
                  'La cotización se encuentra en estatus "${QuoteStatus.fromDbValue(currentStatus).label}". Al guardar las modificaciones, pasará automáticamente a estatus Borrador. ¿Deseas continuar?',
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirm) return;
    }

    final success = await ref
        .read(createQuoteProvider.notifier)
        .createQuote(status: 'draft');

    if (success && mounted) {
      final savedQuote = ref.read(createQuoteProvider).quote;
      final quoteId = savedQuote?.id;
      ref.invalidate(paginatedQuotesListProvider);
      ref.invalidate(paginatedQuoteSearchProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cotización guardada como Borrador')),
      );

      if (quoteId != null) {
        ref.invalidate(viewQuoteProvider(quoteId));
        context.pushReplacement('/quotes/view/$quoteId');
      }
    }
  }
}
