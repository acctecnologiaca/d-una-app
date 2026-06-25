import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../supplier_orders_list/providers/supplier_orders_providers.dart';
import '../../create_supplier_order/providers/create_supplier_order_provider.dart';
import '../tabs/view_supplier_order_details_tab.dart';
import '../tabs/view_supplier_order_products_tab.dart';
import '../tabs/view_supplier_order_summary_tab.dart';
import '../../../domain/models/supplier_order_status.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:d_una_app/core/pdf/templates/supplier_order_pdf_template.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/shared/utils/string_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupplierOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const SupplierOrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<SupplierOrderDetailsScreen> createState() =>
      _SupplierOrderDetailsScreenState();
}

class _SupplierOrderDetailsScreenState
    extends ConsumerState<SupplierOrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

        Supplier? matchedSupplier;
        for (final s in suppliers) {
          if (s.id == order.supplierId) {
            matchedSupplier = s;
            break;
          }
        }
        final supplierDisplayName = matchedSupplier != null
            ? (matchedSupplier.legalName != null && matchedSupplier.legalName!.isNotEmpty
                ? '${matchedSupplier.name} (${matchedSupplier.legalName})'
                : matchedSupplier.name)
            : order.supplierName;

        return Scaffold(
          appBar: StandardAppBar(
            title: 'Orden de compra',
            subtitle: '#${order.orderNumber} ($supplierDisplayName)',
            actions: [
              IconButton(
                icon: const Icon(Icons.send),
                color: colors.onSurfaceVariant,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Funcionalidad de envío próximamente disponible',
                      ),
                    ),
                  );
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

                          final selectedStatus = await _showStatusDialog(context, order.status);

                          if (selectedStatus != null && selectedStatus != order.status) {
                            try {
                              await ref
                                  .read(paginatedSupplierOrdersProvider.notifier)
                                  .updateSupplierOrderStatus(order.id, selectedStatus.dbValue);

                              ref.invalidate(supplierOrderDetailProvider(order.id));

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Estatus cambiado a "${selectedStatus.label}"'),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Error al cambiar estatus: $e')),
                              );
                            }
                          }
                        },
                      ),
                      BottomSheetActionItem(
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
                        icon: order.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                        label: order.isArchived ? 'Desarchivar' : 'Archivar',
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final router = GoRouter.of(context);
                          context.pop(); // Close action sheet

                          await ref
                              .read(paginatedSupplierOrdersProvider.notifier)
                              .archiveSupplierOrder(order.id, archive: !order.isArchived);

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
              onTap: () => Navigator.of(context, rootNavigator: true).pop(status),
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
}
