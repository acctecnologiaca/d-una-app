import 'package:d_una_app/core/theme/app_theme.dart';
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
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/features/supplier_orders/domain/utils/oc_email_template_builder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/core/utils/contact_utils.dart';
import 'package:d_una_app/core/utils/phone_utils.dart';
import 'package:d_una_app/core/services/whatsapp_repository.dart';
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart'
    show StockStatus;
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool _hasTriggeredSend = false;
  RealtimeChannel? _singleOrderChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    _initSingleOrderRealtime();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(supplierOrderDetailProvider(widget.orderId));
    }
  }

  void _initSingleOrderRealtime() {
    _singleOrderChannel = Supabase.instance.client
        .channel(
          'public:supplier_order_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'supplier_orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.orderId,
          ),
          callback: (payload) {
            // ignore: avoid_print
            print(
              '🔴 [REALTIME DETAIL SCREEN] supplier_order single change: event=${payload.eventType}, new=${payload.newRecord}, old=${payload.oldRecord}',
            );
            final recId =
                (payload.newRecord['id'] ?? payload.oldRecord['id']) as String?;
            if (recId == widget.orderId && mounted) {
              ref.invalidate(supplierOrderDetailProvider(widget.orderId));
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _singleOrderChannel?.unsubscribe();
    _singleOrderChannel = null;
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final detailsAsync = ref.watch(supplierOrderDetailProvider(widget.orderId));
    final suppliers = ref.watch(suppliersProvider).valueOrNull ?? [];

    return detailsAsync.unwrapPrevious().when(
      data: (data) {
        final order = data.order;
        final items = data.items;
        final canEdit = order.status.canEdit;

        final isDraft = order.status == SupplierOrderStatus.draft;
        final isSentOrResent =
            order.status == SupplierOrderStatus.sent ||
            order.status == SupplierOrderStatus.resent ||
            order.status == SupplierOrderStatus.opened ||
            order.status == SupplierOrderStatus.expired;
        final canSendOrResend = isDraft || isSentOrResent;

        final hasTwoFabs =
            (order.status == SupplierOrderStatus.approved) ||
            (canEdit && isSentOrResent);
        final hasOneFab = canEdit && isDraft;
        final double tabBottomPadding = hasTwoFabs
            ? 184.0
            : (hasOneFab ? 112.0 : 24.0);

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

        final supplierDisplayName = matchedSupplier!.name;

        return Scaffold(
          appBar: StandardAppBar(
            title: 'Orden de compra',
            subtitle: '${order.orderNumber} ($supplierDisplayName)',
            actions: [
              IconButton(
                icon: Icon(
                  isDraft
                      ? Icons.send
                      : (isSentOrResent ? Symbols.forward : Icons.send),
                ),
                color: canSendOrResend
                    ? colors.onSurfaceVariant
                    : colors.onSurfaceVariant.withValues(alpha: 0.38),
                tooltip: isDraft
                    ? 'Enviar'
                    : (isSentOrResent ? 'Reenviar' : 'Enviar'),
                onPressed: canSendOrResend
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
                                .loadFromExisting(order, items);
                            context.push(
                              '/supplier-orders/edit/${order.id}?tab=${_tabController.index}',
                            );
                          },
                        ),

                      if (isSentOrResent)
                        BottomSheetActionItem(
                          icon: Symbols.forward,
                          label: 'Reenviar',
                          onTap: () {
                            context.pop();
                            _checkAndSendOrder(context, order, items);
                          },
                        ),
                      if (order.status == SupplierOrderStatus.approved)
                        BottomSheetActionItem(
                          icon: Icons.receipt_long_outlined,
                          label: 'Registrar compra',
                          onTap: () {
                            context.pop();
                            _finalizeOrderFlow(order, items);
                          },
                        ),
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
                      final hasAlerts =
                          canShowAlerts &&
                          (order.hasPriceIncrease ||
                              order.stockStatus != StockStatus.available ||
                              validationState.items.values.any(
                                (item) => item.statuses.isNotEmpty,
                              ));
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
              ViewSupplierOrderDetailsTab(
                order: order,
                bottomPadding: tabBottomPadding,
              ),
              ViewSupplierOrderProductsTab(
                order: order,
                items: items,
                bottomPadding: tabBottomPadding,
              ),
              ViewSupplierOrderSummaryTab(
                order: order,
                items: items,
                onNavigateToTab: (index) => _tabController.animateTo(index),
                bottomPadding: tabBottomPadding,
              ),
            ],
          ),
          floatingActionButton:
              (canEdit ||
                  order.status == SupplierOrderStatus.approved ||
                  isSentOrResent)
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: Builder(
                    builder: (context) {
                      final showFinalizeFab =
                          order.status == SupplierOrderStatus.approved;
                      final showWhatsAppFab =
                          isSentOrResent ||
                          order.status == SupplierOrderStatus.approved;

                      if (showFinalizeFab) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (showWhatsAppFab) ...[
                              FloatingActionButton(
                                heroTag: 'whatsapp_contact_fab',
                                onPressed: () {
                                  _contactSupplierWhatsApp(context, order);
                                },
                                backgroundColor: colors.greenBase,
                                tooltip: 'Contactar proveedor por WhatsApp',
                                child: Image.asset(
                                  'assets/icons/whatsapp_icon.png',
                                  width: 28,
                                  height: 28,
                                  color: colors.greenBaseOn,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            FloatingActionButton(
                              heroTag: 'finalize_order_fab',
                              onPressed: () {
                                _finalizeOrderFlow(order, items);
                              },
                              backgroundColor: colors.secondaryContainer,
                              foregroundColor: colors.onSecondaryContainer,
                              tooltip: 'Registrar compra',
                              child: const Icon(Icons.receipt_long_outlined),
                            ),
                          ],
                        );
                      }

                      if (canEdit) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (showWhatsAppFab) ...[
                              FloatingActionButton(
                                heroTag: 'whatsapp_contact_fab',
                                onPressed: () {
                                  _contactSupplierWhatsApp(context, order);
                                },
                                backgroundColor: colors.greenBase,
                                tooltip: 'Contactar proveedor por WhatsApp',
                                child: Image.asset(
                                  'assets/icons/whatsapp_icon.png',
                                  width: 28,
                                  height: 28,
                                  color: colors.greenBaseOn,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
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

                      return const SizedBox.shrink();
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

      // Determinar canal de recepción configurado (Prioridad: Sucursal -> Proveedor -> 'email')
      final branchChannel = branchInfo['order_reception_channel'] as String?;
      final supplierData = branchInfo['suppliers'] as Map<String, dynamic>?;
      final supplierChannel =
          supplierData?['order_reception_channel'] as String?;

      String channel = branchChannel ?? supplierChannel ?? 'email';
      if (branchChannel == null && supplierChannel == null) {
        // Fallback buscando en la lista local de proveedores
        final suppliersList = ref.read(suppliersProvider).value ?? [];
        final matchedSupplier = suppliersList
            .where((s) => s.id == order.supplierId)
            .firstOrNull;
        if (matchedSupplier != null) {
          channel = matchedSupplier.orderReceptionChannel;
        }
      }

      final hasEmail = email != null && email.trim().isNotEmpty;
      final hasPhone = phone != null && phone.trim().isNotEmpty;

      if (channel == 'whatsapp') {
        if (!hasPhone) {
          CustomDialog.show(
            context: context,
            dialog: CustomDialog.confirmation(
              title: 'Error de envío',
              contentText:
                  'La sucursal seleccionada está configurada para recibir órdenes por WhatsApp pero no cuenta con un número de teléfono registrado.',
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
        _sendViaWhatsApp(context, order, items, phone.trim(), email?.trim());
      } else if (channel == 'both') {
        // Si tiene ambos, enviamos por correo prioritariamente y si tiene teléfono se le notifica
        if (hasEmail) {
          _sendViaEmail(context, order, items, email.trim(), phone?.trim());
        } else if (hasPhone) {
          _sendViaWhatsApp(context, order, items, phone.trim(), null);
        } else {
          CustomDialog.show(
            context: context,
            dialog: CustomDialog.confirmation(
              title: 'Error de envío',
              contentText:
                  'La sucursal no cuenta con correo ni teléfono registrado.',
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        // Canal por defecto: email
        if (!hasEmail) {
          CustomDialog.show(
            context: context,
            dialog: CustomDialog.confirmation(
              title: 'Error de envío',
              contentText:
                  'La sucursal seleccionada no cuenta con un correo electrónico registrado en la plataforma para el envío automático de la orden. Por favor, contacta al administrador.',
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
        _sendViaEmail(context, order, items, email.trim(), phone?.trim());
      }
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

  Future<void> _sendViaWhatsApp(
    BuildContext context,
    SupplierOrder order,
    List<SupplierOrderItem> items,
    String phone,
    String? email,
  ) async {
    var isLoadingShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userProfile = ref.read(userProfileProvider).value;
      if (userProfile == null) {
        throw Exception('No se pudo cargar el perfil del usuario.');
      }

      // 1. Generar token de acción único de 72h
      final actionToken = await ref
          .read(supplierOrdersRepositoryProvider)
          .generateActionToken(order.id);

      final cleanPhone = PhoneUtils.normalizeForWhatsApp(phone);
      if (cleanPhone == null) {
        throw Exception(
          'El número de teléfono del proveedor ($phone) no tiene un formato válido para WhatsApp.',
        );
      }

      // Extraer datos del comprador
      final hasCompany =
          userProfile.companyName != null &&
          userProfile.companyName!.trim().isNotEmpty;
      final buyerName = hasCompany
          ? userProfile.companyName!.trim()
          : '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'
                .trim();
      final finalBuyerName = buyerName.isEmpty ? 'Cliente' : buyerName;

      final userPhone = userProfile.phone?.trim() ?? '';

      // Truncar para el header si es necesario (Meta limita el header total a 60 chars; "Nueva OC de " usa 12 chars)
      final headerBuyerName = finalBuyerName.length > 48
          ? finalBuyerName.substring(0, 48).trim()
          : finalBuyerName;

      // 2. Invocación WhatsApp Cloud API vía Repositorio
      await ref
          .read(whatsappRepositoryProvider)
          .sendMessage(
            phone: cleanPhone,
            templateName: 'd_una_envio_orden_compra',
            headerVariables: [
              {'name': 'usuario', 'text': headerBuyerName},
            ],
            bodyVariables: [
              {'name': 'nro_orden_compra', 'text': order.orderNumber},
              {'name': 'usuario', 'text': finalBuyerName},
              {'name': 'telefono', 'text': userPhone},
            ],
            buttonUrlParam: 'order.html?token=$actionToken',
          );

      // 3. Actualizar estado de la orden a sent / resent
      final newStatus = order.status == SupplierOrderStatus.draft
          ? SupplierOrderStatus.sent
          : SupplierOrderStatus.resent;

      await ref
          .read(paginatedSupplierOrdersProvider.notifier)
          .updateSupplierOrderStatus(order.id, newStatus.dbValue);

      ref.invalidate(supplierOrderDetailProvider(order.id));

      if (!context.mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      isLoadingShowing = false;

      _showDisclaimerDialog(context, 'WhatsApp', phone, order);
    } catch (e) {
      if (context.mounted) {
        if (isLoadingShowing) {
          Navigator.pop(context);
        }
        CustomDialog.show(
          context: context,
          dialog: CustomDialog.confirmation(
            title: 'Error al enviar WhatsApp',
            contentText: 'Ocurrió un error al enviar la orden por WhatsApp: $e',
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

      final userName =
          '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();

      // Generar token de acción único de 72h
      final actionToken = await ref
          .read(supplierOrdersRepositoryProvider)
          .generateActionToken(order.id);

      final bodyHtml = OcEmailTemplateBuilder.buildHtmlBody(
        order: order,
        items: items,
        userProfile: userProfile,
        userEmail: userEmail ?? '',
        actionToken: actionToken,
      );

      final response = await Supabase.instance.client.functions.invoke(
        'send_document_email',
        body: {
          'documentBase64': null,
          'fileName': null,
          'documentType': 'supplier_order',
          'documentId': order.id,
          'recipientEmails': [email],
          'userContext': {
            'name': userName.isEmpty ? 'Usuario' : userName,
            'companyName': userProfile.companyName,
            'phone': userProfile.phone,
            'companyLogo': userProfile.companyLogoUrl,
          },
          'emailContent': {
            'subject': OcEmailTemplateBuilder.buildSubject(
              order: order,
              userProfile: userProfile,
            ),
            'bodyHtml': bodyHtml,
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
              'La orden ha sido enviada exitosamente',
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
                backgroundColor: colors.greenBase,
                foregroundColor: colors.greenBaseOn,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                final msg =
                    'Hola, acabo de enviarles la Orden de Compra #${order.orderNumber} al correo electrónico, quisiera concretar la compra de los productos que aparecen en ella, ¿podrían indicarme los pasos a seguir? Gracias.';
                ContactUtils.launchWhatsApp(branchPhone, message: msg);
              },
              icon: Image.asset(
                'assets/icons/whatsapp_icon.png',
                width: 22,
                color: colors.greenBaseOn,
              ),
              label: Text(
                'Contactar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
    final hasValidationAlerts = validationState.items.values.any(
      (item) => item.statuses.isNotEmpty,
    );

    return order.hasPriceIncrease ||
        order.stockStatus != StockStatus.available ||
        hasValidationAlerts ||
        items.any(
          (item) =>
              item.hasPriceIncrease || item.isOutOfStock || item.hasLowStock,
        );
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
      if (!mounted) return;
      final confirm = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.destructive(
          title: '¿Registrar compra?',
          contentText:
              'Se creará el registro de compra y los productos se agregarán a tu inventario.\n'
              'La orden pasará a estatus finalizada.',
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Registrar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        if (!mounted) return;
        final navigator = Navigator.of(context, rootNavigator: true);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          final purchaseId = await ref
              .read(paginatedSupplierOrdersProvider.notifier)
              .finalizeSupplierOrder(
                orderId: order.id,
                photoFile: result['photoFile'] as File,
                documentType: result['documentType'] as String,
                documentNumber: result['documentNumber'] as String,
                createPurchaseRecord: result['createPurchaseRecord'] as bool,
              );

          navigator.pop(); // Dismiss loading dialog cleanly
          await Future.delayed(const Duration(milliseconds: 100));

          if (!mounted) return;

          if (result['createPurchaseRecord'] == true && purchaseId != null) {
            final goToPurchase = await CustomDialog.show<bool>(
              context: context,
              dialog: CustomDialog.confirmation(
                title: '¿Completar registro?',
                contentText:
                    'Se generó el registro de compra. ¿Deseas agregar ahora los seriales y tiempos de garantía de los productos registrados?',
                actions: [
                  TextButton(
                    onPressed: () => navigator.pop(false),
                    child: const Text('Más tarde'),
                  ),
                  FilledButton(
                    onPressed: () => navigator.pop(true),
                    child: const Text('Registrar ahora'),
                  ),
                ],
              ),
            );

            ref.invalidate(supplierOrderDetailProvider(order.id));
            ref.invalidate(linkedPurchaseProvider(order.id));

            if (goToPurchase == true && mounted) {
              context.push(
                '/my-purchases/view/$purchaseId',
                extra: {'editMode': true},
              );
            }
          } else {
            ref.invalidate(supplierOrderDetailProvider(order.id));
            ref.invalidate(linkedPurchaseProvider(order.id));

            messenger.showSnackBar(
              const SnackBar(
                content: Text('Orden de compra finalizada con éxito.'),
              ),
            );
          }
        } catch (e) {
          navigator.pop(); // Dismiss loading dialog cleanly on error
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text('Error al finalizar orden: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _contactSupplierWhatsApp(
    BuildContext context,
    SupplierOrder order,
  ) async {
    final branchId = order.supplierBranchId;
    if (branchId == null) {
      CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          title: 'Contacto no disponible',
          contentText: 'La orden no tiene una sucursal asignada.',
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

    final branchInfo = await ref.read(
      supplierBranchContactInfoProvider(branchId).future,
    );

    final phone = branchInfo?['phone'] as String?;
    if (phone != null && phone.trim().isNotEmpty) {
      final msg =
          'Hola, les escribo con respecto a la Orden de Compra #${order.orderNumber}, la cual fue enviada a su correo electrónico. Quisiera concretar la compra de los productos que aparecen en ella, ¿podrían indicarme los pasos a seguir? Gracias.';
      ContactUtils.launchWhatsApp(phone.trim(), message: msg);
    } else {
      if (context.mounted) {
        CustomDialog.show(
          context: context,
          dialog: CustomDialog.confirmation(
            title: 'Contacto no disponible',
            contentText:
                'La sucursal seleccionada no cuenta con un número de teléfono registrado.',
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
}
