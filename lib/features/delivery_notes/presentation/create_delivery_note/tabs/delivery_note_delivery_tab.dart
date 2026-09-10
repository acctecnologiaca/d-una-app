import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_location_picker.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/settings/data/models/shipping_company.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_shipping_company_sheet.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import '../providers/create_delivery_note_provider.dart';

class DeliveryNoteDeliveryTab extends ConsumerStatefulWidget {
  const DeliveryNoteDeliveryTab({super.key});

  @override
  ConsumerState<DeliveryNoteDeliveryTab> createState() =>
      _DeliveryNoteDeliveryTabState();
}

class _DeliveryNoteDeliveryTabState
    extends ConsumerState<DeliveryNoteDeliveryTab>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _trackingController;
  late final TextEditingController _addressController;
  late final TextEditingController _instructionsController;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final state = ref.read(createDeliveryNoteProvider);
    _deliveryDateController = TextEditingController(
      text: state.deliveryDate != null
          ? _dateFormat.format(state.deliveryDate!)
          : '',
    );
    _trackingController = TextEditingController(
      text: state.trackingNumber ?? '',
    );
    _addressController = TextEditingController(
      text: state.recipientAddress ?? '',
    );
    _instructionsController = TextEditingController(
      text: state.deliveryInstructions ?? '',
    );
  }

  @override
  void dispose() {
    _deliveryDateController.dispose();
    _trackingController.dispose();
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickDeliveryDate() async {
    final state = ref.read(createDeliveryNoteProvider);
    final initial = state.deliveryDate ?? state.date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      ref.read(createDeliveryNoteProvider.notifier).setDeliveryDate(picked);
      _deliveryDateController.text = _dateFormat.format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createDeliveryNoteProvider);
    final shippingCompaniesAsync = ref.watch(shippingCompaniesProvider);
    final shippingCompanies = shippingCompaniesAsync.value ?? [];

    final clientsAsync = ref.watch(clientsProvider);
    final clients = clientsAsync.value ?? [];
    final selectedClient = clients
        .where((c) => c.id == state.clientId)
        .firstOrNull;
    final clientHasAddress =
        selectedClient != null &&
        selectedClient.address != null &&
        selectedClient.address!.trim().isNotEmpty;

    final selectedShippingCompany = shippingCompanies
        .where((c) => c.id == state.shippingCompanyId)
        .firstOrNull;

    // Reactively sync controllers if state changes externally
    ref.listen<DeliveryNoteCreateState>(createDeliveryNoteProvider, (
      previous,
      next,
    ) {
      final formattedDeliveryDate = next.deliveryDate != null
          ? _dateFormat.format(next.deliveryDate!)
          : '';
      if (_deliveryDateController.text != formattedDeliveryDate) {
        _deliveryDateController.text = formattedDeliveryDate;
      }
      if (next.trackingNumber != previous?.trackingNumber &&
          _trackingController.text != (next.trackingNumber ?? '')) {
        _trackingController.text = next.trackingNumber ?? '';
      }
      if (next.recipientAddress != previous?.recipientAddress &&
          _addressController.text != (next.recipientAddress ?? '')) {
        _addressController.text = next.recipientAddress ?? '';
      }
      if (next.deliveryInstructions != previous?.deliveryInstructions &&
          _instructionsController.text != (next.deliveryInstructions ?? '')) {
        _instructionsController.text = next.deliveryInstructions ?? '';
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Fecha de despacho
          CustomTextField(
            controller: _deliveryDateController,
            label: 'Fecha de Despacho',
            hintText: 'Seleccionar fecha...',
            readOnly: true,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDeliveryDate,
          ),
          const SizedBox(height: 20),

          // 2. Selector de Modalidad de Despacho
          Text(
            'Modalidad de Despacho *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'pickup',
                  icon: Icon(Icons.storefront_outlined, size: 20),
                  tooltip: 'Retiro en Sede',
                ),
                ButtonSegment<String>(
                  value: 'direct_delivery',
                  icon: Icon(Icons.local_shipping_outlined, size: 20),
                  tooltip: 'Entrega Directa',
                ),
                ButtonSegment<String>(
                  value: 'courier',
                  icon: Icon(Icons.markunread_mailbox_outlined, size: 20),
                  tooltip: 'Encomienda',
                ),
              ],
              selected: {state.deliveryType},
              onSelectionChanged: (val) {
                ref
                    .read(createDeliveryNoteProvider.notifier)
                    .setDeliveryType(val.first);
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.comfortable,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildModalityHelper(context, state.deliveryType),
          const SizedBox(height: 16),

          // 3. Opciones para Entrega Directa o Encomienda
          if (state.deliveryType != 'pickup') ...[
            // Opciones específicas de ENCOMIENDA
            if (state.deliveryType == 'courier') ...[
              CustomDropdown<ShippingCompany>(
                value: selectedShippingCompany,
                items: shippingCompanies,
                label: 'Empresa de encomienda',
                isRequired: true,
                searchable: true,
                itemLabelBuilder: (c) => c.displayName,
                showAddOption: true,
                addOptionLabel: 'Agregar empresa',
                addOptionValue: const ShippingCompany(
                  id: '___ADD___',
                  legalName: '___ADD___',
                  taxId: '___ADD___',
                  userId: '',
                ),
                onAddPressed: () async {
                  final result = await showModalBottomSheet<ShippingCompany>(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    backgroundColor: colors.surfaceContainer,
                    builder: (context) => const AddEditShippingCompanySheet(),
                  );
                  if (result != null && mounted) {
                    ref
                        .read(createDeliveryNoteProvider.notifier)
                        .setShippingInfo(
                          shippingCompanyId: result.id,
                          shippingCompanyName: result.displayName,
                          trackingNumber: state.trackingNumber,
                        );
                  }
                },
                onChanged: (company) {
                  ref
                      .read(createDeliveryNoteProvider.notifier)
                      .setShippingInfo(
                        shippingCompanyId: company?.id,
                        shippingCompanyName: company?.displayName,
                        trackingNumber: state.trackingNumber,
                      );
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _trackingController,
                label: 'Número de guía / tracking *',
                hintText: 'Ej. 981240129',
                maxLength: 50,
                onChanged: (val) {
                  ref
                      .read(createDeliveryNoteProvider.notifier)
                      .setShippingInfo(
                        shippingCompanyId: state.shippingCompanyId,
                        shippingCompanyName: state.shippingCompanyName,
                        trackingNumber: val.trim().isEmpty ? null : val.trim(),
                      );
                },
              ),
              const SizedBox(height: 20),
            ],

            // Switch "Usar la dirección registrada del cliente"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usar la dirección registrada del cliente',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: clientHasAddress
                                ? colors.onSurface
                                : colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedClient == null
                              ? 'Selecciona un cliente en la pestaña Cliente'
                              : (clientHasAddress
                                    ? 'Bloquea la edición y toma los datos registrados del cliente'
                                    : 'El cliente no posee dirección registrada'),
                          style: TextStyle(
                            fontSize: 12,
                            color: clientHasAddress
                                ? colors.onSurfaceVariant
                                : colors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.useClientAddress,
                    onChanged: clientHasAddress
                        ? (val) {
                            ref
                                .read(createDeliveryNoteProvider.notifier)
                                .setUseClientAddress(val);
                            if (val) {
                              _addressController.text =
                                  selectedClient.address ?? '';
                              ref
                                  .read(createDeliveryNoteProvider.notifier)
                                  .setRecipientAddress(
                                    address: selectedClient.address,
                                    stateName: selectedClient.state,
                                    city: selectedClient.city,
                                  );
                            } else {
                              _addressController.clear();
                              ref
                                  .read(createDeliveryNoteProvider.notifier)
                                  .clearRecipientAddress();
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dirección de destino / entrega
            CustomTextField(
              controller: _addressController,
              label: 'Dirección de destino / entrega *',
              helperText: 'Dirección detallada con punto de referencia.',
              maxLines: 2,
              maxLength: 250,
              enabled: !state.useClientAddress,
              suffixIcon: state.useClientAddress
                  ? Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    )
                  : null,
              onChanged: (val) {
                ref
                    .read(createDeliveryNoteProvider.notifier)
                    .setRecipientAddress(
                      address: val.trim().isEmpty ? null : val.trim(),
                    );
              },
            ),
            const SizedBox(height: 16),

            // Estado y Ciudad en cascada (uno debajo del otro, obligatorios)
            CustomLocationPicker(
              showCountry: false,
              isRequired: true,
              enabled: !state.useClientAddress,
              selectedState: state.recipientState,
              selectedCity: state.recipientCity,
              spacing: 16,
              onStateChanged: (val) {
                ref
                    .read(createDeliveryNoteProvider.notifier)
                    .setRecipientAddress(stateName: val, clearCity: true);
              },
              onCityChanged: (val) {
                ref
                    .read(createDeliveryNoteProvider.notifier)
                    .setRecipientAddress(city: val);
              },
            ),
            const SizedBox(height: 16),

            // Instrucciones especiales de entrega
            CustomTextField(
              controller: _instructionsController,
              label: 'Instrucciones especiales de entrega',
              helperText:
                  'Horario permitido, quién recibe, precauciones de transporte...',
              maxLines: 2,
              maxLength: 250,
              onChanged: (val) {
                ref
                    .read(createDeliveryNoteProvider.notifier)
                    .setRecipientAddress(
                      instructions: val.trim().isEmpty ? null : val.trim(),
                    );
              },
            ),
          ] else ...[
            // Aviso explicativo de retiro en sede
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: colors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Puedes registrar la firma o recepción una vez guardado el documento o desde el detalle de la nota de entrega.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModalityHelper(BuildContext context, String deliveryType) {
    final colors = Theme.of(context).colorScheme;
    String title;
    String description;
    IconData icon;

    switch (deliveryType) {
      case 'pickup':
        title = 'Retiro en Sede';
        description =
            'El cliente o persona autorizada retirará los productos directamente en sus instalaciones.';
        icon = Icons.storefront_outlined;
        break;
      case 'courier':
        title = 'Encomienda';
        description =
            'Envío gestionado a través de una empresa de transporte o courier.';
        icon = Icons.markunread_mailbox_outlined;
        break;
      case 'direct_delivery':
      default:
        title = 'Entrega Directa';
        description =
            'Despacho con transporte propio a la dirección acordada con el cliente.';
        icon = Icons.local_shipping_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
