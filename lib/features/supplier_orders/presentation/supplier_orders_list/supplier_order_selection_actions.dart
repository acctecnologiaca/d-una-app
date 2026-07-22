import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';

import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/bottom_sheet_action_item.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/features/supplier_orders/domain/models/supplier_order.dart';
import 'package:d_una_app/features/supplier_orders/domain/models/supplier_order_status.dart';
import 'package:d_una_app/features/supplier_orders/presentation/view_supplier_order/widgets/finalize_supplier_order_sheet.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_selection_provider.dart';
import 'package:d_una_app/features/supplier_orders/presentation/create_supplier_order/providers/create_supplier_order_provider.dart';
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart' show StockStatus;
import 'package:d_una_app/core/pdf/templates/supplier_order_pdf_template.dart';

class SupplierOrderSelectionActions {
  SupplierOrderSelectionActions._();

  static List<SupplierOrder> _getAllOrders(WidgetRef ref) {
    final listOrders =
        ref.read(paginatedSupplierOrdersProvider).valueOrNull?.items ?? [];
    final searchOrders =
        ref.read(paginatedSupplierOrderSearchProvider).valueOrNull?.items ?? [];
    final map = <String, SupplierOrder>{};
    for (final o in listOrders) {
      map[o.id] = o;
    }
    for (final o in searchOrders) {
      map[o.id] = o;
    }
    return map.values.toList();
  }

