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
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart'
    show StockStatus;
import 'package:d_una_app/core/pdf/pdf_helpers.dart';
import 'package:d_una_app/core/pdf/templates/supplier_order_pdf_template.dart';
import 'package:d_una_app/features/settings/data/models/shipping_method.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/widgets/merge_supplier_orders_sheet.dart';
import 'package:d_una_app/features/collaborators/domain/models/collaborator.dart';
import 'package:d_una_app/features/supplier_orders/domain/utils/oc_email_template_builder.dart';

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
    final canEdit = order.status.canEdit;

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
          if (order.status == SupplierOrderStatus.approved)
            BottomSheetActionItem(
              icon: Icons.receipt_long_outlined,
              label: 'Registrar compra',
              onTap: () async {
                final parentContext = context;
                Navigator.pop(context);
                ref
                    .read(supplierOrderSelectionProvider.notifier)
                    .clearSelection();
                _finalizeOrderFlow(parentContext, ref, order);
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

        if (order.status == SupplierOrderStatus.merged)
          BottomSheetActionItem(
            icon: Icons.call_split_rounded,
            label: 'Deshacer Consolidación',
            onTap: () {
              Navigator.pop(context);
              _handleUnmergeOrder(context, ref, [order.id]);
            },
          ),
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

    final canMerge =
        selectedOrders.length >= 2 &&
        selectedOrders.every((o) => o.status.canEdit);

    final canUnmergeAll =
        selectedOrders.isNotEmpty &&
        selectedOrders.every((o) => o.status == SupplierOrderStatus.merged);

    final firstSupplierId = selectedOrders.isNotEmpty
        ? selectedOrders.first.supplierId
        : null;
    final isSameSupplier =
        selectedOrders.isNotEmpty &&
        selectedOrders.every((o) => o.supplierId == firstSupplierId);

    final isAllArchived =
        selectedOrders.isNotEmpty && selectedOrders.every((o) => o.isArchived);

    CustomActionSheet.show(
      context: context,
      title: '${selection.count} seleccionados',
      actions: [
        if (canMerge)
          BottomSheetActionItem(
            icon: Icons.merge_type_rounded,
            label: 'Consolidar órdenes de compra',
            enabled: isSameSupplier,
            subtitle: !isSameSupplier
                ? 'Solo se pueden consolidar órdenes del mismo proveedor'
                : null,
            onTap: () {
              Navigator.pop(context);
              _handleBatchMerge(context, ref, selectedOrders);
            },
          ),
        if (canUnmergeAll)
          BottomSheetActionItem(
            icon: Icons.call_split_rounded,
            label: 'Deshacer consolidación',
            onTap: () {
              Navigator.pop(context);
              _handleUnmergeOrder(context, ref, selection.selectedIds.toList());
            },
          ),
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
          icon: isAllArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
          label: isAllArchived ? 'Desarchivar' : 'Archivar',
          onTap: () async {
            Navigator.pop(context);
            await handleBatchArchive(
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

  static Future<void> _handleBatchMerge(
    BuildContext context,
    WidgetRef ref,
    List<SupplierOrder> selectedOrders,
  ) async {
    final confirm = await MergeSupplierOrdersSheet.show(
      context: context,
      selectedOrders: selectedOrders,
    );

    if (confirm == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Consolidando órdenes de compra...'),
          duration: Duration(seconds: 1),
        ),
      );

      try {
        final repo = ref.read(supplierOrdersRepositoryProvider);
        final orderIds = selectedOrders.map((o) => o.id).toList();
        final primaryOrder = await repo.mergeSupplierOrders(orderIds);

        ref.read(paginatedSupplierOrdersProvider.notifier).refresh();
        ref.invalidate(paginatedSupplierOrderSearchProvider);
        ref.read(supplierOrderSelectionProvider.notifier).clearSelection();

        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Órdenes consolidadas exitosamente en ${primaryOrder.orderNumber}.',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error al consolidar órdenes: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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

    final ordersWithAlerts = selectedOrders
        .where(
          (o) =>
              o.canShowAlerts &&
              (o.hasPriceIncrease || o.stockStatus != StockStatus.available),
        )
        .toList();

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
            final results = await Future.wait([
              PdfHelpers.fetchShippingMethodById(order.shippingMethodId),
              PdfHelpers.fetchCollaboratorById(order.receiverCollaboratorId),
            ]);
            final shippingMethod = results[0] as ShippingMethod?;
            final receiverCollaborator = results[1] as Collaborator?;

            final pdfBytes = await SupplierOrderPdfTemplate(
              order: order,
              items: details.items,
              userProfile: profile,
              userEmail: userEmail,
              shippingMethod: shippingMethod,
              receiverCollaborator: receiverCollaborator,
            ).generate(PdfPageFormat.a4);

            final base64Pdf = base64Encode(pdfBytes);
            final userName =
                '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();

            final actionToken = await ref
                .read(supplierOrdersRepositoryProvider)
                .generateActionToken(order.id);
            const apiBaseUrl =
                'https://fdkswvzrozijbizdthge.supabase.co/functions';

            final bodyHtml = OcEmailTemplateBuilder.buildHtmlBody(
              order: order,
              items: details.items,
              userProfile: profile,
              userEmail: userEmail ?? '',
              actionToken: actionToken,
              apiBaseUrl: apiBaseUrl,
              shippingMethod: shippingMethod,
              receiverCollaborator: receiverCollaborator,
            );

            await Supabase.instance.client.functions.invoke(
              'send_document_email',
              body: {
                'documentBase64': base64Pdf,
                'fileName': 'Orden_${order.orderNumber}.pdf',
                'documentType': 'supplier_order',
                'documentId': order.id,
                'recipientEmails': [email.trim()],
                'userContext': {
                  'name': userName.isEmpty ? 'Usuario' : userName,
                  'companyName': profile.companyName,
                  'phone': profile.phone,
                  'replyToEmail': userEmail,
                  'companyLogo': profile.companyLogoUrl,
                },
                'emailContent': {
                  'subject': OcEmailTemplateBuilder.buildSubject(
                    order: order,
                    userProfile: profile,
                  ),
                  'bodyHtml': bodyHtml,
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
    final hasAlerts =
        order.canShowAlerts &&
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
      final navigator = Navigator.of(context, rootNavigator: true);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final purchaseId = await ref
            .read(paginatedSupplierOrdersProvider.notifier)
            .finalizeSupplierOrder(
              orderId: order.id,
              photoFile: result['photoFile'],
              documentType: result['documentType'] as String,
              documentNumber: result['documentNumber'] as String,
              createPurchaseRecord: result['createPurchaseRecord'] as bool,
            );

        navigator.pop(); // Dismiss loading
        await Future.delayed(const Duration(milliseconds: 100));

        if (context.mounted &&
            result['createPurchaseRecord'] == true &&
            purchaseId != null) {
          final goToPurchase = await CustomDialog.show<bool>(
            context: context,
            dialog: CustomDialog.confirmation(
              title: 'Compra registrada',
              contentText:
                  'Se ha generado el registro de compra con éxito. '
                  'Recuerda ingresar los números de serie y tiempos de garantía de los productos agregados.',
              actions: [
                TextButton(
                  onPressed: () => navigator.pop(false),
                  child: const Text('Más tarde'),
                ),
                FilledButton(
                  onPressed: () => navigator.pop(true),
                  child: const Text('Ir al registro'),
                ),
              ],
            ),
          );

          ref.invalidate(linkedPurchaseProvider(order.id));

          if (goToPurchase == true && context.mounted) {
            context.push(
              '/my-purchases/view/$purchaseId',
              extra: {'editMode': true},
            );
          }
        }
      } catch (e) {
        navigator.pop();
      }
    }
  }

  static Future<void> _handleUnmergeOrder(
    BuildContext context,
    WidgetRef ref,
    List<String> orderIds,
  ) async {
    final confirm = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.confirmation(
        title: '¿Deshacer consolidación?',
        contentText: orderIds.length == 1
            ? 'La orden seleccionada se desvinculará de la OC Principal y volverá al estado Borrador.'
            : 'Las ${orderIds.length} órdenes seleccionadas se desvincularán de sus OCs Principales y volverán al estado Borrador.',
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Procesando...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      try {
        await ref
            .read(supplierOrdersRepositoryProvider)
            .batchUnmergeSupplierOrders(orderIds);

        ref.read(paginatedSupplierOrdersProvider.notifier).refresh();
        ref.invalidate(paginatedSupplierOrderSearchProvider);
        ref.read(supplierOrderSelectionProvider.notifier).clearSelection();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                orderIds.length == 1
                    ? 'Consolidación deshecha. La orden volvió a Borrador.'
                    : 'Consolidación deshecha. Las ${orderIds.length} órdenes volvieron a Borrador.',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al deshacer consolidación: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
