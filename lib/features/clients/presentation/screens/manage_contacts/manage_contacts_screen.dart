import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/features/clients/presentation/widgets/contact_list_tile.dart';
import 'package:d_una_app/core/utils/contact_utils.dart';
import '../../../../../shared/widgets/generic_list_screen.dart';

class ManageContactsScreen extends ConsumerStatefulWidget {
  final String clientId;
  final Map<String, dynamic>? initialData;

  const ManageContactsScreen({
    super.key,
    required this.clientId,
    this.initialData,
  });

  @override
  ConsumerState<ManageContactsScreen> createState() =>
      _ManageContactsScreenState();
}

class _ManageContactsScreenState extends ConsumerState<ManageContactsScreen> {
  @override
  Widget build(BuildContext context) {
    final clientId = widget.clientId;
    final clientsState = ref.watch(clientsProvider);

    // We need to wrap the nested contacts list in an AsyncValue for GenericListScreen
    final contactsAsync = clientsState.whenData((clients) {
      final client = clients.firstWhere(
        (c) => c.id == clientId,
        orElse: () => throw Exception('Client not found'),
      );
      return client.contacts;
    });

    final companyName =
        clientsState.valueOrNull
            ?.firstWhere(
              (c) => c.id == clientId,
              orElse: () => throw Exception('Client not found'),
            )
            .name ??
        '';

    return GenericListScreen<dynamic>(
      title: 'Contactos',
      subtitle: companyName,
      itemsAsync: contactsAsync,
      onSearch: (c, query) {
        final q = query.toLowerCase();
        final matchName = c.name.toLowerCase().contains(q);
        final matchRole = (c.role ?? '').toLowerCase().contains(q);
        return matchName || matchRole;
      },
      onAddPressed: () {
        context.go('/clients/$clientId/contacts/add', extra: companyName);
      },
      emptyListMessage: 'No hay contactos registrados',
      itemBuilder: (context, contact) {
        return ContactListTile(
          name: contact.name,
          role: contact.role ?? 'Sin cargo',
          initial: contact.name.isNotEmpty
              ? contact.name[0].toUpperCase()
              : '?',
          isPrimary: contact.isPrimary,
          onPhoneTap: () => ContactUtils.makePhoneCall(contact.phone),
          onWhatsAppTap: () => ContactUtils.launchWhatsApp(contact.phone),
          onTap: () {
            context.go(
              '/clients/$clientId/contacts/details',
              extra: {
                'companyName': companyName,
                'contact': contact,
                'contactCount': contactsAsync.valueOrNull?.length ?? 0,
              },
            );
          },
        );
      },
    );
  }
}