  static void showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    SupplierOrderSelectionState selection,
  ) {
    if (selection.isSingle) {
      final allOrders = _getAllOrders(ref);
      final order = allOrders.firstWhere(
        (o) => o.id == selection.selectedIds.first,
      );
      _showSingleActionsSheet(context, ref, selection, order);
    } else {
      _showMultiActionsSheet(context, ref, selection);
    }
  }

  static void _showSingleActionsSheet(
    BuildContext context,
    WidgetRef ref,
    SupplierOrderSelectionState selection,
    SupplierOrder order,
  ) {
    final isDraft = order.status == SupplierOrderStatus.draft;
    final isSentOrResent =
        order.status == SupplierOrderStatus.sent ||
        order.status == SupplierOrderStatus.resent;
    final canEdit =
        order.status != SupplierOrderStatus.finalized &&
        order.status != SupplierOrderStatus.cancelled;

    CustomActionSheet.show(
      context: context,
      title: '${order.orderNumber} (${order.supplierName})',
      actions: [
        if (canEdit) ...[
          BottomSheetActionItem(
            icon: Icons.edit_outlined,
            label: 'Modificar',
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(supplierOrderSelectionProvider.notifier)
                  .clearSelection();
              ref
                  .read(createSupplierOrderProvider.notifier)
                  .loadFromExisting(order, []);
              context.push('/supplier-orders/edit/${order.id}');
            },
          ),
          BottomSheetActionItem(
            icon: isDraft ? Icons.send : Symbols.forward,
            label: isDraft ? 'Enviar' : 'Reenviar',
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(supplierOrderSelectionProvider.notifier)
                  .clearSelection();
              context.push(
                '/supplier-orders/view/${order.id}?triggerSend=true',
              );
            },
          ),
          if (isSentOrResent)
            BottomSheetActionItem(
              icon: Icons.check_circle_outline,
              label: 'Finalizar',
              onTap: () async {
                Navigator.pop(context);
                ref
                    .read(supplierOrderSelectionProvider.notifier)
                    .clearSelection();
                _finalizeOrderFlow(context, ref, order);
              },
            ),

          BottomSheetActionItem(
            icon: Icons.cancel_outlined,
            label: 'Cancelar',
            onTap: () async {
              Navigator.pop(context);
              final confirm = await CustomDialog.show<bool>(
                context: context,
                dialog: CustomDialog.destructive(
                  title: '¿Cancelar orden de compra?',
                  contentText:
                      'La orden pasará a estatus Cancelada y no podrá modificarse.',
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Volver'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref
                    .read(paginatedSupplierOrdersProvider.notifier)
                    .updateSupplierOrderStatus(
                      order.id,
                      SupplierOrderStatus.cancelled.dbValue,
                    );
                ref
                    .read(supplierOrderSelectionProvider.notifier)
                    .clearSelection();
              }
            },
          ),
        ],
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Icons.content_copy_outlined,
          label: 'Crear una copia',
          onTap: () async {
            Navigator.pop(context);
            ref.read(supplierOrderSelectionProvider.notifier).clearSelection();
            await ref
                .read(createSupplierOrderProvider.notifier)
                .loadSupplierOrderAsCopy(order.id);
            if (context.mounted) {
              context.push('/supplier-orders/create');
            }
          },
        ),
        BottomSheetActionItem(
          icon: order.isArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
          label: order.isArchived ? 'Desarchivar' : 'Archivar',
          onTap: () async {
            Navigator.pop(context);
            await ref
                .read(paginatedSupplierOrdersProvider.notifier)
                .archiveSupplierOrder(order.id, archive: !order.isArchived);
            ref.read(supplierOrderSelectionProvider.notifier).clearSelection();
          },
        ),
      ],
    );
  }

  static void _showMultiActionsSheet(
    BuildContext context,
    WidgetRef ref,
    SupplierOrderSelectionState selection,
  ) {
    final allOrders = _getAllOrders(ref);
    final selectedOrders = allOrders
        .where((o) => selection.selectedIds.contains(o.id))
        .toList();

    // Validar si todos son borradores, enviados o reenviados para permitir cancelar masivamente
    final canCancelAll = selectedOrders.every(
      (o) =>
          o.status == SupplierOrderStatus.draft ||
          o.status == SupplierOrderStatus.sent ||
          o.status == SupplierOrderStatus.resent,
    );

    final isAllArchived = selectedOrders.isNotEmpty &&
        selectedOrders.every((o) => o.isArchived);

    CustomActionSheet.show(
      context: context,
      title: '${selection.count} seleccionados',
      actions: [
        if (canCancelAll)
          BottomSheetActionItem(
            icon: Icons.cancel_outlined,
            label: 'Cancelar',
            onTap: () {
              Navigator.pop(context);
              _handleBatchCancel(context, ref, selection);
            },
          ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: isAllArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
          label: isAllArchived ? 'Desarchivar' : 'Archivar',
          onTap: () async {
            Navigator.pop(context);
            await handleBatchArchive(context, ref, selection, archive: !isAllArchived);
          },
        ),
      ],
    );
  }

  static Future<void> handleBatchArchive(
    BuildContext context,
    WidgetRef ref,
    SupplierOrderSelectionState selection, {
    bool archive = true,
  }) async {
    await ref
        .read(paginatedSupplierOrdersProvider.notifier)
        .batchArchiveSupplierOrders(
          selection.selectedIds.toList(),
          archive: archive,
        );
    ref.invalidate(paginatedSupplierOrderSearchProvider);
    ref.read(supplierOrderSelectionProvider.notifier).clearSelection();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            archive
                ? 'Órdenes de compra archivadas.'
                : 'Órdenes de compra desarchivadas.',
          ),
        ),
      );
    }
  }

  static Future<void> handleBatchSend(
    BuildContext context,
    WidgetRef ref,
    SupplierOrderSelectionState selection,
  ) async {
    final allOrders = _getAllOrders(ref);
    final selectedOrders = allOrders
        .where((o) => selection.selectedIds.contains(o.id))
        .toList();

    final ordersWithAlerts = selectedOrders.where(
      (o) => o.canShowAlerts && (o.hasPriceIncrease || o.stockStatus != StockStatus.available),
    ).toList();

    if (ordersWithAlerts.isNotEmpty) {
      final isSingle = selectedOrders.length == 1;
      final numbers = ordersWithAlerts
          .map((o) => '${o.orderNumber} (${o.supplierName})')
          .join('\n• ');

      CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          title: isSingle
              ? (selectedOrders.first.status == SupplierOrderStatus.draft
                  ? 'No se puede enviar la orden'
                  : 'No se puede reenviar la orden')
              : 'Envío bloqueado por alertas',
          icon: Symbols.warning,
          iconColor: Colors.amber.shade800,
          contentWidget: Text(
            isSingle
                ? (selectedOrders.first.status == SupplierOrderStatus.draft
                    ? 'Esta orden de compra contiene productos con alza de costo o problemas de stock. Debes resolver las alertas antes de enviarla al proveedor.'
                    : 'Esta orden de compra contiene productos con alza de costo o problemas de stock. No es posible reenviarla mientras las alertas persistan.')
                : 'Las siguientes órdenes de compra contienen productos con alza de costo o problemas de stock y no pueden ser enviadas:\n\n• $numbers\n\nPor favor resuelve las alertas antes de proceder.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final isSingleResend =
        selectedOrders.length == 1 &&
        (selectedOrders.first.status == SupplierOrderStatus.sent ||
            selectedOrders.first.status == SupplierOrderStatus.resent);

    // Confirmación mediante lista de números
    final numbers = selectedOrders
        .map((o) => '${o.orderNumber} (${o.supplierName})')
        .join('\n');
    final confirm = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.confirmation(
        title: isSingleResend
            ? '¿Reenviar orden de compra?'
            : '¿Enviar órdenes de compra?',
        icon: isSingleResend ? Symbols.forward : Symbols.send,
        contentText: isSingleResend
            ? '¿Estás seguro de que deseas reenviar la siguiente orden de compra?\n\n$numbers'
            : '¿Estás seguro de que deseas enviar las siguientes órdenes de compra?\n\n$numbers',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isSingleResend ? 'Reenviar' : 'Enviar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final messenger = ScaffoldMessenger.of(context);
      try {
        final profile = ref.read(userProfileProvider).value;
        final userEmail = Supabase.instance.client.auth.currentUser?.email;

        if (profile == null) throw Exception('No se pudo cargar el perfil.');

        for (final order in selectedOrders) {
          // Obtener los detalles y contacto de la sucursal
          final details = await ref
              .read(supplierOrdersRepositoryProvider)
              .getSupplierOrderDetails(order.id);
          final contact = await ref.read(
            supplierBranchContactInfoProvider(
              order.supplierBranchId ?? '',
            ).future,
          );
          final email = contact?['email'] as String?;

          if (email != null && email.trim().isNotEmpty) {
            final pdfBytes = await SupplierOrderPdfTemplate(
              order: order,
              items: details.items,
              userProfile: profile,
              userEmail: userEmail,
            ).generate(PdfPageFormat.a4);

            final base64Pdf = base64Encode(pdfBytes);
            final userName =
                '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();

            await Supabase.instance.client.functions.invoke(
              'send_document_email',
              body: {
                'documentBase64': base64Pdf,
                'fileName': 'Orden_${order.orderNumber}.pdf',
                'documentType': 'supplier_order',
                'recipientEmails': [email.trim()],
                'userContext': {
                  'name': userName.isEmpty ? 'Usuario' : userName,
                  'companyName': profile.companyName,
                  'phone': profile.phone,
                  'replyToEmail': userEmail,
                  'companyLogo': profile.companyLogoUrl,
                },
                'emailContent': {
                  'subject':
                      'Orden de Compra #${order.orderNumber} - ${profile.companyName ?? ''}',
                  'bodyHtml':
                      '<p>Estimado Proveedor,</p><p>Le adjuntamos la Orden de Compra #${order.orderNumber}.</p>',
                },
              },
            );

            final nextStatus = order.status == SupplierOrderStatus.draft
                ? SupplierOrderStatus.sent
                : SupplierOrderStatus.resent;

            await ref
                .read(paginatedSupplierOrdersProvider.notifier)
                .updateSupplierOrderStatus(order.id, nextStatus.dbValue);
          }
        }

        if (context.mounted) Navigator.pop(context); // Dismiss loading

        ref.invalidate(paginatedSupplierOrderSearchProvider);
        ref.read(supplierOrderSelectionProvider.notifier).clearSelection();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Órdenes enviadas por correo con éxito.'),
          ),
        );
      } catch (e) {
        if (context.mounted) Navigator.pop(context); // Dismiss loading
        messenger.showSnackBar(
          SnackBar(content: Text('Error al enviar órdenes: $e')),
        );
      }
    }
  }

  static Future<void> _handleBatchCancel(
    BuildContext context,
    WidgetRef ref,
    SupplierOrderSelectionState selection,
  ) async {
    final confirm = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.destructive(
        title: '¿Cancelar órdenes de compra?',
        contentText:
            'Las órdenes seleccionadas pasarán a estatus Canceladas y no podrán modificarse.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(paginatedSupplierOrdersProvider.notifier)
          .batchUpdateSupplierOrderStatus(
            selection.selectedIds.toList(),
            SupplierOrderStatus.cancelled.dbValue,
          );
      ref.invalidate(paginatedSupplierOrderSearchProvider);
      ref.read(supplierOrderSelectionProvider.notifier).clearSelection();
    }
  }

  static Future<void> _finalizeOrderFlow(
    BuildContext context,
    WidgetRef ref,
    SupplierOrder order,
  ) async {
    final hasAlerts = order.canShowAlerts &&
        (order.hasPriceIncrease || order.stockStatus != StockStatus.available);

    if (hasAlerts) {
      CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          title: 'No se puede finalizar la orden',
          icon: Symbols.warning,
          iconColor: Colors.amber.shade800,
          contentWidget: Text(
            'Esta orden de compra contiene productos con alza de costo o problemas de disponibilidad de stock. No es posible finalizarla mientras las alertas persistan.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FinalizeSupplierOrderSheet(orderId: order.id),
    );

    if (result != null && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await ref
            .read(paginatedSupplierOrdersProvider.notifier)
            .finalizeSupplierOrder(
              orderId: order.id,
              photoFile: result['photoFile'],
              documentType: result['documentType'] as String,
              documentNumber: result['documentNumber'] as String,
              createPurchaseRecord: result['createPurchaseRecord'] as bool,
            );
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        if (context.mounted) Navigator.pop(context);
      }
    }
  }
}
