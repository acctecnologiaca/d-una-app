import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../supplier_orders_list/providers/supplier_orders_providers.dart';
import '../../create_supplier_order/providers/create_supplier_order_provider.dart';
import 'dart:io';
import '../tabs/view_supplier_order_details_tab.dart';
import '../tabs/view_supplier_order_products_tab.dart';
import '../tabs/view_supplier_order_summary_tab.dart';
import '../widgets/finalize_supplier_order_sheet.dart';
import '../../../domain/models/supplier_order_status.dart';
import '../../../domain/models/supplier_order.dart';
import '../../../domain/models/supplier_order_item.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:d_una_app/core/pdf/templates/supplier_order_pdf_template.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:d_una_app/core/utils/contact_utils.dart';
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart' show StockStatus;
import '../../create_supplier_order/providers/supplier_order_validation_provider.dart';

class SupplierOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  final bool triggerSend;

  const SupplierOrderDetailsScreen({
    super.key,
    required this.orderId,
    this.triggerSend = false,
  });

  @override
  ConsumerState<SupplierOrderDetailsScreen> createState() =>
      _SupplierOrderDetailsScreenState();
}

class _SupplierOrderDetailsScreenState
    extends ConsumerState<SupplierOrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasTriggeredSend = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final detailsAsync = ref.watch(supplierOrderDetailProvider(widget.orderId));
    final suppliers = ref.watch(suppliersProvider).valueOrNull ?? [];

    return detailsAsync.when(
      data: (data) {
        final order = data.order;
        final items = data.items;
        final canEdit =
            order.status != SupplierOrderStatus.finalized &&
            order.status != SupplierOrderStatus.cancelled;
        final isSentOrResent =
            order.status == SupplierOrderStatus.sent ||
            order.status == SupplierOrderStatus.resent;

        if (widget.triggerSend && !_hasTriggeredSend) {
          _hasTriggeredSend = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndSendOrder(context, order, items);
          });
        }

        Supplier? matchedSupplier;
        for (final s in suppliers) {
          if (s.id == order.supplierId) {
            matchedSupplier = s;
            break;
          }
        }

        final supplierDisplayName = /*matchedSupplier != null
        ? (matchedSupplier.legalName != null && matchedSupplier.legalName!.isNotEmpty
            ? '${matchedSupplier.name} (${matchedSupplier.legalName})'
            :*/
            matchedSupplier!.name; /*)*/
        /*: 
        order.supplierName;*/

        return Scaffold(
          appBar: StandardAppBar(
            title: 'Orden de compra',
            subtitle: '${order.orderNumber} ($supplierDisplayName)',
            actions: [
              IconButton(
                icon: Icon(isSentOrResent ? Symbols.forward : Icons.send),
                color: canEdit
                    ? colors.onSurfaceVariant
                    : colors.onSurfaceVariant.withValues(alpha: 0.38),
                tooltip: isSentOrResent ? 'Reenviar' : 'Enviar',
                onPressed: canEdit
                    ? () {
                        _checkAndSendOrder(context, order, items);
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                color: colors.onSurfaceVariant,
                onPressed: () {
                  CustomActionSheet.show(
                    context: context,
                    title: 'Opciones',
                    actions: [
                      if (canEdit)
                        BottomSheetActionItem(
                          icon: Icons.edit_outlined,
                          label: 'Modificar',
                          onTap: () {
                            context.pop();
                            ref
                                .read(createSupplierOrderProvider.notifier)
                                .loadFromExisting(order, []);
                            context.push('/supplier-orders/edit/${order.id}');
                          },
                        ),
                      if (isSentOrResent) ...[
                        BottomSheetActionItem(
                          icon: Symbols.forward,
                          label: 'Reenviar',
                          onTap: () {
                            context.pop();
                            _checkAndSendOrder(context, order, items);
                          },
                        ),
                        BottomSheetActionItem(
                          icon: Icons.check_circle_outline,
                          label: 'Finalizar',
                          onTap: () {
                            context.pop();
                            _finalizeOrderFlow(context, order, items);
                          },
                        ),
                      ],
                      if (canEdit)
                        BottomSheetActionItem(
                          icon: Icons.cancel_outlined,
                          label: 'Cancelar',
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            context.pop();
                            final confirm = await CustomDialog.show<bool>(
                              context: context,
                              dialog: CustomDialog.destructive(
                                title: '¿Cancelar orden de compra?',
                                contentText:
                                    'La orden pasará a estatus Cancelada y no podrá modificarse.',
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Volver'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Confirmar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await ref
                                    .read(
                                      paginatedSupplierOrdersProvider.notifier,
                                    )
                                    .updateSupplierOrderStatus(
                                      order.id,
                                      SupplierOrderStatus.cancelled.dbValue,
                                    );

                                ref.invalidate(
                                  supplierOrderDetailProvider(order.id),
                                );

                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Orden de compra cancelada.'),
                                  ),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al cancelar orden: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),

                      const Divider(height: 1, indent: 16, endIndent: 16),
                      BottomSheetActionItem(
                        icon: Icons.content_copy_outlined,
                        label: 'Crear una copia',
                        onTap: () async {
                          final router = GoRouter.of(context);
                          context.pop(); // Close action sheet
                          await ref
                              .read(createSupplierOrderProvider.notifier)
                              .loadSupplierOrderAsCopy(order.id);
                          router.push('/supplier-orders/create');
                        },
                      ),
                      BottomSheetActionItem(
                        icon: order.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                        label: order.isArchived ? 'Desarchivar' : 'Archivar',
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final router = GoRouter.of(context);
                          context.pop(); // Close action sheet

                          await ref
                              .read(paginatedSupplierOrdersProvider.notifier)
                              .archiveSupplierOrder(
                                order.id,
                                archive: !order.isArchived,
                              );

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                order.isArchived
                                    ? 'Orden desarchivada exitosamente'
                                    : 'Orden archivada exitosamente',
                              ),
                            ),
                          );
                          router.pop(); // Return to supplier orders list
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: colors.primary,
              unselectedLabelColor: colors.onSurfaceVariant,
              indicatorColor: colors.primary,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                const Tab(text: 'Detalles'),
                Tab(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final canShowAlerts = order.canShowAlerts;
                      final validationState = ref.watch(
                        supplierOrderValidationProvider(items),
                      );
                      final hasAlerts = canShowAlerts && (
                        order.hasPriceIncrease ||
                        order.stockStatus != StockStatus.available ||
                        validationState.items.values.any((item) => item.statuses.isNotEmpty)
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
                const Tab(text: 'Resumen'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              ViewSupplierOrderDetailsTab(order: order),
              ViewSupplierOrderProductsTab(order: order, items: items),
              ViewSupplierOrderSummaryTab(
                order: order,
                items: items,
                onNavigateToTab: (index) => _tabController.animateTo(index),
              ),
            ],
          ),
          floatingActionButton: canEdit
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Builder(
                    builder: (context) {
                      final showFinalizeFab =
                          order.status == SupplierOrderStatus.sent ||
                          order.status == SupplierOrderStatus.resent;

                      if (showFinalizeFab) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FloatingActionButton(
                              heroTag: 'finalize_order_fab',
                              onPressed: () {
                                _finalizeOrderFlow(context, order, items);
                              },
                              backgroundColor: colors.secondaryContainer,
                              foregroundColor: colors.onSecondaryContainer,
                              tooltip: 'Finalizar orden',
                              child: const Icon(Icons.check_circle_outline),
                            ),
                            const SizedBox(height: 16),
                            FloatingActionButton(
                              heroTag: 'edit_order_fab',
                              onPressed: () {
                                ref
                                    .read(createSupplierOrderProvider.notifier)
                                    .loadFromExisting(order, items);
                                context.push(
                                  '/supplier-orders/edit/${order.id}?tab=${_tabController.index}',
                                );
                              },
                              child: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        );
                      }

                      return FloatingActionButton(
                        heroTag: 'edit_order_fab',
                        onPressed: () {
                          ref
                              .read(createSupplierOrderProvider.notifier)
                              .loadFromExisting(order, items);
                          context.push(
                            '/supplier-orders/edit/${order.id}?tab=${_tabController.index}',
                          );
                        },
                        child: const Icon(Icons.edit_outlined),
                      );
                    },
                  ),
                )
              : null,
        );
      },
      loading: () => const Scaffold(
        appBar: StandardAppBar(
          title: 'Orden de compra',
          subtitle: 'Cargando...',
        ),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        appBar: const StandardAppBar(title: 'Orden de compra'),
        body: Center(child: Text('Error al cargar detalles: $e')),
      ),
    );
  }

  Future<void> _handleSendFlow(
    BuildContext context,
    SupplierOrder order,
    List<SupplierOrderItem> items,
  ) async {
    // Track whether loading dialog is still showing
    var isLoadingShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final branchId = order.supplierBranchId!;
      final branchInfo = await ref.read(
        supplierBranchContactInfoProvider(branchId).future,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      isLoadingShowing = false;

      if (branchInfo == null) {
        CustomDialog.show(
          context: context,
          dialog: CustomDialog.confirmation(
            title: 'Error de envío',
            contentText: 'No se pudo encontrar la información de la sucursal.',
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final email = branchInfo['email'] as String?;
      final phone = branchInfo['phone'] as String?;

      final hasEmail = email != null && email.trim().isNotEmpty;
      final hasPhone = phone != null && phone.trim().isNotEmpty;

      if (!hasEmail) {
        if (hasPhone) {
          CustomDialog.show(
            context: context,
            dialog: CustomDialog.confirmation(
              title: 'Envío no disponible',
              icon: Symbols.warning,
              iconColor: Colors.amber,
              contentWidget: const Text(
                'La sucursal seleccionada no cuenta con un correo electrónico registrado para el envío automático de la orden.\n\n'
                'Puedes ponerte en contacto directamente con el proveedor por WhatsApp para coordinar tu compra.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    final msg =
                        'Hola, le escribo con respecto a la Orden de Compra #${order.orderNumber}.';
                    ContactUtils.launchWhatsApp(phone, message: msg);
                  },
                  icon: Image.asset(
                    'assets/icons/whatsapp_icon.png',
                    width: 22,
                    color: Colors.white,
                  ),
                  label: const Text('Contactar'),
                ),
              ],
            ),
          );
        } else {
          CustomDialog.show(
            context: context,
            dialog: CustomDialog.confirmation(
              title: 'Error de envío',
              contentText:
                  'La sucursal seleccionada no cuenta con correo electrónico ni número de teléfono registrados.',
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

      // Enviar directamente por correo
      _sendViaEmail(context, order, items, email.trim(), phone?.trim());
    } catch (e) {
      if (context.mounted) {
        if (isLoadingShowing) {
          Navigator.pop(context); // Only dismiss loading if it's still showing
        }
        CustomDialog.show(
          context: context,
          dialog: CustomDialog.confirmation(
            title: 'Error',
            contentText:
                'Ocurrió un error al consultar los datos de la sucursal: $e',
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _sendViaEmail(
    BuildContext context,
    SupplierOrder order,
    List<SupplierOrderItem> items,
    String email,
    String? phone,
  ) async {
    var isLoadingShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userProfile = ref.read(userProfileProvider).value;
      final userEmail = Supabase.instance.client.auth.currentUser?.email;

      if (userProfile == null) {
        throw Exception('No se pudo cargar el perfil del usuario.');
      }

      final pdfBytes = await SupplierOrderPdfTemplate(
        order: order,
        items: items,
        userProfile: userProfile,
        userEmail: userEmail,
      ).generate(PdfPageFormat.a4);

      final base64Pdf = base64Encode(pdfBytes);
      final fileName = 'Orden_${order.orderNumber}.pdf';
      final userName =
          '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();

      final response = await Supabase.instance.client.functions.invoke(
        'send_document_email',
        body: {
          'documentBase64': base64Pdf,
          'fileName': fileName,
          'documentType': 'supplier_order',
          'recipientEmails': [email],
          'userContext': {
            'name': userName.isEmpty ? 'Usuario' : userName,
            'companyName': userProfile.companyName,
            'phone': userProfile.phone,
            'replyToEmail': userEmail,
            'companyLogo': userProfile.companyLogoUrl,
          },
          'emailContent': {
            'subject':
                'Orden de Compra #${order.orderNumber} - ${userProfile.companyName ?? ''}',
            'bodyHtml':
                '<p>Estimado Proveedor,</p>'
                '<p>Le adjuntamos la Orden de Compra <b>#${order.orderNumber}</b> emitida por <b>${userProfile.companyName ?? 'nuestra empresa'}</b>.</p>'
                '<p>Quedamos atentos a sus comentarios.</p>'
                '<p>Atentamente,</p>'
                '<p><b>${userName.isEmpty ? 'Usuario' : userName}</b><br>${userProfile.companyName ?? ''}</p>',
          },
        },
      );

      if (!context.mounted) return;

      if (response.status != 200) {
        Navigator.pop(context); // Dismiss loading dialog
        isLoadingShowing = false;
        throw Exception('Error del servidor: ${response.data}');
      }

      Navigator.pop(context); // Dismiss loading dialog
      isLoadingShowing = false;

      final newStatus = order.status == SupplierOrderStatus.draft
          ? SupplierOrderStatus.sent
          : SupplierOrderStatus.resent;

      await ref
          .read(paginatedSupplierOrdersProvider.notifier)
          .updateSupplierOrderStatus(order.id, newStatus.dbValue);

      ref.invalidate(supplierOrderDetailProvider(order.id));

      if (!context.mounted) return;
      _showDisclaimerDialog(context, 'correo electrónico', phone, order);
    } catch (e) {
      if (context.mounted) {
        if (isLoadingShowing) {
          Navigator.pop(context); // Only dismiss loading if it's still showing
        }
        CustomDialog.show(
          context: context,
          dialog: CustomDialog.confirmation(
            title: 'Error al enviar',
            contentText: 'Ocurrió un error al enviar el correo: $e',
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showDisclaimerDialog(
    BuildContext context,
    String methodUsed,
    String? branchPhone,
    SupplierOrder order,
  ) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasPhone = branchPhone != null && branchPhone.trim().isNotEmpty;

    CustomDialog.show(
      context: context,
      barrierDismissible: false,
      dialog: CustomDialog.confirmation(
        title: 'Orden Enviada',
        icon: Symbols.check_circle,
        iconColor: colors.primary,
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'La orden ha sido enviada exitosamente por $methodUsed.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withAlpha(128),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant.withAlpha(128)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Symbols.warning, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta orden no compromete al proveedor a reservar la mercancía, debes finiquitar la compra directamente con un vendedor.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasPhone) ...[
              const SizedBox(height: 16),
              Text(
                'Para finalizar la orden, te recomendamos contactar al proveedor de inmediato.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (hasPhone) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                final msg =
                    'Hola, le escribo con respecto a la Orden de Compra #${order.orderNumber}.';
                ContactUtils.launchWhatsApp(branchPhone, message: msg);
              },
              icon: Image.asset(
                'assets/icons/whatsapp_icon.png',
                width: 22,
                color: Colors.white,
              ),
              label: const Text('Contactar'),
            ),
          ] else
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
        ],
      ),
    );
  }

  bool _hasActiveAlerts(SupplierOrder order, List<SupplierOrderItem> items) {
    if (!order.canShowAlerts) return false;

    final validationState = ref.read(supplierOrderValidationProvider(items));
    final hasValidationAlerts =
        validationState.items.values.any((item) => item.statuses.isNotEmpty);

    return order.hasPriceIncrease ||
        order.stockStatus != StockStatus.available ||
        hasValidationAlerts ||
        items.any((item) => item.hasPriceIncrease || item.isOutOfStock || item.hasLowStock);
  }

  Future<void> _checkAndSendOrder(
    BuildContext context,
    SupplierOrder order,
    List<SupplierOrderItem> items,
  ) async {
    if (_hasActiveAlerts(order, items)) {
      final isResend =
          order.status == SupplierOrderStatus.sent ||
          order.status == SupplierOrderStatus.resent;
      CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          title: isResend
              ? 'No se puede reenviar la orden'
              : 'No se puede enviar la orden',
          icon: Symbols.warning,
          iconColor: Colors.amber.shade800,
          contentWidget: Text(
            isResend
                ? 'Esta orden de compra contiene productos con alza de costo o problemas de disponibilidad de stock. No es posible reenviarla mientras las alertas persistan.'
                : 'Esta orden de compra contiene productos con alza de costo o problemas de disponibilidad de stock. Debes resolver las alertas antes de enviarla al proveedor.',
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

    final suppliers = ref.read(suppliersProvider).valueOrNull ?? [];
    Supplier? matchedSupplier;
    for (final s in suppliers) {
      if (s.id == order.supplierId) {
        matchedSupplier = s;
        break;
      }
    }

    if (matchedSupplier != null && matchedSupplier.minimumPurchaseAmount > 0) {
      if (order.subtotal < matchedSupplier.minimumPurchaseAmount) {
        final diff = matchedSupplier.minimumPurchaseAmount - order.subtotal;
        CustomDialog.show(
          context: context,
          dialog: CustomDialog.confirmation(
            title: 'Monto mínimo no alcanzado',
            icon: Symbols.warning,
            iconColor: Colors.amber,
            contentWidget: Text(
              'El proveedor ${matchedSupplier.name} exige un monto mínimo de compra (subtotal) de ${CurrencyFormatter.format(matchedSupplier.minimumPurchaseAmount)} USD por orden.\n\n'
              'El subtotal de esta orden es de ${CurrencyFormatter.format(order.subtotal)} USD (te faltan ${CurrencyFormatter.format(diff)} USD para alcanzar el mínimo).',
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
    }

    final branchId = order.supplierBranchId;
    if (branchId == null) {
      CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          title: 'Error de envío',
          contentText:
              'Esta orden no tiene asignada una sucursal para el envío.',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final isResend =
        order.status == SupplierOrderStatus.sent ||
        order.status == SupplierOrderStatus.resent;

    final confirm = await _showSendConfirmationDialog(
      context,
      orderNumber: order.orderNumber,
      supplierName: matchedSupplier?.name ?? '',
      isResend: isResend,
    );
    if (confirm && context.mounted) {
      _handleSendFlow(context, order, items);
    }
  }

  Future<bool> _showSendConfirmationDialog(
    BuildContext context, {
    required String orderNumber,
    required String supplierName,
    required bool isResend,
  }) async {
    return await CustomDialog.show<bool>(
          context: context,
          dialog: CustomDialog.confirmation(
            title: isResend
                ? '¿Reenviar orden de compra?'
                : '¿Enviar orden de compra?',
            icon: isResend ? Symbols.forward : Symbols.send,
            contentText: isResend
                ? '¿Estás seguro de que deseas reenviar esta orden de compra ahora?\n\n$orderNumber ($supplierName)'
                : '¿Estás seguro de que deseas enviar la orden de compra ahora?\n\n$orderNumber ($supplierName)',
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(isResend ? 'Reenviar' : 'Enviar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _finalizeOrderFlow(
    BuildContext context,
    SupplierOrder order,
    List<SupplierOrderItem> items,
  ) async {
    if (_hasActiveAlerts(order, items)) {
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

    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FinalizeSupplierOrderSheet(orderId: order.id),
    );

    if (result != null) {
      if (!context.mounted) return;
      final confirm = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.destructive(
          title: '¿Finalizar Orden de Compra?',
          contentText:
              'Una vez finalizada, esta orden no podrá ser modificada ni cancelada. '
              'El documento cargado debe coincidir plenamente con la Orden de Compra. '
              'De lo contrario, los créditos otorgados serán revertidos y su cuenta puede ser suspendida.',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Finalizar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          await ref
              .read(paginatedSupplierOrdersProvider.notifier)
              .finalizeSupplierOrder(
                orderId: order.id,
                photoFile: result['photoFile'] as File,
                documentType: result['documentType'] as String,
                documentNumber: result['documentNumber'] as String,
                createPurchaseRecord: result['createPurchaseRecord'] as bool,
              );

          if (context.mounted) {
            Navigator.pop(context); // Dismiss loading dialog
          }

          ref.invalidate(supplierOrderDetailProvider(order.id));
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Orden de compra finalizada con éxito.'),
            ),
          );
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // Dismiss loading dialog
          }
          messenger.showSnackBar(
            SnackBar(content: Text('Error al finalizar orden: $e')),
          );
        }
      }
    }
  }
}
