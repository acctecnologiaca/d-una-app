import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/settings/data/models/shipping_method.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/features/collaborators/domain/models/collaborator.dart';
import 'package:d_una_app/features/collaborators/presentation/providers/collaborators_providers.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
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
  late final TextEditingController _recipientAddressController;
  late final TextEditingController _recipientContactNameController;
  late final TextEditingController _recipientPhoneNumberController;
  late final TextEditingController _deliveryInstructionsController;

  static const _phoneCodes = [
    '0412',
    '0414',
    '0424',
    '0416',
    '0426',
    '0212',
    '0251',
    '0241',
    '0261',
  ];
  String _selectedPhoneCode = '0412';

  void _initPhone(String? rawPhone) {
    if (rawPhone == null || rawPhone.isEmpty) {
      _selectedPhoneCode = '0412';
      _recipientPhoneNumberController.text = '';
      return;
    }
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    for (final code in _phoneCodes) {
      if (digits.startsWith(code)) {
        _selectedPhoneCode = code;
        _recipientPhoneNumberController.text = digits.substring(code.length);
        return;
      }
      if (digits.startsWith('58') &&
          digits.length > 2 &&
          digits.substring(2).startsWith(code.substring(1))) {
        _selectedPhoneCode = code;
        _recipientPhoneNumberController.text = digits.substring(
          2 + code.length - 1,
        );
        return;
      }
    }
    if (digits.length >= 4) {
      final candidate = digits.substring(0, 4);
      if (_phoneCodes.contains(candidate)) {
        _selectedPhoneCode = candidate;
        _recipientPhoneNumberController.text = digits.substring(4);
        return;
      }
    }
    _selectedPhoneCode = '0412';
    _recipientPhoneNumberController.text = digits;
  }

  void _syncPhoneToProvider() {
    final num = _recipientPhoneNumberController.text.trim();
    final fullPhone = num.isNotEmpty ? '$_selectedPhoneCode$num' : '';
    ref.read(createSupplierOrderProvider.notifier).setRecipientPhone(fullPhone);
  }

  @override
  void initState() {
    super.initState();
    final initial = ref.read(createSupplierOrderProvider);
    _recipientAddressController = TextEditingController(
      text: initial.recipientAddress ?? '',
    );
    _recipientContactNameController = TextEditingController(
      text: initial.recipientContactName ?? '',
    );
    _recipientPhoneNumberController = TextEditingController();
    _initPhone(initial.recipientPhone);
    _deliveryInstructionsController = TextEditingController(
      text: initial.deliveryInstructions ?? '',
    );
  }

  @override
  void dispose() {
    _recipientAddressController.dispose();
    _recipientContactNameController.dispose();
    _recipientPhoneNumberController.dispose();
    _deliveryInstructionsController.dispose();
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
        setState(() {});
        return;
      }
    }

    final notifier = ref.read(createSupplierOrderProvider.notifier);
    notifier.setSupplier(newSupplier.id, newSupplier.name);
    notifier.setBranch(null, null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createSupplierOrderProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final shippingMethodsAsync = ref.watch(shippingMethodsProvider);
    final collaboratorsAsync = ref.watch(collaboratorsProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final theme = Theme.of(context);

    // Sync controllers if state changes externally
    ref.listen<CreateSupplierOrderState>(createSupplierOrderProvider, (
      prev,
      next,
    ) {
      if (next.recipientAddress != prev?.recipientAddress &&
          _recipientAddressController.text != (next.recipientAddress ?? '')) {
        _recipientAddressController.text = next.recipientAddress ?? '';
      }
      if (next.recipientContactName != prev?.recipientContactName &&
          _recipientContactNameController.text !=
              (next.recipientContactName ?? '')) {
        _recipientContactNameController.text = next.recipientContactName ?? '';
      }
      if (next.recipientPhone != prev?.recipientPhone) {
        final currentCombined = _recipientPhoneNumberController.text.isNotEmpty
            ? '$_selectedPhoneCode${_recipientPhoneNumberController.text.trim()}'
            : '';
        if (currentCombined != (next.recipientPhone ?? '')) {
          _initPhone(next.recipientPhone);
        }
      }
      if (next.deliveryInstructions != prev?.deliveryInstructions &&
          _deliveryInstructionsController.text !=
              (next.deliveryInstructions ?? '')) {
        _deliveryInstructionsController.text = next.deliveryInstructions ?? '';
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.quoteId != null && state.quoteId!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta orden de compra está vinculada a una cotización.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Monto mínimo de compra: ${CurrencyFormatter.format(selectedSupplier.minimumPurchaseAmount)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => FriendlyErrorWidget(error: e),
          ),

          // Branch dropdown (only if supplier selected and has branches)
          if (state.supplierId != null &&
              state.supplierId!.trim().isNotEmpty) ...[
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sucursal',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomDropdown<Map<String, dynamic>>(
                          label: 'Sucursal de despacho',
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
                  error: (e, s) => const SizedBox.shrink(),
                ),
          ],

          Text(
            'Destino y condiciones de envío',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Selector de destino: Inventario propio vs Dropshipping
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Recepción propia'),
                  icon: Icon(Icons.shelves),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Envío al cliente'),
                  icon: Icon(Icons.local_shipping_outlined),
                ),
              ],
              selected: {state.isDropshipping},
              onSelectionChanged: (newSelection) {
                ref
                    .read(createSupplierOrderProvider.notifier)
                    .setIsDropshipping(newSelection.first);
              },
            ),
          ),
          const SizedBox(height: 16),

          if (!state.isDropshipping) ...[
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
                // Auto-select user collaborator (self) if none selected yet
                if (state.receiverCollaboratorId == null &&
                    collaborators.isNotEmpty) {
                  final selfCollaborator = collaborators
                      .where((c) => c.isUserRecord)
                      .firstOrNull;
                  if (selfCollaborator != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref
                          .read(createSupplierOrderProvider.notifier)
                          .setReceiver(
                            selfCollaborator.id,
                            selfCollaborator.fullName,
                          );
                    });
                  }
                }

                final selectedCollaborator =
                    state.receiverCollaboratorId != null
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
          ] else ...[
            // Tarjeta informativa Dropshipping
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El proveedor despachará directamente al cliente final. No ingresará mercancía al inventario local.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Selector de Cliente Destinatario
            clientsAsync.when(
              data: (clients) {
                final selectedClient = state.clientId != null
                    ? clients.where((c) => c.id == state.clientId).firstOrNull
                    : null;

                final isCompany = selectedClient?.type == 'company';
                final companyContacts = selectedClient?.contacts ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomDropdown<Client>(
                      label: 'Cliente destinatario',
                      value: selectedClient,
                      items: clients,
                      searchable: true,
                      itemLabelBuilder: (c) => c.name,
                      onChanged: (client) {
                        if (client != null) {
                          final isComp = client.type == 'company';
                          final primaryContact = isComp
                              ? (client.contacts
                                        .where((c) => c.isPrimary)
                                        .firstOrNull ??
                                    client.contacts.firstOrNull)
                              : null;
                          final contactName = primaryContact?.name;
                          final phone = primaryContact?.phone ?? client.phone;

                          _recipientAddressController.text =
                              client.address ?? '';
                          _recipientContactNameController.text =
                              contactName ?? '';
                          _initPhone(phone);
                          _syncPhoneToProvider();

                          ref
                              .read(createSupplierOrderProvider.notifier)
                              .setRecipientClient(
                                clientId: client.id,
                                name: client.name,
                                contactName: contactName,
                                address: client.address,
                                phone: phone != null
                                    ? '$_selectedPhoneCode${_recipientPhoneNumberController.text.trim()}'
                                    : null,
                              );
                        } else {
                          _recipientAddressController.text = '';
                          _recipientContactNameController.text = '';
                          _initPhone(null);
                          ref
                              .read(createSupplierOrderProvider.notifier)
                              .setRecipientClient(
                                clientId: null,
                                name: null,
                                contactName: null,
                                address: null,
                                phone: null,
                              );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Si el cliente es una empresa y tiene más de 1 contacto, permitir elegir
                    if (isCompany && companyContacts.length > 1) ...[
                      CustomDropdown<Contact>(
                        label: 'Seleccionar contacto de la empresa',
                        value: companyContacts
                            .where((c) => c.name == state.recipientContactName)
                            .firstOrNull,
                        items: companyContacts,
                        itemLabelBuilder: (c) =>
                            '${c.name}${c.role != null && c.role!.isNotEmpty ? " (${c.role})" : ""}',
                        onChanged: (contact) {
                          if (contact != null) {
                            _recipientContactNameController.text = contact.name;
                            ref
                                .read(createSupplierOrderProvider.notifier)
                                .setRecipientContactName(contact.name);
                            if (contact.phone != null &&
                                contact.phone!.isNotEmpty) {
                              _initPhone(contact.phone);
                              _syncPhoneToProvider();
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Si el cliente es una empresa, mostrar campo de contacto principal
                    if (isCompany) ...[
                      CustomTextField(
                        controller: _recipientContactNameController,
                        label: 'Contacto principal',
                        hintText: 'Persona que recibe en la empresa',
                        onChanged: (val) {
                          ref
                              .read(createSupplierOrderProvider.notifier)
                              .setRecipientContactName(val);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => FriendlyErrorWidget(error: e),
            ),

            CustomTextField(
              controller: _recipientAddressController,
              label: 'Dirección de entrega',
              hintText: 'Dirección completa donde recibirá el cliente',
              maxLines: 2,
              onChanged: (val) {
                ref
                    .read(createSupplierOrderProvider.notifier)
                    .setRecipientAddress(val);
              },
            ),
            const SizedBox(height: 16),

            // Teléfono dividido en Código + Número
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: CustomDropdown<String>(
                    label: 'Código',
                    value: _selectedPhoneCode,
                    items: _phoneCodes,
                    itemLabelBuilder: (c) => c,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPhoneCode = val);
                        _syncPhoneToProvider();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _recipientPhoneNumberController,
                    label: 'Teléfono de contacto',
                    hintText: '1234567',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(7),
                    ],
                    onChanged: (_) => _syncPhoneToProvider(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _deliveryInstructionsController,
              label: 'Instrucciones de entrega (Opcional)',
              hintText: 'Ej. Persona que recibe, referencias...',
              maxLines: 2,
              onChanged: (val) {
                ref
                    .read(createSupplierOrderProvider.notifier)
                    .setDeliveryInstructions(val);
              },
            ),
            const SizedBox(height: 24),
          ],
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
              // Auto-select default payment method if none selected yet
              if (state.paymentMethod == null && methods.isNotEmpty) {
                final defaultMethod =
                    methods.contains('Transferencia bancaria en bolívares')
                    ? 'Transferencia bancaria en bolívares'
                    : methods.first;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref
                      .read(createSupplierOrderProvider.notifier)
                      .setPaymentMethod(defaultMethod);
                });
              }

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
