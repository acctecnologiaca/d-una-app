import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/portfolio/domain/models/unaffiliated_supplier_model.dart';
import 'package:d_una_app/features/settings/data/models/shipping_method.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/features/collaborators/domain/models/collaborator.dart';
import 'package:d_una_app/features/collaborators/presentation/providers/collaborators_providers.dart';
import '../providers/create_supplier_order_provider.dart';
import '../providers/supplier_orders_providers.dart';

class CreateSupplierOrderDetailsTab extends ConsumerStatefulWidget {
  const CreateSupplierOrderDetailsTab({super.key});

  @override
  ConsumerState<CreateSupplierOrderDetailsTab> createState() =>
      _CreateSupplierOrderDetailsTabState();
}

class _CreateSupplierOrderDetailsTabState extends ConsumerState<CreateSupplierOrderDetailsTab> {
  late final TextEditingController _dateController;
  late final TextEditingController _paymentMethodController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(createSupplierOrderProvider);
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(state.date),
    );
    _paymentMethodController = TextEditingController(
      text: state.paymentMethod ?? '',
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final state = ref.read(createSupplierOrderProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != state.date) {
      ref.read(createSupplierOrderProvider.notifier).setDate(picked);
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createSupplierOrderProvider);
    final suppliersAsync = ref.watch(allSuppliersProvider);
    final shippingMethodsAsync = ref.watch(shippingMethodsProvider);
    final collaboratorsAsync = ref.watch(collaboratorsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selector
          CustomTextField(
            label: 'Fecha de la orden*',
            controller: _dateController,
            readOnly: true,
            onTap: () => _selectDate(context),
            suffixIcon: Icon(
              Icons.calendar_today_outlined,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Supplier dropdown
          suppliersAsync.when(
            data: (suppliers) {
              final selectedSupplier = state.supplierId != null
                  ? suppliers.where((s) => s.id == state.supplierId).firstOrNull
                  : null;

              return CustomDropdown<UnaffiliatedSupplier>(
                label: 'Proveedor*',
                value: selectedSupplier,
                items: suppliers,
                searchable: true,
                itemLabelBuilder: (s) => s.legalName ?? s.name,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(createSupplierOrderProvider.notifier).setSupplier(val.id, val.legalName ?? val.name);
                    ref.read(createSupplierOrderProvider.notifier).setBranch(null, null); // clear branch
                  }
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => FriendlyErrorWidget(error: e),
          ),
          const SizedBox(height: 24),

          // Supplier Branch dropdown (only if supplier selected)
          if (state.supplierId != null) ...[
            ref.watch(supplierBranchesProvider(state.supplierId!)).when(
              data: (branches) {
                if (branches.isEmpty) return const SizedBox.shrink();

                final selectedBranch = state.supplierBranchId != null
                    ? branches.where((b) => b['id'] == state.supplierBranchId).firstOrNull
                    : null;

                return Column(
                  children: [
                    CustomDropdown<Map<String, dynamic>>(
                      label: 'Sucursal del Proveedor',
                      value: selectedBranch,
                      items: branches,
                      itemLabelBuilder: (b) => b['name'] as String,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(createSupplierOrderProvider.notifier).setBranch(val['id'] as String, val['name'] as String);
                        } else {
                          ref.read(createSupplierOrderProvider.notifier).setBranch(null, null);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => FriendlyErrorWidget(error: e),
            ),
          ],

          // Shipping Method dropdown
          shippingMethodsAsync.when(
            data: (methods) {
              final selectedMethod = state.shippingMethodId != null
                  ? methods.where((m) => m.id == state.shippingMethodId).firstOrNull
                  : null;

              return CustomDropdown<ShippingMethod>(
                label: 'Método de envío',
                value: selectedMethod,
                items: methods,
                showAddOption: true,
                addOptionLabel: 'Agregar método de envío',
                addOptionValue: ShippingMethod(id: '___ADD___', userId: '', label: '___ADD___', companyId: '', deliveryOption: '___ADD___'),
                itemLabelBuilder: (m) => m.label,
                onAddPressed: () async {
                  await context.push('/settings/shipping-methods/add');
                  ref.invalidate(shippingMethodsProvider);
                },
                onChanged: (val) {
                  if (val != null && val.id != '___ADD___') {
                    ref.read(createSupplierOrderProvider.notifier).setShippingMethod(val.id, val.label);
                  }
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => FriendlyErrorWidget(error: e),
          ),
          const SizedBox(height: 24),

          // Receiver Collaborator dropdown
          collaboratorsAsync.when(
            data: (collaborators) {
              final selectedCollaborator = state.receiverCollaboratorId != null
                  ? collaborators.where((c) => c.id == state.receiverCollaboratorId).firstOrNull
                  : null;

              return CustomDropdown<Collaborator>(
                label: 'Persona que recibe/retira',
                value: selectedCollaborator,
                items: collaborators,
                itemLabelBuilder: (c) => c.fullName,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(createSupplierOrderProvider.notifier).setReceiver(val.id, val.fullName);
                  } else {
                    ref.read(createSupplierOrderProvider.notifier).setReceiver(null, null);
                  }
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => FriendlyErrorWidget(error: e),
          ),
          const SizedBox(height: 24),

          // Payment method / conditions
          CustomTextField(
            label: 'Condiciones de pago',
            controller: _paymentMethodController,
            helperText: 'Ej. Crédito 30 días, Transferencia, Contado',
            prefixIcon: const Icon(Icons.payment),
            keyboardType: TextInputType.text,
            onChanged: (val) {
              ref.read(createSupplierOrderProvider.notifier).setPaymentMethod(val);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
