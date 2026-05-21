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
import '../../../domain/models/quote_model.dart';
import '../../../domain/repositories/quotes_repository.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/core/pdf/templates/quote_pdf_template.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:pdf/pdf.dart';
import '../../../../../shared/utils/string_utils.dart';
import '../widgets/send_email_bottom_sheet.dart';
import '../widgets/send_whatsapp_bottom_sheet.dart';

class ViewQuoteScreen extends ConsumerStatefulWidget {
  final String quoteId;
  const ViewQuoteScreen({super.key, required this.quoteId});

  @override
  ConsumerState<ViewQuoteScreen> createState() => _ViewQuoteScreenState();
}

class _ViewQuoteScreenState extends ConsumerState<ViewQuoteScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(viewQuoteProvider(widget.quoteId));

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Cotización',
        subtitle: state.clientName != null
            ? '#${state.currentQuoteNumber} (${state.clientName})'
            : (state.currentQuoteNumber ?? 'Cargando...'),
        actions: [
          IconButton(
            onPressed: () async {
              if (state.quote == null) return;

              CustomActionSheet.show(
                context: context,
                title: 'Enviar cotización',
                actions: [
                  BottomSheetActionItem(
                    icon: Icons.email_outlined,
                    label: 'Enviar por correo electrónico',
                    onTap: () {
                      Navigator.of(context).pop();
                      SendEmailBottomSheet.show(context, state.quote!);
                    },
                  ),
                  BottomSheetActionItem(
                    icon: 'assets/icons/whatsapp_icon.png',
                    label: 'Enviar por WhatsApp',
                    onTap: () {
                      Navigator.of(context).pop();
                      SendWhatsAppBottomSheet.show(context, state.quote!);
                    },
                  ),
                ],
              );
            },
            icon: Icon(Icons.send, color: colors.onSurfaceVariant),
          ),
          IconButton(
            onPressed: () {
              CustomActionSheet.show(
                context: context,
                title: 'Opciones',
                actions: [
                  BottomSheetActionItem(
                    icon: Symbols.conversion_path,
                    label: 'Cambiar estatus',
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

                          if (!context.mounted) return;

                          // Refresh view provider
                          ref.invalidate(viewQuoteProvider(widget.quoteId));

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
                                  onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
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
                  ),
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
                  BottomSheetActionItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Realizar pedido',
                    onTap: () {
                      context.pop();
                    },
                  ),
                  BottomSheetActionItem(
                    icon: Icons.receipt_outlined,
                    label: 'Generar nota de entrega',
                    onTap: () {
                      context.pop();
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
      floatingActionButton: Padding(
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

    return CustomDialog.show<QuoteStatus>(
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
        status == QuoteStatus.inReview;

    if (!isPending) return false;

    final expirationDate = state.dateIssued.add(
      Duration(days: state.validityDays),
    );
    return expirationDate.isBefore(DateTime.now());
  }
}
