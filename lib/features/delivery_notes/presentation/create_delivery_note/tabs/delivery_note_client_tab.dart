import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import '../providers/create_delivery_note_provider.dart';

class DeliveryNoteClientTab extends ConsumerStatefulWidget {
  const DeliveryNoteClientTab({super.key});

  @override
  ConsumerState<DeliveryNoteClientTab> createState() => _DeliveryNoteClientTabState();
}

class _DeliveryNoteClientTabState extends ConsumerState<DeliveryNoteClientTab> {
  @override
  Widget build(BuildContext context) {
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

    final isCompany = selectedClient != null && selectedClient.type == 'company';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Selector de Cliente
          CustomDropdown<Client>(
            value: selectedClient,
            items: clients,
            label: 'Nombre o razón social',
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
            addOptionLabel: 'Agregar cliente',
            onAddPressed: () async {
              final previousClients = clientsAsync.value ?? [];
              final returnToParam = Uri.encodeComponent(
                '/delivery_notes/create?tab=1',
              );
              await context.push('/clients/add?returnTo=$returnToParam');

              final newClientsResult = await ref.refresh(
                clientsProvider.future,
              );

              if (mounted && newClientsResult.length > previousClients.length) {
                final oldIds = previousClients.map((c) => c.id).toSet();
                final newClient = newClientsResult.firstWhere(
                  (c) => !oldIds.contains(c.id),
                  orElse: () => newClientsResult.last,
                );
                ref.read(createDeliveryNoteProvider.notifier).setClient(newClient);
              }
            },
            onChanged: (client) {
              if (client != null) {
                if (state.clientId != client.id) {
                  ref.read(createDeliveryNoteProvider.notifier).setClient(client);
                }
              } else {
                ref.read(createDeliveryNoteProvider.notifier).clearClient();
              }
            },
          ),

          // 2. Ficha de Datos del Cliente
          if (selectedClient != null) ...[
            const SizedBox(height: 24),
            Text(
              'Datos del cliente',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InfoBlock.text(
              icon: Icons.badge_outlined,
              label: 'Identificación Fiscal',
              value: selectedClient.taxId ?? 'No especificada',
            ),
            const SizedBox(height: 16),
            InfoBlock.text(
              icon: Icons.location_on_outlined,
              label: 'Dirección fiscal',
              value: [
                selectedClient.address,
                selectedClient.city,
                selectedClient.state,
                selectedClient.country,
              ].where((e) => e != null && e.isNotEmpty).join(', '),
            ),
            if (selectedClient.phone != null &&
                selectedClient.phone!.isNotEmpty) ...[
              const SizedBox(height: 16),
              InfoBlock.text(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: selectedClient.phone!,
              ),
            ],
            if (selectedClient.email != null &&
                selectedClient.email!.isNotEmpty) ...[
              const SizedBox(height: 16),
              InfoBlock.text(
                icon: Icons.email_outlined,
                label: 'Correo Electrónico',
                value: selectedClient.email!,
              ),
            ],
          ],

          // 3. Dropdown de Persona de Contacto (visible para empresas)
          if (selectedClient == null || selectedClient.type == 'company') ...[
            const SizedBox(height: 24),
            CustomDropdown<Contact>(
              value: isCompany ? selectedContact : null,
              items: isCompany ? contacts : const [],
              label: 'Persona de contacto',
              searchable: true,
              itemLabelBuilder: (c) => c.role != null && c.role!.isNotEmpty
                  ? '${c.name} — ${c.role}'
                  : c.name,
              enabled: isCompany,
              showAddOption: isCompany,
              addOptionValue: Contact(
                id: '___ADD___',
                name: '___ADD___',
                clientId: selectedClient?.id ?? '',
                isPrimary: false,
                createdAt: DateTime.now(),
              ),
              addOptionLabel: 'Agregar contacto',
              onAddPressed: !isCompany
                  ? null
                  : () async {
                      final previousContacts = selectedClient.contacts;
                      final returnToParam = Uri.encodeComponent(
                        '/delivery_notes/create?tab=1',
                      );
                      await context.push(
                        '/clients/${selectedClient.id}/contacts/add?returnTo=$returnToParam',
                        extra: selectedClient.name,
                      );

                      final newClientsResult = await ref.refresh(
                        clientsProvider.future,
                      );

                      if (mounted) {
                        final updatedClient = newClientsResult.firstWhere(
                          (c) => c.id == selectedClient.id,
                          orElse: () => selectedClient,
                        );
                        if (updatedClient.contacts.length >
                            previousContacts.length) {
                          final oldIds =
                              previousContacts.map((c) => c.id).toSet();
                          final newContact = updatedClient.contacts.firstWhere(
                            (c) => !oldIds.contains(c.id),
                            orElse: () => updatedClient.contacts.last,
                          );
                          ref
                              .read(createDeliveryNoteProvider.notifier)
                              .setContact(newContact.id, newContact.name);
                        }
                      }
                    },
              onChanged: (contact) {
                if (contact != null) {
                  ref
                      .read(createDeliveryNoteProvider.notifier)
                      .setContact(contact.id, contact.name);
                } else {
                  ref.read(createDeliveryNoteProvider.notifier).clearContact();
                }
              },
            ),
          ],

          // 4. Datos del Contacto seleccionado
          if (isCompany && selectedContact != null) ...[
            const SizedBox(height: 24),
            Text(
              'Datos del contacto',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (selectedContact.phone != null &&
                selectedContact.phone!.isNotEmpty) ...[
              const SizedBox(height: 16),
              InfoBlock.text(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: selectedContact.phone!,
              ),
            ],
            if (selectedContact.email != null &&
                selectedContact.email!.isNotEmpty) ...[
              const SizedBox(height: 16),
              InfoBlock.text(
                icon: Icons.email_outlined,
                label: 'Correo Electrónico',
                value: selectedContact.email!,
              ),
            ],
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
