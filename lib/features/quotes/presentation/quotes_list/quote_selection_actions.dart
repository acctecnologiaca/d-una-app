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
import 'providers/quotes_provider.dart';
import '../create_quote/providers/create_quote_provider.dart';
import '../../../supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';

/// Shared action methods for quote multi-selection, used in both
/// QuotesListScreen and QuotesSearchScreen.
class QuoteSelectionActions {
  QuoteSelectionActions._();

  static void showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
  ) {
    if (selection.isSingle) {
      final allQuotes = ref.read(quotesListProvider).value ?? [];
      final quote = allQuotes.firstWhere(
        (q) => q.id == selection.selectedIds.first,
      );
      _showSingleActionsSheet(context, ref, selection, quote);
    } else {
      _showMultiActionsSheet(context, ref, selection);
    }
  }

  static void _showSingleActionsSheet(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
    Quote quote,
  ) {
    CustomActionSheet.show(
      context: context,
      title: '${quote.clientName}\n#${quote.quoteNumber}',
      actions: [
        BottomSheetActionItem(
          icon: Icons.send,
          label: 'Enviar',
          onTap: () {
            context.pop();
            showComingSoon(context, 'Enviar');
          },
        ),
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus',
          onTap: () {
            context.pop();
            showStatusDialog(context, ref, selection);
          },
        ),
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
          icon: Icons.shopping_cart_outlined,
          label: 'Generar orden de compra',
          onTap: () async {
            context.pop();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Generando órdenes de compra...'),
                duration: Duration(seconds: 1),
              ),
            );

            try {
              final repo = ref.read(supplierOrdersRepositoryProvider);
              final result = await repo.batchGenerateFromQuote(quote.id);
              
              if (!context.mounted) return;

              final skipped = result['skippedSuppliers'] as List<dynamic>? ?? [];
              final generatedCount = result['generatedCount'] as int? ?? 0;

              if (skipped.isNotEmpty) {
                // Show warning dialog about skipped suppliers
                await CustomDialog.show(
                  context: context,
                  dialog: CustomDialog.confirmation(
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.amber.shade800,
                    title: 'Órdenes Generadas con Advertencias',
                    contentText: 'Se generaron $generatedCount órdenes de compra.\n\nNo se pudieron generar órdenes para los siguientes proveedores porque no están registrados en la tabla de proveedores:\n\n${skipped.map((s) => '• $s').join('\n')}',
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Se generaron $generatedCount órdenes de compra exitosamente.'),
                  ),
                );
              }

              // Navigate to supplier orders list
              if (context.mounted) {
                context.push('/supplier-orders');
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al generar órdenes: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.receipt_outlined,
          label: 'Generar nota de entrega',
          onTap: () {
            context.pop();
            showComingSoon(context, 'Generar nota de entrega');
          },
        ),
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
          icon: Icons.edit_outlined,
          label: 'Modificar',
          onTap: () {
            context.pop();
            ref.read(quoteSelectionProvider.notifier).clearSelection();
            context.push('/quotes/edit/${quote.id}');
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
  ) {
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
          icon: Icons.archive_outlined,
          label: 'Archivar',
          onTap: () async {
            context.pop();
            handleBatchArchive(context, ref, selection);
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

    if (selectedStatus != null) {
      final result = await ref
          .read(quotesListProvider.notifier)
          .batchUpdateStatus(
            selection.selectedIds.toList(),
            selectedStatus.dbValue,
          );

      ref.read(quoteSelectionProvider.notifier).clearSelection();

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
    QuoteSelectionState selection,
  ) async {
    await ref
        .read(quotesListProvider.notifier)
        .batchArchive(selection.selectedIds.toList(), archive: true);
    ref.read(quoteSelectionProvider.notifier).clearSelection();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selection.count} cotización${selection.count > 1 ? 'es' : ''} archivada${selection.count > 1 ? 's' : ''}',
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
}
