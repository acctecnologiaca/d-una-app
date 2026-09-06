import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import '../providers/create_delivery_note_provider.dart';

class DeliveryNoteDetailsTab extends ConsumerStatefulWidget {
  const DeliveryNoteDetailsTab({super.key});

  @override
  ConsumerState<DeliveryNoteDetailsTab> createState() =>
      _DeliveryNoteDetailsTabState();
}

class _DeliveryNoteDetailsTabState extends ConsumerState<DeliveryNoteDetailsTab> {
  late final TextEditingController _dateController;
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _clientPoController;
  late final TextEditingController _tagController;
  late final TextEditingController _notesController;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final state = ref.read(createDeliveryNoteProvider);
    _dateController = TextEditingController(text: _dateFormat.format(state.date));
    _deliveryDateController = TextEditingController(
      text: state.deliveryDate != null ? _dateFormat.format(state.deliveryDate!) : '',
    );
    _clientPoController = TextEditingController(text: state.clientPoNumber ?? '');
    _tagController = TextEditingController(text: state.tag ?? '');
    _notesController = TextEditingController(text: state.notes ?? '');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _deliveryDateController.dispose();
    _clientPoController.dispose();
    _tagController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDeliveryDate}) async {
    final state = ref.read(createDeliveryNoteProvider);
    final initialDate = isDeliveryDate
        ? (state.deliveryDate ?? state.date)
        : state.date;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      if (isDeliveryDate) {
        ref.read(createDeliveryNoteProvider.notifier).setDeliveryDate(picked);
        _deliveryDateController.text = _dateFormat.format(picked);
      } else {
        ref.read(createDeliveryNoteProvider.notifier).setDate(picked);
        _dateController.text = _dateFormat.format(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createDeliveryNoteProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final activeClients = clientsAsync.value ?? [];

    final selectedClient = activeClients
            .where((c) => c.id == state.clientId)
            .firstOrNull ??
        (state.clientId != null
            ? Client(
                id: state.clientId!,
                name: state.clientName ?? '',
                userId: '',
                type: 'company',
                createdAt: DateTime.now(),
                isArchived: true,
              )
            : null);

    final clients = [
      ...activeClients,
      if (selectedClient != null &&
          !activeClients.any((c) => c.id == selectedClient.id))
        selectedClient,
    ];

    final contacts = selectedClient?.contacts ?? [];
    final selectedContact = contacts
        .where((c) => c.id == state.contactId)
        .firstOrNull;

    final isCompany = selectedClient?.type == 'company';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Selector de Cliente
          CustomDropdown<Client>(
            value: selectedClient,
            items: clients,
            label: 'Cliente *',
            searchable: true,
            itemLabelBuilder: (c) => c.alias != null && c.alias!.isNotEmpty
                ? '${c.name} (${c.alias})'
                : c.name,
            showAddOption: true,
            addOptionValue: Client(
              id: '___ADD___',
              name: '___ADD___',
              userId: 'dummy',
              type: 'company',
              createdAt: DateTime.now(),
            ),
            addOptionLabel: 'Agregar cliente nuevo',
            onAddPressed: () async {
              final previousClients = clientsAsync.value ?? [];
              final returnToParam = Uri.encodeComponent(
                '/delivery_notes/create?tab=0',
              );
              await context.push('/clients/add?returnTo=$returnToParam');

              ref.invalidate(clientsProvider);
              final updatedClients = await ref.read(clientsProvider.future);
              final newClients = updatedClients
                  .where((c) => !previousClients.any((pc) => pc.id == c.id))
                  .toList();

              if (newClients.isNotEmpty) {
                final newlyCreated = newClients.first;
                ref.read(createDeliveryNoteProvider.notifier).setClient(newlyCreated);
              }
            },
            onChanged: (client) {
              if (client != null && client.id != '___ADD___') {
                ref.read(createDeliveryNoteProvider.notifier).setClient(client);
              }
            },
          ),
          const SizedBox(height: 16),

          // 2. Selector de Contacto (si aplica)
          if (contacts.isNotEmpty) ...[
            CustomDropdown<Contact>(
              value: selectedContact,
              items: contacts,
              label: 'Persona de contacto',
              searchable: false,
              itemLabelBuilder: (c) => c.phone != null && c.phone!.isNotEmpty
                  ? '${c.name} (${c.phone})'
                  : c.name,
              onChanged: (contact) {
                ref.read(createDeliveryNoteProvider.notifier).setContact(
                      contact?.id,
                      contact?.name,
                    );
              },
            ),
            const SizedBox(height: 16),
          ],

          // 3. Ficha resumen del cliente seleccionado
          if (selectedClient != null) ...[
            InfoBlock(
              label: isCompany ? 'Empresa' : 'Cliente Particular',
              icon: isCompany ? Icons.business_outlined : Icons.person_outline,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedClient.taxId != null && selectedClient.taxId!.isNotEmpty)
                    Text(
                      '${isCompany ? "RIF" : "Cédula"}: ${selectedClient.taxId}',
                      style: TextStyle(fontSize: 13, color: colors.onSurface),
                    ),
                  if (selectedContact != null)
                    Text(
                      'Atención: ${selectedContact.name}${selectedContact.phone != null ? " (${selectedContact.phone})" : ""}',
                      style: TextStyle(fontSize: 13, color: colors.onSurface),
                    )
                  else if (selectedClient.phone != null && selectedClient.phone!.isNotEmpty)
                    Text(
                      'Teléfono: ${selectedClient.phone}',
                      style: TextStyle(fontSize: 13, color: colors.onSurface),
                    ),
                  if (selectedClient.email != null && selectedClient.email!.isNotEmpty)
                    Text(
                      'Email: ${selectedClient.email}',
                      style: TextStyle(fontSize: 13, color: colors.onSurface),
                    ),
                  if (selectedClient.address != null && selectedClient.address!.isNotEmpty)
                    Text(
                      'Dirección fiscal: ${selectedClient.address}',
                      style: TextStyle(fontSize: 13, color: colors.onSurface),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Fechas de emisión y entrega
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _dateController,
                  label: 'Fecha de emisión *',
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  onTap: () => _pickDate(isDeliveryDate: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _deliveryDateController,
                  label: 'Fecha entrega',
                  readOnly: true,
                  suffixIcon: const Icon(Icons.event_available_outlined),
                  onTap: () => _pickDate(isDeliveryDate: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. N° Orden de Compra del Cliente y Tag
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _clientPoController,
                  label: 'OC del Cliente (Opcional)',
                  hintText: 'Ej. OC-CLIENTE-9821',
                  onChanged: (val) {
                    ref
                        .read(createDeliveryNoteProvider.notifier)
                        .setClientPoNumber(val.trim().isEmpty ? null : val.trim());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _tagController,
                  label: 'Etiqueta / Tag',
                  hintText: 'Ej. Despacho Urgente',
                  onChanged: (val) {
                    ref
                        .read(createDeliveryNoteProvider.notifier)
                        .setTag(val.trim().isEmpty ? null : val.trim());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 6. Notas internas del despacho
          CustomTextField(
            controller: _notesController,
            label: 'Notas adicionales o instrucciones',
            hintText: 'Comentarios internos sobre este despacho...',
            maxLines: 3,
            onChanged: (val) {
              ref
                  .read(createDeliveryNoteProvider.notifier)
                  .setNotes(val.trim().isEmpty ? null : val.trim());
            },
          ),
        ],
      ),
    );
  }
}
