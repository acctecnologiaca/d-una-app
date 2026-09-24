import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../providers/view_quote_provider.dart';
import '../../quotes_list/providers/quotes_provider.dart';
import '../../create_quote/providers/create_quote_provider.dart';
import '../tabs/view_quote_products_tab.dart';
import '../tabs/view_quote_services_tab.dart';
import '../tabs/view_quote_details_tab.dart';
import '../tabs/view_quote_conditions_tab.dart';
import '../tabs/view_quote_summary_tab.dart';
import '../../create_quote/providers/quote_validation_provider.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../quotes_list/quote_selection_actions.dart';
import '../../../domain/models/quote_model.dart' show QuoteStatus;
import '../../../data/models/quote.dart';
import '../../../domain/repositories/quotes_repository.dart';
import '../../../data/models/quote_item_product.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/core/pdf/templates/quote_pdf_template.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:pdf/pdf.dart';
import '../../../../../shared/utils/string_utils.dart';
import '../../../../supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import 'package:d_una_app/features/supplier_orders/domain/models/supplier_order_status.dart';
import '../widgets/send_email_bottom_sheet.dart';
import '../widgets/select_oc_suppliers_sheet.dart';
import '../widgets/send_whatsapp_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/core/utils/contact_utils.dart';
import 'package:d_una_app/core/theme/app_theme.dart';

class ViewQuoteScreen extends ConsumerStatefulWidget {
  final String quoteId;
  final bool triggerSend;
  const ViewQuoteScreen({
    super.key,
    required this.quoteId,
    this.triggerSend = false,
  });

  @override
  ConsumerState<ViewQuoteScreen> createState() => _ViewQuoteScreenState();
}

