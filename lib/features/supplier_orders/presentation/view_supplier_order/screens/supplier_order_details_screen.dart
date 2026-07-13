import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../supplier_orders_list/providers/supplier_orders_providers.dart';
import '../../create_supplier_order/providers/create_supplier_order_provider.dart';
import '../tabs/view_supplier_order_details_tab.dart';
import '../tabs/view_supplier_order_products_tab.dart';
import '../tabs/view_supplier_order_summary_tab.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
        final supplierDisplayName = matchedSupplier != null
            ? (matchedSupplier.legalName != null &&
                      matchedSupplier.legalName!.isNotEmpty
                  ? '${matchedSupplier.name} (${matchedSupplier.legalName})'
                  : matchedSupplier.name)
            : order.supplierName;

        return Scaffold(
          appBar: StandardAppBar(
            title: 'Orden de compra',
            subtitle: '${order.shortOrderNumber} ($supplierDisplayName)',
            actions: [
              IconButton(
                icon: const Icon(Icons.send),
                color: colors.onSurfaceVariant,
                onPressed: () {
                  _checkAndSendOrder(context, order, items);
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                color: colors.onSurfaceVariant,
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

                          final selectedStatus = await _showStatusDialog(
                            context,
                            order.status,
                          );

                          if (selectedStatus != null &&
                              selectedStatus != order.status) {
                            try {
                              await ref
                                  .read(
                                    paginatedSupplierOrdersProvider.notifier,
                                  )
                                  .updateSupplierOrderStatus(
                                    order.id,
                                    selectedStatus.dbValue,
                                  );

                              ref.invalidate(
                                supplierOrderDetailProvider(order.id),
                              );

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Estatus cambiado a "${selectedStatus.label}"',
                                  ),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error al cambiar estatus: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      /*     BottomSheetActionItem(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'Descargar PDF',
                        onTap: () {
                          final userProfile = ref.read(userProfileProvider).value;
                          final userEmail = Supabase.instance.client.auth.currentUser?.email;

                          if (userProfile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cargando perfil de usuario... Por favor espere.'),
                              ),
                            );
                            return;
                          }

                          context.pop(); // Close action sheet

                          context.push(
                            '/pdf-preview',
                            extra: {
                              'title': 'Previsualizar Orden de Compra',
                              'subtitle': '#${order.orderNumber} (${order.supplierName})',
                              'fileName': StringUtils.sanitizeForFileName(
                                '${order.date.toIso8601String().substring(0, 10)}_${order.supplierName}_${order.orderNumber}.pdf',
                              ),
                              'buildPdf': (PdfPageFormat format) =>
                                  SupplierOrderPdfTemplate(
                                    order: order,
                                    items: items,
                                    userProfile: userProfile,
                                    userEmail: userEmail,
                                  ).generate(format),
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
              tabs: const [
                Tab(text: 'Detalles'),
                Tab(text: 'Productos'),
                Tab(text: 'Resumen'),
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
                  child: FloatingActionButton(
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

  Future<SupplierOrderStatus?> _showStatusDialog(
    BuildContext context,
    SupplierOrderStatus currentStatus,
  ) async {
    final colors = Theme.of(context).colorScheme;

    return CustomDialog.show<SupplierOrderStatus>(
      context: context,
      dialog: CustomDialog.vertical(
        icon: Symbols.conversion_path,
        title: 'Cambiar estatus',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: SupplierOrderStatus.values.map((status) {
            final isSelected = status == currentStatus;
            return ListTile(
              leading: Image.asset(status.iconPath, width: 24, height: 24),
              title: Text(
                status.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colors.primary : colors.onSurface,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: colors.primary, size: 20)
                  : null,
              onTap: () =>
                  Navigator.of(context, rootNavigator: true).pop(status),
            );
          }).toList(),
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

  Future<void> _checkAndSendOrder(
    BuildContext context,
    SupplierOrder order,
    List<SupplierOrderItem> items,
  ) async {
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

    final confirm = await _showSendConfirmationDialog(
      context,
      orderNumber: order.shortOrderNumber,
    );
    if (confirm && context.mounted) {
      _handleSendFlow(context, order, items);
    }
  }

  Future<bool> _showSendConfirmationDialog(
    BuildContext context, {
    required String orderNumber,
  }) async {
    return await CustomDialog.show<bool>(
          context: context,
          dialog: CustomDialog.confirmation(
            title: '¿Enviar orden de compra?',
            icon: Symbols.send,
            contentText:
                '¿Estás seguro de que deseas enviar la orden de compra #$orderNumber ahora?',
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enviar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
