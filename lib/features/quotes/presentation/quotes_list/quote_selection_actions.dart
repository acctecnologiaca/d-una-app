import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../../shared/utils/string_utils.dart';
import '../../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../../core/pdf/templates/quote_pdf_template.dart';

import '../../domain/models/quote_model.dart';
import '../../data/models/quote.dart' as data;
import '../../data/models/quote_item_product.dart';
import 'providers/quotes_provider.dart';
import '../create_quote/providers/create_quote_provider.dart';
import '../view_quote/providers/view_quote_provider.dart';
import '../view_quote/widgets/select_oc_suppliers_sheet.dart';
import '../../../supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import 'package:intl/intl.dart';

/// Shared action methods for quote multi-selection, used in both
/// QuotesListScreen and QuotesSearchScreen.
class QuoteSelectionActions {
  QuoteSelectionActions._();

  static void showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
    List<Quote> allQuotes,
  ) {
    if (selection.isSingle) {
      final quote = allQuotes.firstWhere(
        (q) => q.id == selection.selectedIds.first,
      );
      _showSingleActionsSheet(context, ref, selection, quote);
    } else {
      _showMultiActionsSheet(context, ref, selection, allQuotes);
    }
  }

  static void _showSingleActionsSheet(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
    Quote quote,
  ) {
    final isFinalized = quote.status == QuoteStatus.finalized;
    final isBlockedForOcNe =
        quote.status == QuoteStatus.rejected ||
        quote.status == QuoteStatus.finalized ||
        quote.status == QuoteStatus.cancelled;
    final hasAlerts =
        quote.canShowAlerts &&
        (quote.hasPriceIncrease || quote.stockStatus != StockStatus.available);

    CustomActionSheet.show(
      context: context,
      title: '${quote.quoteNumber} (${quote.clientName})',
      actions: [
        BottomSheetActionItem(
          icon: Icons.edit_outlined,
          label: 'Modificar',
          enabled: !isFinalized,
          subtitle: isFinalized
              ? 'Cotización finalizada. No se puede editar'
              : null,
          onTap: () {
            context.pop();
            ref.read(quoteSelectionProvider.notifier).clearSelection();
            context.push('/quotes/edit/${quote.id}');
          },
        ),
        (() {
          final isSentOrResent =
              quote.status == QuoteStatus.sent ||
              quote.status == QuoteStatus.resent ||
              quote.status == QuoteStatus.opened ||
              quote.status == QuoteStatus.inReview;
          return BottomSheetActionItem(
            icon: isSentOrResent ? Symbols.forward : Icons.send,
            label: isSentOrResent ? 'Reenviar' : 'Enviar',
            enabled: !isFinalized,
            subtitle: isFinalized
                ? 'Cotización finalizada. No se puede enviar'
                : null,
            onTap: () {
              context.pop();
              _checkDateAndSendFromSelection(context, ref, quote);
            },
          );
        })(),

        BottomSheetActionItem(
          icon: Icons.picture_as_pdf_outlined,
          label: 'Descargar PDF',
          onTap: () async {
            context.pop();

            final userProfile = ref.read(userProfileProvider).value;
            final userEmail = Supabase.instance.client.auth.currentUser?.email;

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

            // Mostramos feedback de carga
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Preparando documento...'),
                duration: Duration(seconds: 1),
              ),
            );

            try {
              // Cargamos la cotización completa con sus detalles
              final fullQuote = await ref
                  .read(quotesRepositoryProvider)
                  .getQuoteWithDetails(quote.id);

              if (context.mounted) {
                context.push(
                  '/pdf-preview',
                  extra: {
                    'title': 'Previsualizar Cotización',
                    'subtitle':
                        ' ${fullQuote.quoteNumber} (${fullQuote.clientName})',
                    'fileName': StringUtils.sanitizeForFileName(
                      '${fullQuote.dateIssued.toIso8601String().substring(0, 10)}_${fullQuote.clientName ?? ''}_${fullQuote.quoteNumber ?? fullQuote.id}_${fullQuote.quoteTag ?? ''}.pdf',
                    ),
                    'buildPdf': (PdfPageFormat format) => QuotePdfTemplate(
                      quote: fullQuote,
                      products: fullQuote.products ?? [],
                      services: fullQuote.services ?? [],
                      conditions: fullQuote.conditions ?? [],
                      userProfile: userProfile,
                      userEmail: userEmail,
                    ).generate(format),
                  },
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al cargar detalles de cotización: $e'),
                  ),
                );
              }
            }
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus',
          enabled: !isFinalized,
          subtitle: isFinalized
              ? 'Cotización finalizada. No se puede cambiar de estado'
              : null,
          onTap: () {
            context.pop();
            showStatusDialog(context, ref, selection);
          },
        ),
        FutureBuilder<data.Quote>(
          future: ref
              .read(quotesRepositoryProvider)
              .getQuoteWithDetails(quote.id),
          builder: (context, snapshot) {
            final fullQuote = snapshot.data;
            final hasAffiliatedProducts =
                fullQuote?.products?.any(
                  (p) =>
                      p.sourceType == QuoteItemSourceType.affiliated ||
                      p.supplierBranchStockId != null,
                ) ??
                true;

            final isDoneLoading =
                snapshot.connectionState != ConnectionState.waiting;

            final isOcEnabled =
                !isBlockedForOcNe &&
                (!isDoneLoading || hasAffiliatedProducts) &&
                !hasAlerts;

            String? ocSubtitle;
            if (isBlockedForOcNe) {
              ocSubtitle =
                  'No disponible para cotizaciones rechazadas, finalizadas o canceladas';
            } else if (hasAlerts) {
              ocSubtitle =
                  'Bloqueado: La cotización contiene productos con alza de costo o stock insuficiente. Resuelve las alertas antes de generar la OC';
            } else if (isDoneLoading && !hasAffiliatedProducts) {
              ocSubtitle =
                  'Esta cotización no contiene productos de proveedores afiliados';
            }

            return BottomSheetActionItem(
              icon: Icons.shopping_cart_outlined,
              label: 'Generar ordenes de compra',
              enabled: isOcEnabled,
              subtitle: ocSubtitle,
              onTap: () async {
                final router = GoRouter.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  final repo = ref.read(supplierOrdersRepositoryProvider);

                  final statuses = await repo.getQuoteSuppliersOcStatus(
                    quote.id,
                  );

                  if (!context.mounted) return;

                  // Close the action sheet
                  Navigator.of(context).pop();

                  final availableSuppliers = statuses
                      .where((s) => !s.hasExistingOc)
                      .toList();

                  if (availableSuppliers.isEmpty && statuses.isNotEmpty) {
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

                  final selectedIds = await SelectOcSuppliersSheet.show(
                    context: context,
                    suppliers: statuses,
                  );

                  if (selectedIds == null || selectedIds.isEmpty) return;

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
                      result['skippedSuppliers'] as List<dynamic>? ?? [];
                  final generatedCount = result['generatedCount'] as int? ?? 0;

                  if (generatedCount > 0) {
                    ref.invalidate(viewQuoteProvider(quote.id));
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

                  final query = quote.quoteNumber;
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
        /* BottomSheetActionItem(
          icon: Icons.receipt_outlined,
          label: 'Generar nota de entrega',
          enabled: !isBlockedForOcNe,
          subtitle: isBlockedForOcNe
              ? 'No disponible para cotizaciones rechazadas, finalizadas o canceladas'
              : null,
          onTap: () {
            context.pop();
            showComingSoon(context, 'Generar nota de entrega');
          },
        ), */
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Icons.content_copy_outlined,
          label: 'Crear una copia',
          onTap: () async {
            context.pop();
            await ref
                .read(createQuoteProvider.notifier)
                .loadQuoteAsCopy(quote.id);
            if (context.mounted) {
              ref.read(quoteSelectionProvider.notifier).clearSelection();
              context.push('/quotes/create');
            }
          },
        ),

        BottomSheetActionItem(
          icon: quote.isArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
          label: quote.isArchived ? 'Desarchivar' : 'Archivar',
          onTap: () async {
            context.pop();
            await ref
                .read(quotesListProvider.notifier)
                .archiveQuote(quote.id, archive: !quote.isArchived);
            ref.read(quoteSelectionProvider.notifier).clearSelection();
          },
        ),
      ],
    );
  }

  static void _showMultiActionsSheet(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
    List<Quote> allQuotes,
  ) {
    final selectedQuotes = allQuotes
        .where((q) => selection.selectedIds.contains(q.id))
        .toList();
    final isAllArchived =
        selectedQuotes.isNotEmpty && selectedQuotes.every((q) => q.isArchived);

    CustomActionSheet.show(
      context: context,
      title: '${selection.count} seleccionados',
      actions: [
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus',
          onTap: () {
            context.pop();
            showStatusDialog(context, ref, selection);
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
            handleBatchArchive(
              context,
              ref,
              selection,
              archive: !isAllArchived,
            );
          },
        ),
      ],
    );
  }

  static Future<void> showStatusDialog(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
  ) async {
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
                return ListTile(
                  leading: Image.asset(status.iconPath, width: 24, height: 24),
                  title: Text(status.label),
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

    if (!context.mounted) return;

    if (selectedStatus == QuoteStatus.finalized) {
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

      if (confirmFinalize != true) return;
    }

    if (selectedStatus != null) {
      final result = await ref
          .read(quotesListProvider.notifier)
          .batchUpdateStatus(
            selection.selectedIds.toList(),
            selectedStatus.dbValue,
          );

      ref.read(quoteSelectionProvider.notifier).clearSelection();
      refreshAllQuoteProviders(ref);

      if (!context.mounted) return;

      if (result.hasErrors) {
        final List<String> allMissingProducts = [];
        for (var error in result.stockErrors.values) {
          allMissingProducts.addAll(error.productNames);
        }

        final uniqueMissingProducts = allMissingProducts.toSet().toList();

        String contentText =
            'Se actualizaron ${result.successfulIds.length} cotizaciones.\n\nSin embargo, ${result.stockErrors.length} fallaron debido a stock insuficiente en el inventario propio para los siguientes productos:\n\n${uniqueMissingProducts.map((name) => '• $name').join('\n')}\n\nPor favor, agregue más stock para poder aprobarlas.';

        if (result.generalErrors.isNotEmpty) {
          contentText +=
              '\n\nAdemás, hubo ${result.generalErrors.length} errores generales adicionales.';
        }

        CustomDialog.show(
          context: context,
          dialog: CustomDialog.confirmation(
            icon: Symbols.warning,
            iconColor: Colors.amber.shade800,
            title: 'Actualización Parcial',
            contentText: contentText,
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estatus cambiado a "${selectedStatus.label}" en ${result.successfulIds.length} cotizaciones.',
            ),
          ),
        );
      }
    }
  }

  static Future<void> handleBatchArchive(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection, {
    bool archive = true,
  }) async {
    await ref
        .read(quotesListProvider.notifier)
        .batchArchive(selection.selectedIds.toList(), archive: archive);
    ref.read(quoteSelectionProvider.notifier).clearSelection();
    if (context.mounted) {
      final statusWord = archive ? 'archivada' : 'desarchivada';
      final statusWordPlural = archive ? 'archivadas' : 'desarchivadas';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selection.count} cotización${selection.count > 1 ? 'es' : ''} ${selection.count > 1 ? statusWordPlural : statusWord}',
          ),
        ),
      );
    }
  }

  static void showComingSoon(BuildContext context, String action) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$action — Próximamente')));
  }

  static Future<void> _checkDateAndSendFromSelection(
    BuildContext context,
    WidgetRef ref,
    Quote quote,
  ) async {
    if (quote.status == QuoteStatus.finalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cotización está finalizada y no se puede enviar.'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final issueDate = quote.date;
    final isSameDate =
        issueDate.year == now.year &&
        issueDate.month == now.month &&
        issueDate.day == now.day;

    void onProceedSend(Quote targetQuote) {
      ref.read(quoteSelectionProvider.notifier).clearSelection();
      context.push(
        '/quotes/view/${targetQuote.id}',
        extra: {'triggerSend': true},
      );
    }

    if (isSameDate) {
      onProceedSend(quote);
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
      onProceedSend(quote);
    } else if (action == 'update_date') {
      try {
        await ref
            .read(quotesListProvider.notifier)
            .updateQuoteDate(quote.id, DateTime.now());
        ref.invalidate(viewQuoteProvider(quote.id));
        final updatedQuote = quote.copyWith(date: DateTime.now());
        onProceedSend(updatedQuote);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar fecha: $e')),
          );
        }
      }
    } else if (action == 'modify') {
      if (context.mounted) {
        ref.read(quoteSelectionProvider.notifier).clearSelection();
        await context.push('/quotes/edit/${quote.id}?tab=3');
        ref.invalidate(quotesListProvider);
        ref.invalidate(viewQuoteProvider(quote.id));
      }
    }
  }
}
