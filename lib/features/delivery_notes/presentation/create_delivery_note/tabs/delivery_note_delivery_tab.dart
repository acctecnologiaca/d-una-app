import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/settings/data/models/shipping_company.dart';
import '../providers/create_delivery_note_provider.dart';

class DeliveryNoteDeliveryTab extends ConsumerStatefulWidget {
  const DeliveryNoteDeliveryTab({super.key});

  @override
  ConsumerState<DeliveryNoteDeliveryTab> createState() =>
      _DeliveryNoteDeliveryTabState();
}

class _DeliveryNoteDeliveryTabState extends ConsumerState<DeliveryNoteDeliveryTab> {
  late final TextEditingController _trackingController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _instructionsController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(createDeliveryNoteProvider);
    _trackingController = TextEditingController(text: state.trackingNumber ?? '');
    _addressController = TextEditingController(text: state.recipientAddress ?? '');
    _cityController = TextEditingController(text: state.recipientCity ?? '');
    _stateController = TextEditingController(text: state.recipientState ?? '');
    _instructionsController =
        TextEditingController(text: state.deliveryInstructions ?? '');
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createDeliveryNoteProvider);
    final shippingCompaniesAsync = ref.watch(shippingCompaniesProvider);
    final shippingCompanies = shippingCompaniesAsync.value ?? [];

    final selectedShippingCompany = shippingCompanies
        .where((c) => c.id == state.shippingCompanyId)
        .firstOrNull;

    // Sync controllers if updated externally (e.g. from client selection)
    if (_addressController.text.isEmpty &&
        state.recipientAddress != null &&
        state.recipientAddress!.isNotEmpty) {
      _addressController.text = state.recipientAddress!;
    }
    if (_cityController.text.isEmpty &&
        state.recipientCity != null &&
        state.recipientCity!.isNotEmpty) {
      _cityController.text = state.recipientCity!;
    }
    if (_stateController.text.isEmpty &&
        state.recipientState != null &&
        state.recipientState!.isNotEmpty) {
      _stateController.text = state.recipientState!;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Selector de Modalidad de Despacho
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
                  label: Text('Retiro en Sede', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.storefront_outlined, size: 16),
                ),
                ButtonSegment<String>(
                  value: 'direct_delivery',
                  label: Text('Entrega Directa', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.local_shipping_outlined, size: 16),
                ),
                ButtonSegment<String>(
                  value: 'courier',
                  label: Text('Encomienda', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.markunread_mailbox_outlined, size: 16),
                ),
              ],
              selected: {state.deliveryType},
              onSelectionChanged: (val) {
                ref
                    .read(createDeliveryNoteProvider.notifier)
                    .setDeliveryType(val.first);
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Opciones específicas de ENCOMIENDA
          if (state.deliveryType == 'courier') ...[
            CustomDropdown<ShippingCompany>(
              value: selectedShippingCompany,
              items: shippingCompanies,
              label: 'Empresa de encomienda *',
              searchable: true,
              itemLabelBuilder: (c) => c.displayName,
              onChanged: (company) {
                ref.read(createDeliveryNoteProvider.notifier).setShippingInfo(
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
              onChanged: (val) {
                ref.read(createDeliveryNoteProvider.notifier).setShippingInfo(
                      shippingCompanyId: state.shippingCompanyId,
                      shippingCompanyName: state.shippingCompanyName,
                      trackingNumber: val.trim().isEmpty ? null : val.trim(),
                    );
              },
            ),
            const SizedBox(height: 20),
          ],

          // 3. Dirección de entrega (para Entrega Directa o Encomienda)
          if (state.deliveryType != 'pickup') ...[
            CustomTextField(
              controller: _addressController,
              label: 'Dirección de destino / entrega *',
              hintText: 'Calle, avenida, edificio, punto de referencia...',
              maxLines: 2,
              onChanged: (val) {
                ref
                    .read(createDeliveryNoteProvider.notifier)
                    .setRecipientAddress(address: val.trim().isEmpty ? null : val.trim());
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _cityController,
                    label: 'Ciudad',
                    hintText: 'Ej. Valencia',
                    onChanged: (val) {
                      ref
                          .read(createDeliveryNoteProvider.notifier)
                          .setRecipientAddress(city: val.trim().isEmpty ? null : val.trim());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _stateController,
                    label: 'Estado',
                    hintText: 'Ej. Carabobo',
                    onChanged: (val) {
                      ref
                          .read(createDeliveryNoteProvider.notifier)
                          .setRecipientAddress(stateName: val.trim().isEmpty ? null : val.trim());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _instructionsController,
              label: 'Instrucciones especiales de entrega',
              hintText: 'Horario permitido, quién recibe, precauciones de transporte...',
              maxLines: 2,
              onChanged: (val) {
                ref
                    .read(createDeliveryNoteProvider.notifier)
                    .setRecipientAddress(instructions: val.trim().isEmpty ? null : val.trim());
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
                  Icon(
                    Icons.info_outline,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Modalidad seleccionada: Retiro en sede / mostrador.\n\nEl cliente o persona autorizada retirará los productos directamente en sus instalaciones. Puede registrar la firma de recepción en la pestaña de Conformidad al momento de la entrega.',
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
}