class _ViewQuoteScreenState extends ConsumerState<ViewQuoteScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  bool _hasTriggeredSend = false;
  RealtimeChannel? _singleQuoteChannel;
  RealtimeChannel? _linkedOrdersChannel;
  RealtimeChannel? _linkedDeliveryNotesChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicializamos con 5 pestañas, empezando en la última (Resúmen = índice 4)
    _tabController = TabController(length: 5, vsync: this, initialIndex: 4);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });

    _initSingleQuoteRealtime();
    _initLinkedDocsRealtime();

    // Etapa 1: Iniciar validación de productos inmediatamente para alimentar los badges
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(quoteValidationProvider(widget.quoteId).notifier)
            .startValidation();
      }
    });
  }

  void _initSingleQuoteRealtime() {
    _singleQuoteChannel = Supabase.instance.client
        .channel(
          'public:quote_${widget.quoteId}_${DateTime.now().millisecondsSinceEpoch}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'quotes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.quoteId,
          ),
          callback: (payload) {
            if (mounted) {
              ref.invalidate(viewQuoteProvider(widget.quoteId));
              ref.invalidate(linkedSupplierOrdersProvider(widget.quoteId));
              ref.invalidate(linkedDeliveryNotesProvider(widget.quoteId));
              ref
                  .read(quoteValidationProvider(widget.quoteId).notifier)
                  .startValidation();
              ref.read(quotesListProvider.notifier).refresh();
              ref.invalidate(paginatedQuoteSearchProvider);
            }
          },
        )
        .subscribe();
  }

  void _initLinkedDocsRealtime() {
    _linkedOrdersChannel = Supabase.instance.client
        .channel(
          'public:quote_orders_${widget.quoteId}_${DateTime.now().millisecondsSinceEpoch}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'supplier_orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'quote_id',
            value: widget.quoteId,
          ),
          callback: (payload) {
            if (mounted) {
              ref.invalidate(linkedSupplierOrdersProvider(widget.quoteId));
              ref.invalidate(viewQuoteProvider(widget.quoteId));
            }
          },
        )
        .subscribe();

    _linkedDeliveryNotesChannel = Supabase.instance.client
        .channel(
          'public:quote_notes_${widget.quoteId}_${DateTime.now().millisecondsSinceEpoch}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'delivery_notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'quote_id',
            value: widget.quoteId,
          ),
          callback: (payload) {
            if (mounted) {
              ref.invalidate(linkedDeliveryNotesProvider(widget.quoteId));
              ref.invalidate(viewQuoteProvider(widget.quoteId));
            }
          },
        )
        .subscribe();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(viewQuoteProvider(widget.quoteId));
      ref.invalidate(linkedSupplierOrdersProvider(widget.quoteId));
      ref.invalidate(linkedDeliveryNotesProvider(widget.quoteId));
    }
  }

  @override
  void dispose() {
    _singleQuoteChannel?.unsubscribe();
    _singleQuoteChannel = null;
    _linkedOrdersChannel?.unsubscribe();
    _linkedOrdersChannel = null;
    _linkedDeliveryNotesChannel?.unsubscribe();
    _linkedDeliveryNotesChannel = null;
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<QuoteState>(viewQuoteProvider(widget.quoteId), (prev, next) {
      if (widget.triggerSend && !_hasTriggeredSend && next.quote != null) {
        _hasTriggeredSend = true;
        final quote = next.quote!;
        final isSentOrResent =
            quote.status == QuoteStatus.sent.dbValue ||
            quote.status == QuoteStatus.resent.dbValue ||
            quote.status == QuoteStatus.opened.dbValue ||
            quote.status == QuoteStatus.inReview.dbValue;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showSendOptions(context, quote, isSentOrResent);
          }
        });
      }
    });

    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(viewQuoteProvider(widget.quoteId));
    final quote = state.quote;
    final isSentOrResent =
        quote != null &&
        (quote.status == QuoteStatus.sent.dbValue ||
            quote.status == QuoteStatus.resent.dbValue ||
            quote.status == QuoteStatus.opened.dbValue ||
            quote.status == QuoteStatus.inReview.dbValue);

    final isSendDisabled =
        quote == null ||
        quote.status == QuoteStatus.approved.dbValue ||
        quote.status == QuoteStatus.rejected.dbValue ||
        quote.status == QuoteStatus.cancelled.dbValue ||
        quote.status == QuoteStatus.finalized.dbValue;

    // Pre-cargar estado de OCs por proveedor para que esté listo al abrir el ActionSheet
    ref.watch(quoteSuppliersOcStatusProvider(widget.quoteId));

    if (widget.triggerSend &&
        !_hasTriggeredSend &&
        quote != null &&
        !isSendDisabled) {
      _hasTriggeredSend = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSendOptions(context, quote, isSentOrResent);
        }
      });
    }

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Cotización',
        subtitle: state.clientName != null
            ? '${state.currentQuoteNumber} (${state.clientName})'
            : (state.currentQuoteNumber ?? 'Cargando...'),
        actions: [
          IconButton(
            onPressed: isSendDisabled
                ? null
                : () => _showSendOptions(context, quote, isSentOrResent),
            icon: Icon(
              isSentOrResent ? Symbols.forward : Icons.send,
              color: isSendDisabled ? colors.outline : colors.onSurfaceVariant,
            ),
            tooltip: isSendDisabled
                ? 'Cotización ${quote != null ? QuoteStatus.fromDbValue(quote.status).label.toLowerCase() : ''}. No se puede enviar'
                : (isSentOrResent ? 'Reenviar' : 'Enviar'),
          ),
          IconButton(
            onPressed: () {
              CustomActionSheet.show(
                context: context,
                title: 'Opciones',
                actions: [
                  BottomSheetActionItem(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Descargar PDF',
                    onTap: () {
                      final quote = state.quote;
                      if (quote == null) return;

                      final userProfile = ref.read(userProfileProvider).value;
                      final userEmail =
                          Supabase.instance.client.auth.currentUser?.email;

                      if (userProfile == null) {
                        AppToast.info(
                          context,
                          message:
                              'Cargando perfil de usuario... Por favor espere.',
                        );
                        return;
                      }

                      context.pop(); // Cerrar action sheet

                      context.push(
                        '/pdf-preview',
                        extra: {
                          'title': 'Previsualizar Cotización',
                          'subtitle':
                              ' ${quote.quoteNumber} (${quote.clientName})',
                          'fileName': StringUtils.sanitizeForFileName(
                            '${quote.dateIssued.toIso8601String().substring(0, 10)}_${quote.clientName ?? ''}_${quote.quoteNumber ?? quote.id}_${quote.quoteTag ?? ''}.pdf',
                          ),
                          'buildPdf': (PdfPageFormat format) =>
                              QuotePdfTemplate(
                                quote: quote,
                                products: quote.products ?? [],
                                services: quote.services ?? [],
                                conditions: quote.conditions ?? [],
                                userProfile: userProfile,
                                userEmail: userEmail,
                              ).generate(format),
                        },
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Builder(
                    builder: (sheetContext) {
                      final isFinalized =
                          state.quote?.status == QuoteStatus.finalized.dbValue;
                      final isCancelled =
                          state.quote?.status == QuoteStatus.cancelled.dbValue;
                      final isStatusChangeDisabled = isFinalized || isCancelled;
                      return BottomSheetActionItem(
                        icon: Symbols.conversion_path,
                        label: 'Cambiar estatus',
                        enabled: !isStatusChangeDisabled,
                        subtitle: isStatusChangeDisabled
                            ? (isFinalized
                                  ? 'Cotización finalizada. No se puede cambiar de estado'
                                  : 'Cotización cancelada. No se puede cambiar de estado')
                            : null,
                        onTap: () async {
                          sheetContext.pop(); // Close the action sheet

                          final currentStatusStr = state.quote?.status;
                          if (currentStatusStr == null) return;

                          final currentEnum = QuoteStatus.fromDbValue(
                            currentStatusStr,
                          );
                          final selectedStatus =
                              await QuoteSelectionActions.showStatusDialog(
                                context,
                                currentEnum,
                              );

                          if (selectedStatus != null &&
                              selectedStatus != currentEnum) {
                            try {
                              await ref
                                  .read(quotesListProvider.notifier)
                                  .updateQuoteStatus(
                                    widget.quoteId,
                                    selectedStatus.dbValue,
                                  );

                              await ref
                                  .read(
                                    viewQuoteProvider(widget.quoteId).notifier,
                                  )
                                  .loadExistingQuote(widget.quoteId);

                              refreshAllQuoteProviders(ref);

                              if (context.mounted) {
                                AppToast.success(
                                  context,
                                  message:
                                      'Estatus cambiado a "${selectedStatus.label}"',
                                );
                              }
                            } on InsufficientStockException catch (e) {
                              if (!context.mounted) return;
                              CustomDialog.show(
                                context: context,
                                dialog: CustomDialog.confirmation(
                                  icon: Symbols.warning,
                                  iconColor: Colors.amber.shade800,
                                  title: 'Stock Insuficiente',
                                  contentText:
                                      'No se puede aprobar la cotización porque no hay suficiente stock disponible en el inventario propio de los siguientes productos:\n\n${e.productNames.map((name) => '• $name').join('\n')}\n\nPor favor, agregue más stock para poder aprobarla.',
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pop(),
                                      child: const Text('Entendido'),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              AppToast.error(
                                context,
                                message: 'Error al cambiar estatus: $e',
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final statusStr = state.quote?.status;
                      final isBlockedForOcNe =
                          statusStr == QuoteStatus.rejected.dbValue ||
                          statusStr == QuoteStatus.finalized.dbValue ||
                          statusStr == QuoteStatus.cancelled.dbValue;
                      final hasAffiliatedProducts = state.products.any(
                        (p) =>
                            p.sourceType == QuoteItemSourceType.affiliated ||
                            p.supplierBranchStockId != null,
                      );
                      final validationState = ref.watch(
                        quoteValidationProvider(widget.quoteId),
                      );
                      final hasValidationAlerts = validationState.items.values
                          .any(
                            (i) =>
                                i.statuses.contains(
                                  QuoteValidationStatus.priceIncreased,
                                ) ||
                                i.statuses.contains(
                                  QuoteValidationStatus.outOfStock,
                                ) ||
                                i.statuses.contains(
                                  QuoteValidationStatus.lowStock,
                                ),
                          );
                      // Verificación: ¿Todos los proveedores ya tienen OC?
                      final ocStatusAsync = ref.watch(
                        quoteSuppliersOcStatusProvider(widget.quoteId),
                      );
                      final allOcsGenerated =
                          ocStatusAsync.whenOrNull(
                            data: (statuses) =>
                                statuses.isNotEmpty &&
                                statuses.every((s) => s.hasExistingOc),
                          ) ??
                          false;
                      final isEnabled =
                          !isBlockedForOcNe &&
                          hasAffiliatedProducts &&
                          !hasValidationAlerts &&
                          !allOcsGenerated;
                      String? subtitleText;
                      if (isBlockedForOcNe) {
                        subtitleText =
                            'No disponible para cotizaciones rechazadas, finalizadas o canceladas';
                      } else if (!hasAffiliatedProducts) {
                        subtitleText =
                            'Esta cotización no contiene productos de proveedores afiliados';
                      } else if (hasValidationAlerts) {
                        subtitleText =
                            'Bloqueado: La cotización contiene productos con alza de costo o stock insuficiente. Resuelve las alertas antes de generar la orden';
                      } else if (allOcsGenerated) {
                        subtitleText =
                            'Todas las órdenes de compra ya fueron generadas para esta cotización';
                      }

                      return BottomSheetActionItem(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Generar órdenes de compra',
                        enabled: isEnabled,
                        subtitle: subtitleText,
                        onTap: () async {
                          final router = GoRouter.of(context);
                          final quote = state.quote;
                          if (quote == null) return;

                          try {
                            final repo = ref.read(
                              supplierOrdersRepositoryProvider,
                            );

                            final statuses = await repo
                                .getQuoteSuppliersOcStatus(quote.id);

                            if (!context.mounted) return;

                            // Close the action sheet
                            Navigator.of(context).pop();

                            final selection = await SelectOcSuppliersSheet.show(
                              context: context,
                              suppliers: statuses,
                            );

                            if (selection == null ||
                                selection.selectedSupplierIds.isEmpty) {
                              return;
                            }

                            if (context.mounted) {
                              AppToast.info(
                                context,
                                message: 'Generando órdenes de compra...',
                                duration: const Duration(seconds: 1),
                              );
                            }

                            final result = await repo.batchGenerateFromQuote(
                              quote.id,
                              selectedSupplierIds:
                                  selection.selectedSupplierIds,
                              supplierDestinations:
                                  selection.supplierDestinations,
                            );

                            final skipped =
                                result['skippedSuppliers'] as List<dynamic>? ??
                                [];
                            final generatedCount =
                                result['generatedCount'] as int? ?? 0;

                            if (generatedCount > 0) {
                              await ref
                                  .read(viewQuoteProvider(quote.id).notifier)
                                  .loadExistingQuote(quote.id);
                              refreshAllQuoteProviders(ref);
                              ref.invalidate(
                                quoteSuppliersOcStatusProvider(quote.id),
                              );
                            }

                            if (skipped.isNotEmpty) {
                              if (context.mounted) {
                                await CustomDialog.show(
                                  context: context,
                                  dialog: CustomDialog.confirmation(
                                    icon: Icons.warning_amber_rounded,
                                    iconColor: Colors.amber.shade800,
                                    title: 'Órdenes Generadas con Advertencias',
                                    contentText:
                                        'Se generaron $generatedCount órdenes de compra.\n\nNo se generaron órdenes de compra para los siguientes ítems/proveedores porque corresponden a inventario propio, proveedores externos o no están afiliados oficialmente:\n\n${skipped.map((s) => '• $s').join('\n')}',
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pop(),
                                        child: const Text('Entendido'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                AppToast.success(
                                  context,
                                  message:
                                      'Se generaron $generatedCount órdenes de compra exitosamente.',
                                );
                              }
                            }

                            final query =
                                quote.quoteNumber ??
                                state.currentQuoteNumber ??
                                quote.id;
                            router.push(
                              '/supplier-orders/search',
                              extra: {'initialQuery': query, 'readOnly': true},
                            );
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.error(
                                context,
                                message: 'Error al generar órdenes: $e',
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                  Builder(
                    builder: (sheetContext) {
                      final statusStr = state.quote?.status;
                      final isApproved =
                          statusStr == QuoteStatus.approved.dbValue;

                      return BottomSheetActionItem(
                        icon: Symbols.list_alt,
                        label: 'Generar nota de entrega',
                        enabled: isApproved,
                        subtitle: !isApproved
                            ? 'Disponible únicamente cuando la cotización esté aprobada'
                            : null,
                        onTap: () async {
                          final quote = state.quote;
                          if (quote == null) return;

                          final router = GoRouter.of(sheetContext);
                          Navigator.of(
                            sheetContext,
                          ).pop(); // Close action sheet

                          try {
                            // Supplier Monetization Guardrail:
                            // Check if quote contains products from affiliated suppliers
                            final hasAffiliatedProducts = state.products.any(
                              (p) =>
                                  p.sourceType ==
                                      QuoteItemSourceType.affiliated ||
                                  p.supplierBranchStockId != null,
                            );

                            if (hasAffiliatedProducts) {
                              final ocRepo = ref.read(
                                supplierOrdersRepositoryProvider,
                              );
                              final supplierStatuses = await ocRepo
                                  .getQuoteSuppliersOcStatus(quote.id);

                              if (supplierStatuses.isNotEmpty) {
                                final orders = await ocRepo
                                    .getSupplierOrdersByQuoteId(quote.id);
                                final approvedSupplierIds = orders
                                    .where(
                                      (o) =>
                                          o.status ==
                                              SupplierOrderStatus.approved ||
                                          o.status ==
                                              SupplierOrderStatus.finalized,
                                    )
                                    .map((o) => o.supplierId)
                                    .toSet();

                                final pendingSuppliers = supplierStatuses
                                    .where(
                                      (s) => !approvedSupplierIds.contains(
                                        s.supplierId,
                                      ),
                                    )
                                    .toList();

                                if (pendingSuppliers.isNotEmpty &&
                                    context.mounted) {
                                  await CustomDialog.show(
                                    context: context,
                                    dialog: CustomDialog.confirmation(
                                      icon: Symbols.lock,
                                      title: 'Orden de Compra Requerida',
                                      contentText:
                                          'Esta cotización contiene productos de proveedores afiliados (${pendingSuppliers.map((s) => s.supplierName).join(', ')}) que no cuentan con una Orden de Compra aprobada o finalizada en la plataforma.\n\nPara garantizar el despacho formal y la correcta trazabilidad, debes emitir la Orden de Compra y esperar su aprobación antes de generar la Nota de Entrega.',
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pop(),
                                          child: const Text('Entendido'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }
                              }
                            }

                            if (mounted) {
                              router.push(
                                '/delivery-notes/create?quoteId=${quote.id}',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.error(
                                context,
                                message:
                                    'Error al preparar nota de entrega: $e',
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  BottomSheetActionItem(
                    icon: Icons.content_copy_outlined,
                    label: 'Crear una copia',
                    onTap: () async {
                      final router = GoRouter.of(context);
                      context.pop(); // Close the action sheet
                      await ref
                          .read(createQuoteProvider.notifier)
                          .loadQuoteAsCopy(widget.quoteId);
                      if (mounted) {
                        router.push('/quotes/create');
                      }
                    },
                  ),
                  Builder(
                    builder: (sheetContext) {
                      final quoteState = ref.watch(
                        viewQuoteProvider(widget.quoteId),
                      );
                      final isArchived = quoteState.quote?.isArchived ?? false;
                      return BottomSheetActionItem(
                        icon: isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                        label: isArchived ? 'Desarchivar' : 'Archivar',
                        onTap: () async {
                          final router = GoRouter.of(context);

                          sheetContext.pop(); // Close the action sheet
                          await ref
                              .read(quotesListProvider.notifier)
                              .archiveQuote(
                                widget.quoteId,
                                archive: !isArchived,
                              );

                          if (context.mounted) {
                            AppToast.success(
                              context,
                              message: isArchived
                                  ? 'Cotización desarchivada exitosamente'
                                  : 'Cotización archivada exitosamente',
                            );
                            router.pop(); // Return to quotes list
                          }
                        },
                      );
                    },
                  ),
                ],
              );
            },
            icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
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
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('General'),
                  if (_isQuoteExpired(state)) ...[
                    const SizedBox(width: 6),
                    Badge(backgroundColor: colors.error, smallSize: 8),
                  ],
                ],
              ),
            ),
            Tab(
              child: Consumer(
                builder: (context, ref, _) {
                  final validationState = ref.watch(
                    quoteValidationProvider(widget.quoteId),
                  );
                  final hasAlerts = validationState.items.values.any(
                    (item) => item.statuses.isNotEmpty,
                  );
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Productos'),
                      if (hasAlerts) ...[
                        const SizedBox(width: 6),
                        Badge(backgroundColor: colors.error, smallSize: 8),
                      ],
                    ],
                  );
                },
              ),
            ),
            const Tab(text: 'Servicios'),
            const Tab(text: 'Condiciones'),
            const Tab(text: 'Resúmen'),
          ],
        ),
      ),
      body: state.isLoading && state.quote == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                ViewQuoteDetailsTab(quoteId: widget.quoteId),
                ViewQuoteProductsTab(quoteId: widget.quoteId),
                ViewQuoteServicesTab(quoteId: widget.quoteId),
                ViewQuoteConditionsTab(quoteId: widget.quoteId),
                ViewQuoteSummaryTab(
                  quoteId: widget.quoteId,
                  onNavigateToTab: (index) => _tabController.animateTo(index),
                ),
              ],
            ),
      floatingActionButton: Builder(
        builder: (context) {
          final quote = state.quote;
          if (quote == null) return const SizedBox.shrink();

          final currentStatus = quote.status;
          final showWhatsAppFab =
              currentStatus == QuoteStatus.sent.dbValue ||
              currentStatus == QuoteStatus.resent.dbValue ||
              currentStatus == QuoteStatus.inReview.dbValue ||
              currentStatus == QuoteStatus.opened.dbValue ||
              currentStatus == QuoteStatus.approved.dbValue;

          final canEdit = currentStatus != QuoteStatus.finalized.dbValue &&
              currentStatus != QuoteStatus.cancelled.dbValue;

          if (!showWhatsAppFab && !canEdit) {
            return const SizedBox.shrink();
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showWhatsAppFab) ...[
                FloatingActionButton(
                  heroTag: 'quote_whatsapp_contact_fab',
                  onPressed: () => _contactClientWhatsApp(context, quote),
                  backgroundColor: colors.greenBase,
                  tooltip: 'Contactar por WhatsApp',
                  child: Image.asset(
                    'assets/icons/whatsapp_icon.png',
                    width: 28,
                    height: 28,
                    color: colors.greenBaseOn,
                  ),
                ),
                if (canEdit) const SizedBox(height: 16),
              ],
              if (canEdit)
                FloatingActionButton(
                  heroTag: 'quote_edit_fab',
                  onPressed: _handleEditQuote,
                  child: const Icon(Icons.edit_outlined),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleEditQuote() async {
    await context.push(
      '/quotes/edit/${widget.quoteId}?tab=${_tabController.index}',
    );
    // Al volver, refrescamos el proveedor de visualización para obtener los datos actualizados
    ref.invalidate(viewQuoteProvider(widget.quoteId));
    // Y disparamos la validación de inventario inmediatamente
    ref.read(quoteValidationProvider(widget.quoteId).notifier).validate();
  }

  Future<void> _contactClientWhatsApp(BuildContext context, Quote quote) async {
    final phone =
        quote.contact?.phone ?? quote.contactPhone ?? quote.clientPhone ?? '';

    if (phone.trim().isEmpty) {
      if (context.mounted) {
        CustomDialog.show(
          context: context,
          dialog: CustomDialog.confirmation(
            title: 'Contacto no disponible',
            contentText:
                'El cliente o contacto seleccionado no cuenta con un número de teléfono registrado.',
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final contactName = quote.contactName ?? quote.clientName ?? '';
    final quoteNumber = quote.quoteNumber ?? '';
    final msg = contactName.isNotEmpty
        ? 'Hola $contactName, le escribo con respecto a la cotización #$quoteNumber.'
        : 'Hola, le escribo con respecto a la cotización #$quoteNumber.';

    try {
      await ContactUtils.launchWhatsApp(phone.trim(), message: msg);
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, message: 'No se pudo abrir WhatsApp: $e');
      }
    }
  }

  bool _isQuoteExpired(QuoteState state) {
    final statusStr = state.quote?.status;
    if (statusStr == null) return false;

    final status = QuoteStatus.fromDbValue(statusStr);

    // Solo consideramos vencidas las cotizaciones que están en estados "pendientes"
    final isPending =
        status == QuoteStatus.draft ||
        status == QuoteStatus.sent ||
        status == QuoteStatus.resent ||
        status == QuoteStatus.opened ||
        status == QuoteStatus.inReview;

    if (!isPending) return false;

    final expirationDate = state.dateIssued.add(
      Duration(days: state.validityDays),
    );
    return expirationDate.isBefore(DateTime.now());
  }

  void _showSendOptions(
    BuildContext context,
    Quote quote,
    bool isSentOrResent,
  ) {
    // Obtener la versión más reciente de la cotización si está disponible en el provider
    final currentQuote =
        ref.read(viewQuoteProvider(widget.quoteId)).quote ?? quote;
    final currentIsSentOrResent =
        currentQuote.status == QuoteStatus.sent.dbValue ||
        currentQuote.status == QuoteStatus.resent.dbValue ||
        currentQuote.status == QuoteStatus.opened.dbValue ||
        currentQuote.status == QuoteStatus.inReview.dbValue;

    final isSendDisabled =
        currentQuote.status == QuoteStatus.approved.dbValue ||
        currentQuote.status == QuoteStatus.rejected.dbValue ||
        currentQuote.status == QuoteStatus.cancelled.dbValue ||
        currentQuote.status == QuoteStatus.finalized.dbValue;

    if (isSendDisabled) {
      AppToast.warning(
        context,
        message:
            'La cotización está ${QuoteStatus.fromDbValue(currentQuote.status).label.toLowerCase()} y no se puede enviar.',
      );
      return;
    }

    _checkDateAndSend(
      context: context,
      quote: currentQuote,
      onSend: (targetQuote) {
        CustomActionSheet.show(
          context: context,
          title: currentIsSentOrResent
              ? 'Reenviar cotización'
              : 'Enviar cotización',
          actions: [
            BottomSheetActionItem(
              icon: Icons.email_outlined,
              label: currentIsSentOrResent
                  ? 'Reenviar por correo electrónico'
                  : 'Enviar por correo electrónico',
              onTap: () {
                Navigator.of(context).pop();
                SendEmailBottomSheet.show(context, targetQuote);
              },
            ),
            BottomSheetActionItem(
              icon: 'assets/icons/whatsapp_icon.png',
              label: currentIsSentOrResent
                  ? 'Reenviar por WhatsApp'
                  : 'Enviar por WhatsApp',
              onTap: () {
                Navigator.of(context).pop();
                SendWhatsAppBottomSheet.show(context, targetQuote);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkDateAndSend({
    required BuildContext context,
    required Quote quote,
    required Function(Quote quote) onSend,
  }) async {
    final now = DateTime.now();
    final issueDate = quote.dateIssued;
    final isSameDate =
        issueDate.year == now.year &&
        issueDate.month == now.month &&
        issueDate.day == now.day;

    if (isSameDate) {
      onSend(quote);
      return;
    }

    final formattedQuoteDate = DateFormat('dd/MM/yyyy').format(issueDate);
    final formattedToday = DateFormat('dd/MM/yyyy').format(now);

    final action = await CustomDialog.show<String>(
      context: context,
      dialog: CustomDialog.confirmation(
        icon: Icons.date_range_outlined,
        title: 'Fecha de emisión diferente',
        contentText:
            'La fecha de emisión de esta cotización ($formattedQuoteDate) es distinta a la fecha de hoy ($formattedToday). ¿Cómo deseas proceder?',
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop('send_as_is'),
            child: const Text('Enviar así'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop('update_date'),
            child: const Text('Actualizar fecha y enviar'),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop('modify'),
            child: const Text('Modificar'),
          ),
        ],
      ),
    );

    if (action == 'send_as_is') {
      onSend(quote);
    } else if (action == 'update_date') {
      try {
        await ref
            .read(quotesListProvider.notifier)
            .updateQuoteDate(quote.id, DateTime.now());
        ref.invalidate(viewQuoteProvider(quote.id));
        final updatedQuote = quote.copyWith(dateIssued: DateTime.now());
        onSend(updatedQuote);
      } catch (e) {
        if (context.mounted) {
          AppToast.error(context, message: 'Error al actualizar fecha: $e');
        }
      }
    } else if (action == 'modify') {
      if (context.mounted) {
        await context.push('/quotes/edit/${quote.id}?tab=3');
        if (!context.mounted) return;

        // 1. Invalidar provider para que la pantalla ViewQuote se actualice
        ref.invalidate(viewQuoteProvider(quote.id));
        ref.read(quoteValidationProvider(quote.id).notifier).validate();

        // 2. Obtener cotización fresca directamente de la base de datos
        final freshQuote = await ref
            .read(quotesRepositoryProvider)
            .getQuoteWithDetails(quote.id);
        if (context.mounted) {
          final isSentOrResent =
              freshQuote.status == QuoteStatus.sent.dbValue ||
              freshQuote.status == QuoteStatus.resent.dbValue;
          _showSendOptions(context, freshQuote, isSentOrResent);
        }
      }
    }
  }
}
