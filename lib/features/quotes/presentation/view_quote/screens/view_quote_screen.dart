import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../providers/view_quote_provider.dart';
import '../../quotes_list/providers/quotes_provider.dart';
import '../../create_quote/providers/create_quote_provider.dart';
import '../tabs/view_quote_products_tab.dart';
import '../tabs/view_quote_services_tab.dart';
import '../tabs/view_quote_client_tab.dart';
import '../tabs/view_quote_details_tab.dart';
import '../tabs/view_quote_conditions_tab.dart';
import '../tabs/view_quote_summary_tab.dart';
import '../../create_quote/providers/quote_validation_provider.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
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
import '../widgets/send_email_bottom_sheet.dart';
import '../widgets/select_oc_suppliers_sheet.dart';
import '../widgets/send_whatsapp_bottom_sheet.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicializamos con 6 pestañas, empezando en la última (Resúmen = índice 5)
    _tabController = TabController(length: 6, vsync: this, initialIndex: 5);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });

    // Etapa 1: Iniciar validación de productos inmediatamente para alimentar los badges
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(quoteValidationProvider(widget.quoteId).notifier)
            .startValidation();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(viewQuoteProvider(widget.quoteId));
    }
  }

  @override
  void dispose() {
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

    final isSendDisabled = quote == null ||
        quote.status == QuoteStatus.approved.dbValue ||
        quote.status == QuoteStatus.rejected.dbValue ||
        quote.status == QuoteStatus.cancelled.dbValue ||
        quote.status == QuoteStatus.finalized.dbValue;

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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cargando perfil de usuario... Por favor espere.',
                            ),
                          ),
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
                    builder: (context) {
                      final isFinalized =
                          state.quote?.status == QuoteStatus.finalized.dbValue;
                      return BottomSheetActionItem(
                        icon: Symbols.conversion_path,
                        label: 'Cambiar estatus',
                        enabled: !isFinalized,
                        subtitle: isFinalized
                            ? 'Cotización finalizada. No se puede cambiar de estado'
                            : null,
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          context.pop(); // Close the action sheet

                          final currentStatusStr = state.quote?.status;
                          if (currentStatusStr == null) return;

                          final currentEnum = QuoteStatus.fromDbValue(
                            currentStatusStr,
                          );
                          final selectedStatus = await _showStatusDialog(
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

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Estatus cambiado a "${selectedStatus.label}"',
                                  ),
                                ),
                              );
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
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error al cambiar estatus: $e'),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                  Builder(
                    builder: (context) {
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

                      final isEnabled =
                          !isBlockedForOcNe &&
                          hasAffiliatedProducts &&
                          !hasValidationAlerts;

                      String? subtitleText;
                      if (isBlockedForOcNe) {
                        subtitleText =
                            'No disponible para cotizaciones rechazadas, finalizadas o canceladas';
                      } else if (!hasAffiliatedProducts) {
                        subtitleText =
                            'Esta cotización no contiene productos de proveedores afiliados';
                      } else if (hasValidationAlerts) {
                        subtitleText =
                            'Bloqueado: La cotización contiene productos con alza de costo o stock insuficiente. Resuelve las alertas antes de generar la OC';
                      }

                      return BottomSheetActionItem(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Generar ordenes de compra',
                        enabled: isEnabled,
                        subtitle: subtitleText,
                        onTap: () async {
                          final router = GoRouter.of(context);
                          final messenger = ScaffoldMessenger.of(context);

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

                            final availableSuppliers = statuses
                                .where((s) => !s.hasExistingOc)
                                .toList();

                            if (availableSuppliers.isEmpty &&
                                statuses.isNotEmpty) {
                              await CustomDialog.show(
                                context: context,
                                dialog: CustomDialog.confirmation(
                                  icon: Icons.info_outline,
                                  title: 'Órdenes de Compra Emitidas',
                                  contentText:
                                      'Todos los proveedores afiliados de esta cotización ya cuentan con Órdenes de Compra activas generadas.',
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

                            final selectedIds =
                                await SelectOcSuppliersSheet.show(
                                  context: context,
                                  suppliers: statuses,
                                );

                            if (selectedIds == null || selectedIds.isEmpty) {
                              return;
                            }

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Generando órdenes de compra...'),
                                duration: Duration(seconds: 1),
                              ),
                            );

                            final result = await repo.batchGenerateFromQuote(
                              quote.id,
                              selectedSupplierIds: selectedIds,
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
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Se generaron $generatedCount órdenes de compra exitosamente.',
                                  ),
                                ),
                              );
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
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Error al generar órdenes: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                  /* Builder(
                    builder: (context) {
                      final statusStr = state.quote?.status;
                      final isBlockedForOcNe =
                          statusStr == QuoteStatus.rejected.dbValue ||
                          statusStr == QuoteStatus.finalized.dbValue ||
                          statusStr == QuoteStatus.cancelled.dbValue;

                      return BottomSheetActionItem(
                        icon: Icons.receipt_outlined,
                        label: 'Generar nota de entrega',
                        enabled: !isBlockedForOcNe,
                        subtitle: isBlockedForOcNe
                            ? 'No disponible para cotizaciones rechazadas, finalizadas o canceladas'
                            : null,
                        onTap: () {
                          context.pop();
                        },
                      );
                    },
                  ), */
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
                          final messenger = ScaffoldMessenger.of(context);
                          final router = GoRouter.of(context);

                          sheetContext.pop(); // Close the action sheet
                          await ref
                              .read(quotesListProvider.notifier)
                              .archiveQuote(
                                widget.quoteId,
                                archive: !isArchived,
                              );

                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  isArchived
                                      ? 'Cotización desarchivada exitosamente'
                                      : 'Cotización archivada exitosamente',
                                ),
                              ),
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
            const Tab(text: 'Cliente'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Detalles'),
                  if (_isQuoteExpired(state)) ...[
                    const SizedBox(width: 6),
                    Badge(backgroundColor: colors.error, smallSize: 8),
                  ],
                ],
              ),
            ),
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
                ViewQuoteProductsTab(quoteId: widget.quoteId),
                ViewQuoteServicesTab(quoteId: widget.quoteId),
                ViewQuoteClientTab(quoteId: widget.quoteId),
                ViewQuoteDetailsTab(quoteId: widget.quoteId),
                ViewQuoteConditionsTab(quoteId: widget.quoteId),
                ViewQuoteSummaryTab(
                  quoteId: widget.quoteId,
                  onNavigateToTab: (index) => _tabController.animateTo(index),
                ),
              ],
            ),
      floatingActionButton: state.quote?.status == QuoteStatus.finalized.dbValue
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: FloatingActionButton(
                onPressed: () async {
                  await context.push(
                    '/quotes/edit/${widget.quoteId}?tab=${_tabController.index}',
                  );
                  // Al volver, refrescamos el proveedor de visualización para obtener los datos actualizados
                  ref.invalidate(viewQuoteProvider(widget.quoteId));
                  // Y disparamos la validación de inventario inmediatamente
                  ref
                      .read(quoteValidationProvider(widget.quoteId).notifier)
                      .validate();
                },
                child: const Icon(Icons.edit_outlined),
              ),
            ),
    );
  }

  Future<QuoteStatus?> _showStatusDialog(QuoteStatus currentStatus) async {
    final colors = Theme.of(context).colorScheme;

    final selectedStatus = await CustomDialog.show<QuoteStatus>(
      context: context,
      dialog: CustomDialog.vertical(
        icon: Symbols.conversion_path,
        title: 'Cambiar estatus',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: QuoteStatus.values
              .where((status) => status != QuoteStatus.expired)
              .map((status) {
                final isSelected = status == currentStatus;
                return ListTile(
                  leading: Image.asset(status.iconPath, width: 24, height: 24),
                  title: Text(
                    status.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? colors.primary : colors.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: colors.primary, size: 20)
                      : null,
                  onTap: () =>
                      Navigator.of(context, rootNavigator: true).pop(status),
                );
              })
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selectedStatus == QuoteStatus.finalized) {
      if (!mounted) return null;
      final confirmFinalize = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.confirmation(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.amber.shade800,
          title: 'Finalizar Cotización',
          contentText:
              '¿Estás seguro de que deseas finalizar esta cotización? Una vez finalizada, la cotización quedará cerrada permanentemente y no se podrá editar, enviar ni cambiar de estado.',
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(true),
              child: const Text('Confirmar y Finalizar'),
            ),
          ],
        ),
      );

      if (confirmFinalize != true) return null;
    }

    return selectedStatus;
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

    final isSendDisabled = currentQuote.status == QuoteStatus.approved.dbValue ||
        currentQuote.status == QuoteStatus.rejected.dbValue ||
        currentQuote.status == QuoteStatus.cancelled.dbValue ||
        currentQuote.status == QuoteStatus.finalized.dbValue;

    if (isSendDisabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La cotización está ${QuoteStatus.fromDbValue(currentQuote.status).label.toLowerCase()} y no se puede enviar.',
          ),
        ),
      );
      return;
    }

    _checkDateAndSend(
      context: context,
      quote: currentQuote,
      onSend: (targetQuote) {
        CustomActionSheet.show(
          context: context,
          title: currentIsSentOrResent ? 'Reenviar cotización' : 'Enviar cotización',
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar fecha: $e')),
          );
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
        final freshQuote =
            await ref.read(quotesRepositoryProvider).getQuoteWithDetails(quote.id);
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
