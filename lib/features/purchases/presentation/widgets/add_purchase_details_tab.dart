import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/portfolio/domain/models/unaffiliated_supplier_model.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_supplier_sheet.dart';
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

  final List<String> _docTypes = ['invoice', 'delivery_note'];

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          ),
          const SizedBox(height: 24),

          // Proveedor
          suppliersAsync.when(
            data: (List<UnaffiliatedSupplier> suppliers) {
              final selectedSupplier = state.supplierId != null
                  ? suppliers
                        .where(
                          (UnaffiliatedSupplier s) => s.id == state.supplierId,
                        )
                        .firstOrNull
                  : null;

              return CustomDropdown<UnaffiliatedSupplier>(
                label: 'Proveedor',
                value: selectedSupplier,
                items: suppliers,
                searchable: true,
                showAddOption: true,
                addOptionLabel: 'Agregar proveedor',
                addOptionValue: UnaffiliatedSupplier(
                  id: '___ADD___',
                  name: '___ADD___',
                ),
                itemLabelBuilder: (UnaffiliatedSupplier item) =>
                    item.legalName ?? item.name,
                onAddPressed: () async {
                  final result = await showModalBottomSheet<UnaffiliatedSupplier>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainer,
                    builder: (context) => const AddEditSupplierSheet(),
                  );

                  if (result != null) {
                    ref.read(addPurchaseProvider.notifier).setSupplier(
                          result.id,
                          result.legalName ?? result.name,
                          taxId: result.taxId,
                        );
                  }
                },
                onChanged: (UnaffiliatedSupplier? val) {
                  if (val != null && val.id != '___ADD___') {
                    ref
                        .read(addPurchaseProvider.notifier)
                        .setSupplier(val.id, val.legalName ?? val.name, taxId: val.taxId);
                  }
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error al cargar proveedores: $e'),
          ),

          const SizedBox(height: 24),

          // Tipo de documento
          CustomDropdown<String>(
            label: 'Tipo de documento',
            value: state.documentType,
            items: _docTypes,
            itemLabelBuilder: (item) => item == 'invoice' ? 'Factura' : 'Nota de entrega',
            onChanged: (val) {
              if (val != null) {
                ref.read(addPurchaseProvider.notifier).setDocumentType(val);
              }
            },
          ),
          const SizedBox(height: 24),

          // Número de documento
          CustomTextField(
            label: 'Número de documento*',
            controller: _docNumberController,
            helperText: 'Nro. Factura o Nota de Entrega',
            prefixIcon: const Icon(Icons.numbers), // the '#' symbol
            keyboardType: TextInputType.text,
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
