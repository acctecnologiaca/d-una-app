import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/info_disclaimer_card.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/portfolio/domain/models/unaffiliated_supplier_model.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_supplier_sheet.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import 'package:d_una_app/features/supplier_orders/domain/models/supplier_order.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';
import '../providers/add_purchase_provider.dart';

class AddPurchaseDetailsTab extends ConsumerStatefulWidget {
  const AddPurchaseDetailsTab({super.key});

  @override
  ConsumerState<AddPurchaseDetailsTab> createState() =>
      _AddPurchaseDetailsTabState();
}

class _AddPurchaseDetailsTabState extends ConsumerState<AddPurchaseDetailsTab> {
  late final TextEditingController _dateController;
  late final TextEditingController _docNumberController;

  final List<String> _docTypes = [
    'invoice',
    'delivery_note',
    'initial_inventory',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(addPurchaseProvider);
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(state.date),
    );
    _docNumberController = TextEditingController(
      text: state.documentNumber ?? '',
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _docNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final state = ref.read(addPurchaseProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != state.date) {
      ref.read(addPurchaseProvider.notifier).setDate(picked);
      _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(addPurchaseProvider);
    final suppliersAsync = ref.watch(allSuppliersProvider);

    ref.listen<String?>(addPurchaseProvider.select((s) => s.documentNumber), (
      prev,
      next,
    ) {
      if (next != null && next != _docNumberController.text) {
        _docNumberController.text = next;
      }
    });

    final isLinkedToOrder = state.supplierOrderId != null;

    final pendingOrdersAsync = state.supplierId != null
        ? ref.watch(pendingApprovedOrdersBySupplierProvider(state.supplierId!))
        : null;
    final pendingOrders = pendingOrdersAsync?.valueOrNull ?? [];

    final allOrders = [
      ...pendingOrders,
      if (state.linkedSupplierOrder != null &&
          !pendingOrders.any((o) => o.id == state.linkedSupplierOrder!.id))
        state.linkedSupplierOrder!,
    ];

    final selectedOrderItem = allOrders
        .where((o) => o.id == state.supplierOrderId)
        .firstOrNull;

    final isInitialInventory = state.documentType == 'initial_inventory';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isInitialInventory) ...[
            const InfoDisclaimerCard(
              text:
                  'Apertura de existencias físicas. Registra el conteo real en almacén sin requerir factura ni proveedor.',
              showCloseButton: false,
            ),
            const SizedBox(height: 16),
          ],
          if (isLinkedToOrder) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Registro asociado a la Orden de Compra ${selectedOrderItem?.orderNumber ?? ""}. Esta orden pasará a estatus Finalizada al guardar la compra.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Fecha de compra
          CustomTextField(
            label: 'Fecha de compra*',
            controller: _dateController,
            readOnly: true,
            onTap: () => _selectDate(context),
            suffixIcon: Icon(
              Icons.calendar_today_outlined,
              color: colors.onSurfaceVariant,
            ),
            enabled: true,
          ),
          const SizedBox(height: 24),

          if (!isInitialInventory) ...[
            // Proveedor
            suppliersAsync.when(
              data: (List<UnaffiliatedSupplier> suppliers) {
                final selectedSupplier = state.supplierId != null
                    ? suppliers
                          .where(
                            (UnaffiliatedSupplier s) =>
                                s.id == state.supplierId,
                          )
                          .firstOrNull
                    : null;

                return CustomDropdown<UnaffiliatedSupplier>(
                  label: 'Proveedor',
                  value: selectedSupplier,
                  items: suppliers,
                  searchable: !isLinkedToOrder,
                  showAddOption: !isLinkedToOrder,
                  addOptionLabel: 'Agregar proveedor',
                  addOptionValue: UnaffiliatedSupplier(
                    id: '___ADD___',
                    name: '___ADD___',
                  ),
                  itemLabelBuilder: (UnaffiliatedSupplier item) =>
                      item.legalName ?? item.name,
                  enabled: !isLinkedToOrder,
                  onAddPressed: !isLinkedToOrder
                      ? () async {
                          final result =
                              await showModalBottomSheet<UnaffiliatedSupplier>(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainer,
                                builder: (context) =>
                                    const AddEditSupplierSheet(),
                              );

                          if (result != null) {
                            ref
                                .read(addPurchaseProvider.notifier)
                                .setSupplier(
                                  result.id,
                                  result.legalName ?? result.name,
                                  taxId: result.taxId,
                                );
                          }
                        }
                      : null,
                  onChanged: !isLinkedToOrder
                      ? (UnaffiliatedSupplier? val) {
                          if (val != null && val.id != '___ADD___') {
                            ref
                                .read(addPurchaseProvider.notifier)
                                .setSupplier(
                                  val.id,
                                  val.legalName ?? val.name,
                                  taxId: val.taxId,
                                );
                          }
                        }
                      : null,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stack) => FriendlyErrorWidget(error: e),
            ),
            const SizedBox(height: 24),
            if (state.supplierId != null && allOrders.isNotEmpty) ...[
              Text(
                'Orden de compra asociada',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              CustomDropdown<SupplierOrder>(
                value: selectedOrderItem,
                items: allOrders,
                label: 'Vincular orden de compra (Opcional)',
                searchable: true,
                isRequired: false,
                itemLabelBuilder: (o) =>
                    '${o.orderNumber} — ${CurrencyFormatter.format(o.total)} USD (${o.status.label})',
                onChanged: (order) async {
                  if (order == null) {
                    ref
                        .read(addPurchaseProvider.notifier)
                        .setLinkedSupplierOrder(null);
                    return;
                  }

                  if (state.products.isNotEmpty) {
                    final replace = await CustomDialog.show<bool>(
                      context: context,
                      dialog: CustomDialog.confirmation(
                        title: 'Cargar productos',
                        contentText:
                            '¿Deseas reemplazar los productos actuales de la compra con los productos de la orden de compra seleccionada?',
                        actions: [
                          Builder(
                            builder: (c) => TextButton(
                              onPressed: () => Navigator.of(c).pop(false),
                              child: const Text('Solo vincular'),
                            ),
                          ),
                          Builder(
                            builder: (c) => FilledButton(
                              onPressed: () => Navigator.of(c).pop(true),
                              child: const Text('Reemplazar'),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (!context.mounted) return;
                    if (replace == true) {
                      await ref
                          .read(addPurchaseProvider.notifier)
                          .loadFromSupplierOrder(order.id);
                    } else {
                      ref
                          .read(addPurchaseProvider.notifier)
                          .setLinkedSupplierOrder(order);
                    }
                  } else {
                    await ref
                        .read(addPurchaseProvider.notifier)
                        .loadFromSupplierOrder(order.id);
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ],

          // Tipo de documento
          CustomDropdown<String>(
            label: 'Tipo de documento',
            value: state.documentType,
            items: _docTypes,
            enabled: !isLinkedToOrder,
            itemLabelBuilder: (item) {
              switch (item) {
                case 'invoice':
                  return 'Factura';
                case 'delivery_note':
                  return 'Nota de entrega';
                case 'initial_inventory':
                  return 'Inventario inicial (Toma física)';
                default:
                  return item;
              }
            },
            onChanged: (val) {
              if (val != null) {
                ref.read(addPurchaseProvider.notifier).setDocumentType(val);
              }
            },
          ),
          const SizedBox(height: 24),

          // Número de documento / Acta
          CustomTextField(
            label: isInitialInventory
                ? 'Identificador o Acta de inventario*'
                : 'Número de documento*',
            controller: _docNumberController,
            helperText: isInitialInventory
                ? 'Ej. ACTA-001 o código de arqueo interno'
                : 'Nro. Factura o Nota de Entrega',
            prefixIcon: Icon(
              isInitialInventory ? Symbols.fact_check : Icons.numbers,
            ),
            keyboardType: TextInputType.text,
            readOnly: isLinkedToOrder,
            enabled: !isLinkedToOrder,
            onChanged: (val) {
              ref.read(addPurchaseProvider.notifier).setDocumentNumber(val);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
