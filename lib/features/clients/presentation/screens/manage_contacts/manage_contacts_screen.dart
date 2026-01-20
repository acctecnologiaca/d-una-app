import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/features/clients/presentation/widgets/contact_list_tile.dart';
import 'package:d_una_app/core/utils/contact_utils.dart';

class ManageContactsScreen extends ConsumerWidget {
  final String clientId;
  final Map<String, dynamic>? initialData;

  const ManageContactsScreen({
    super.key,
    required this.clientId,
    this.initialData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final clientsState = ref.watch(clientsProvider);

    return clientsState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Error loading clients: $err'))),
      data: (clientsList) {
        final client = clientsList.firstWhere(
          (c) => c.id == clientId,
          orElse: () => throw Exception('Client not found'),
        );

        final companyName = client.name;
        final contacts = client.contacts;

        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contactos',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 20,
                  ),
                ),
                Text(
                  companyName,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  context.push(
                    '/clients/$clientId/contacts/search',
                    extra: companyName,
                  );
                },
              ),
            ],
            backgroundColor: colors.surface,
            foregroundColor: colors.onSurface,
            elevation: 0,
          ),
          body: contacts.isEmpty
              ? Center(
                  child: Text(
                    'No hay contactos registrados',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                  itemCount: contacts.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ContactListTile(
                      name: contact.name,
                      role: contact.role ?? 'Sin cargo',
                      initial: contact.name.isNotEmpty
                          ? contact.name[0].toUpperCase()
                          : '?',
                      isPrimary: contact.isPrimary,
                      onPhoneTap: () =>
                          ContactUtils.makePhoneCall(contact.phone),
                      onWhatsAppTap: () =>
                          ContactUtils.launchWhatsApp(contact.phone),
                      onTap: () {
                        context.go(
                          '/clients/$clientId/contacts/details',
                          extra: {
                            'companyName': companyName,
                            'contact': contact,
                            'contactCount': contacts.length,
                          },
                        );
                      },
                    );
                  },
                ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: FloatingActionButton.extended(
              onPressed: () {
                context.go(
                  '/clients/$clientId/contacts/add',
                  extra: companyName,
                );
              },
              label: const Text(
                'Agregar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.add),
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
            ),
          ),
        );
      },
    );
  }
}
