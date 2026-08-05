import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/settings/data/models/shipping_method.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/features/collaborators/domain/models/collaborator.dart';
import 'package:d_una_app/features/collaborators/presentation/providers/collaborators_providers.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';
import '../providers/create_supplier_order_provider.dart';
import '../../supplier_orders_list/providers/supplier_orders_providers.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';

class CreateSupplierOrderDetailsTab extends ConsumerStatefulWidget {
  const CreateSupplierOrderDetailsTab({super.key});

  @override
  ConsumerState<CreateSupplierOrderDetailsTab> createState() =>
      _CreateSupplierOrderDetailsTabState();
}

class _CreateSupplierOrderDetailsTabState
    extends ConsumerState<CreateSupplierOrderDetailsTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleSupplierChange(
    Supplier? newSupplier,
    CreateSupplierOrderState state,
  ) async {
    if (newSupplier == null) return;
    if (state.supplierId == newSupplier.id) return;

    if (state.items.isNotEmpty) {
      final confirm = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.destructive(
          title: '¿Cambiar de proveedor?',
          contentText:
              'Si cambias el proveedor, se eliminarán todos los productos agregados a la orden actual.',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Continuar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) {
        // Trigger widget rebuild to restore previous selected supplier in dropdown
        setState(() {});
        return;
      }
    }

    final notifier = ref.read(createSupplierOrderProvider.notifier);
    notifier.setSupplier(newSupplier.id, newSupplier.name);
    notifier.setBranch(null, null); // Clear branch selection
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createSupplierOrderProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final shippingMethodsAsync = ref.watch(shippingMethodsProvider);
    final collaboratorsAsync = ref.watch(collaboratorsProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proveedor',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Supplier dropdown
          suppliersAsync.when(
            data: (suppliers) {
              final userProfile = userProfileAsync.valueOrNull;

              // Filter out suppliers that are locked for this user profile context
              final selectableSuppliers = suppliers.where((s) {
                final isVerified =
                    userProfile?.verificationStatus == 'verified';
                final isBusiness = userProfile?.verificationType == 'business';

                if (!isVerified) {
                  // Unverified: Block all Wholesale suppliers
                  return s.tradeType != 'WHOLESALE';
                } else {
                  // Verified Individual: Block Wholesale suppliers unless they explicitly accept individual
                  if (!isBusiness && s.tradeType == 'WHOLESALE') {
                    return s.allowedVerificationTypes.contains('individual');
                  }
                }
                return true;
              }).toList();

              final selectedSupplier = state.supplierId != null
                  ? selectableSuppliers
                        .where((s) => s.id == state.supplierId)
                        .firstOrNull
                  : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomDropdown<Supplier>(
                    label: 'Proveedor',
                    value: selectedSupplier,
                    items: selectableSuppliers,
                    searchable: true,
                    itemLabelBuilder: (s) => s.name,
                    onChanged: (val) => _handleSupplierChange(val, state),
                  ),
                  if (selectedSupplier != null &&
                      selectedSupplier.minimumPurchaseAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Compra mínima: ${CurrencyFormatter.format(selectedSupplier.minimumPurchaseAmount)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => FriendlyErrorWidget(error: e),
          ),
          const SizedBox(height: 24),

          // Supplier Branch dropdown (only if supplier selected)
          if (state.supplierId != null && state.supplierId!.isNotEmpty) ...[
            ref
                .watch(supplierBranchesProvider(state.supplierId!))
                .when(
                  data: (branches) {
                    if (branches.isEmpty) return const SizedBox.shrink();

                    final selectedBranch = state.supplierBranchId != null
                        ? branches
                              .where((b) => b['id'] == state.supplierBranchId)
                              .firstOrNull
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
                              ref
                                  .read(createSupplierOrderProvider.notifier)
                                  .setBranch(
                                    val['id'] as String,
                                    val['name'] as String,
                                  );
                            } else {
                              ref
                                  .read(createSupplierOrderProvider.notifier)
                                  .setBranch(null, null);
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'El pedido se canalizará a través de esta sucursal',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => FriendlyErrorWidget(error: e),
                ),
          ],
          Text(
            'Condiciones de envío',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Shipping Method dropdown
          shippingMethodsAsync.when(
            data: (methods) {
              // Auto-select primary shipping method if none selected yet
              if (state.shippingMethodId == null && methods.isNotEmpty) {
                final primaryMethod = methods
                    .where((m) => m.isPrimary)
                    .firstOrNull;
                if (primaryMethod != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref
                        .read(createSupplierOrderProvider.notifier)
                        .setShippingMethod(
                          primaryMethod.id,
                          primaryMethod.label,
                        );
                  });
                }
              }

              final selectedMethod = state.shippingMethodId != null
                  ? methods
                        .where((m) => m.id == state.shippingMethodId)
                        .firstOrNull
                  : null;

              return CustomDropdown<ShippingMethod>(
                label: 'Método de envío',
                value: selectedMethod,
                items: methods,
                showAddOption: true,
                addOptionLabel: 'Agregar',
                addOptionValue: ShippingMethod(
                  id: '___ADD___',
                  userId: '',
                  label: '___ADD___',
                  companyId: '',
                  deliveryOption: '___ADD___',
                ),
                itemLabelBuilder: (m) => m.label,
                onAddPressed: () async {
                  await context.push('/settings/shipping-methods/add');
                  ref.invalidate(shippingMethodsProvider);
                },
                onChanged: (val) {
                  if (val != null && val.id != '___ADD___') {
                    ref
                        .read(createSupplierOrderProvider.notifier)
                        .setShippingMethod(val.id, val.label);
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
                  ? collaborators
                        .where((c) => c.id == state.receiverCollaboratorId)
                        .firstOrNull
                  : null;

              return CustomDropdown<Collaborator>(
                label: 'Persona que retira',
                value: selectedCollaborator,
                items: collaborators,
                itemLabelBuilder: (c) => c.fullName,
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(createSupplierOrderProvider.notifier)
                        .setReceiver(val.id, val.fullName);
                  } else {
                    ref
                        .read(createSupplierOrderProvider.notifier)
                        .setReceiver(null, null);
                  }
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => FriendlyErrorWidget(error: e),
          ),
          const SizedBox(height: 24),
          Text(
            'Condiciones de pago',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Payment method dropdown
          paymentMethodsAsync.when(
            data: (methods) {
              final selectedMethod =
                  state.paymentMethod != null &&
                      methods.contains(state.paymentMethod)
                  ? state.paymentMethod
                  : null;

              return CustomDropdown<String>(
                label: 'Método de pago',
                value: selectedMethod,
                items: methods,
                itemLabelBuilder: (m) => m,
                onChanged: (val) {
                  ref
                      .read(createSupplierOrderProvider.notifier)
                      .setPaymentMethod(val);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => FriendlyErrorWidget(error: e),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
