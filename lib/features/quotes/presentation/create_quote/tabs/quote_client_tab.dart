import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/create_quote_provider.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../clients/presentation/providers/clients_provider.dart';
import '../../../../clients/data/models/client_model.dart';

class QuoteClientTab extends ConsumerStatefulWidget {
  const QuoteClientTab({super.key});

  @override
  ConsumerState<QuoteClientTab> createState() => _QuoteClientTabState();
}

class _QuoteClientTabState extends ConsumerState<QuoteClientTab> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createQuoteProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final clients = clientsAsync.value ?? [];

    // Find the currently selected client object
    final selectedClient = clients
        .where((c) => c.id == state.clientId)
        .firstOrNull;

    final contacts = selectedClient?.contacts ?? [];
    final selectedContact = contacts
        .where((c) => c.id == state.contactId)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Client Dropdown ───────────────────────────────────────────
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
              final returnToParam = Uri.encodeComponent('/quotes/create?tab=2');
              await context.push('/clients/add?returnTo=$returnToParam');

              // Refresh and wait for result
              final newClientsResult = await ref.refresh(
                clientsProvider.future,
              );

              if (mounted && newClientsResult.length > previousClients.length) {
                // Auto-select the newly added one (find the ID not in previous list)
                final oldIds = previousClients.map((c) => c.id).toSet();
                final newClient = newClientsResult.firstWhere(
                  (c) => !oldIds.contains(c.id),
                  orElse: () => newClientsResult.last,
                );
                ref.read(createQuoteProvider.notifier).setClient(newClient);
              }
            },
            onChanged: (client) {
              if (client != null) {
                if (state.clientId != client.id) {
                  ref.read(createQuoteProvider.notifier).setClient(client);
                }
              } else {
                ref.read(createQuoteProvider.notifier).clearClient();
              }
            },
          ),
          const SizedBox(height: 24),

          // ── Contact Dropdown ───────────────────────────────────────────
          CustomDropdown<Contact>(
            value: selectedContact,
            items: contacts,
            label: (selectedClient?.type == 'person')
                ? 'Persona de contacto (No aplica)'
                : 'Persona de contacto',
            searchable: true,
            itemLabelBuilder: (c) => c.role != null && c.role!.isNotEmpty
                ? '${c.name} — ${c.role}'
                : c.name,
            // Disabled until a company client is selected
            enabled: selectedClient != null && selectedClient.type != 'person',
            onChanged: (contact) {
              if (contact != null) {
                ref
                    .read(createQuoteProvider.notifier)
                    .setContact(contact.id, contact.name);
              }
            },
            showAddOption:
                selectedClient != null && selectedClient.type != 'person',
            addOptionValue: Contact(
              id: '___ADD___',
              name: '___ADD___',
              clientId: selectedClient?.id ?? '',
              isPrimary: false,
              createdAt: DateTime.now(),
            ),
            addOptionLabel: 'Agregar contacto',
            onAddPressed:
                (selectedClient == null || selectedClient.type == 'person')
                ? null
                : () async {
                    final previousContacts = selectedClient.contacts;
                    final returnToParam = Uri.encodeComponent(
                      '/quotes/create?tab=2',
                    );
                    await context.push(
                      '/clients/${selectedClient.id}/contacts/add?returnTo=$returnToParam',
                      extra: selectedClient.name,
                    );

                    // Refresh to get the new contact
                    final newClientsResult = await ref.refresh(
                      clientsProvider.future,
                    );

                    if (mounted) {
                      // Find the updated client object
                      final updatedClient = newClientsResult.firstWhere(
                        (c) => c.id == selectedClient.id,
                        orElse: () => selectedClient,
                      );
                      if (updatedClient.contacts.length >
                          previousContacts.length) {
                        final oldIds = previousContacts
                            .map((c) => c.id)
                            .toSet();
                        final newContact = updatedClient.contacts.firstWhere(
                          (c) => !oldIds.contains(c.id),
                          orElse: () => updatedClient.contacts.last,
                        );
                        ref
                            .read(createQuoteProvider.notifier)
                            .setContact(newContact.id, newContact.name);
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }
}
