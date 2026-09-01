import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/create_quote_provider.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../shared/widgets/info_block.dart';
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
    final activeClients = clientsAsync.value ?? [];

    // Find the currently selected client object
    final selectedClient = activeClients
            .where((c) => c.id == state.clientId)
            .firstOrNull ??
        (state.quote?.clientId == state.clientId && state.clientId != null
            ? Client(
                id: state.clientId!,
                name: state.quote?.clientName ?? '',
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

          // 2. Datos del Cliente (Ubicados sobre el dropdown de contacto)
          if (selectedClient != null) ...[
            const SizedBox(height: 24),
            Text(
              'Datos del cliente',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.badge_outlined,
              label: 'Identificación Fiscal',
              value: selectedClient.taxId ?? 'No especificada',
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.location_on_outlined,
              label: 'Dirección',
              value: [
                selectedClient.address,
                selectedClient.city,
                selectedClient.state,
                selectedClient.country,
              ].where((e) => e != null && e.isNotEmpty).join(', '),
            ),
            if (selectedClient.phone != null &&
                selectedClient.phone!.isNotEmpty) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: selectedClient.phone!,
              ),
            ],
            if (selectedClient.email != null &&
                selectedClient.email!.isNotEmpty) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.email_outlined,
                label: 'Correo Electrónico',
                value: selectedClient.email!,
              ),
            ],
          ],

          // 3. Dropdown de Persona de Contacto (Oculto si el cliente es persona natural, habilitado para empresas)
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
                          final oldIds =
                              previousContacts.map((c) => c.id).toSet();
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
              onChanged: (contact) {
                if (contact != null) {
                  ref
                      .read(createQuoteProvider.notifier)
                      .setContact(contact.id, contact.name);
                } else {
                  ref.read(createQuoteProvider.notifier).clearContact();
                }
              },
            ),
          ],

          // 4. Datos del Contacto (Debajo del dropdown de contacto para empresas)
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
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: selectedContact.phone!,
              ),
            ],
            if (selectedContact.email != null &&
                selectedContact.email!.isNotEmpty) ...[
              const SizedBox(height: 24),
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
