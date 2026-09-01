import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/clients/presentation/widgets/contact_list_tile.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import 'package:d_una_app/core/utils/contact_utils.dart';

class ClientDetailsScreen extends ConsumerWidget {
  final String clientId;
  final Client? initialClient;

  const ClientDetailsScreen({
    super.key,
    required this.clientId,
    this.initialClient,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final clientsAsync = ref.watch(clientsProvider);

    final client = clientsAsync.valueOrNull?.firstWhere(
          (c) => c.id == clientId,
          orElse: () =>
              initialClient ??
              Client(
                id: '',
                userId: '',
                name: '',
                type: '',
                createdAt: DateTime.now(),
                contacts: [],
              ),
        ) ??
        initialClient ??
        Client(
          id: '',
          userId: '',
          name: '',
          type: '',
          createdAt: DateTime.now(),
          contacts: [],
        );

    if (client.id.isEmpty) {
      if (clientsAsync.isLoading) {
        return Scaffold(
          backgroundColor: colors.surface,
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          elevation: 0,
        ),
        body: const Center(child: Text('Cliente no encontrado')),
      );
    }

        final isCompany = client.type == 'company';
        final fullAddress = [
          client.address,
          client.city,
          client.state,
          client.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        final title = isCompany
            ? 'Detalles de la empresa'
            : 'Detalles del cliente';

        final hasLinkedDocsAsync =
            ref.watch(clientHasLinkedDocumentsProvider(clientId));
        final hasLinkedDocs = hasLinkedDocsAsync.value ?? true;
        final isCheckingDocs = hasLinkedDocsAsync.isLoading;
        final canDelete = !hasLinkedDocs && !isCheckingDocs;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: colors.surface,
            foregroundColor: colors.onSurface,
            elevation: 0,
            title: Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                tooltip:
                    client.isArchived ? 'Desarchivar cliente' : 'Archivar cliente',
                icon: Icon(
                  client.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  color: colors.onSurface,
                ),
                onPressed: () async {
                  final actionName =
                      client.isArchived ? 'Desarchivar' : 'Archivar';
                  final actionMessage = client.isArchived
                      ? '¿Deseas desarchivar este cliente para que vuelva a mostrarse en los listados activos?'
                      : '¿Deseas archivar este cliente? Se ocultará de los listados y selectores de nuevos documentos.';

                  final confirm = await CustomDialog.show<bool>(
                    context: context,
                    dialog: CustomDialog.confirmation(
                      title: '$actionName Cliente',
                      contentText: actionMessage,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop(true),
                          child: Text(actionName),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (client.isArchived) {
                      await ref
                          .read(clientsProvider.notifier)
                          .unarchiveClient(client.id);
                      if (context.mounted) {
                        AppToast.success(
                          context,
                          message: 'Cliente desarchivado correctamente',
                        );
                      }
                    } else {
                      await ref
                          .read(clientsProvider.notifier)
                          .archiveClient(client.id);
                      if (context.mounted) {
                        AppToast.info(context, message: 'Cliente archivado');
                        context.pop();
                      }
                    }
                  }
                },
              ),
              Tooltip(
                message: canDelete
                    ? 'Eliminar cliente'
                    : 'No se puede eliminar: tiene cotizaciones asociadas',
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: canDelete
                        ? colors.onSurface
                        : colors.onSurface.withValues(alpha: 0.38),
                  ),
                  onPressed: canDelete
                      ? () async {
                          final confirm = await CustomDialog.show<bool>(
                            context: context,
                            dialog: CustomDialog.destructive(
                              title: 'Eliminar Cliente',
                              contentText:
                                  '¿Estás seguro de que deseas eliminar este cliente?',
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors.error,
                                  ),
                                  onPressed: () => Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop(true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ref
                                .read(clientsProvider.notifier)
                                .deleteClient(client.id);
                            if (context.mounted) context.pop();
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: FloatingActionButton(
              onPressed: () {
                // Pass IDs and let Edit Screen fetch fresh or pass full object
                // Passing ID is safer for consistency.
                if (isCompany) {
                  context.go('/clients/$clientId/edit-company', extra: client);
                } else {
                  context.go('/clients/$clientId/edit-person', extra: client);
                }
              },
              backgroundColor: colors.primaryContainer,
              child: Icon(Icons.edit, color: colors.onPrimaryContainer),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (client.isArchived)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Este cliente se encuentra archivado',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Top Action Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                            color: colors.outline.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () {
                          final encodedName = Uri.encodeComponent(client.name);
                          context.push(
                            '/quotes/search?clientId=${client.id}&clientName=$encodedName&readOnly=true',
                          );
                        },
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Cotizaciones'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                            color: colors.outline.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () {
                          AppToast.info(
                            context,
                            message:
                                'El módulo de reportes estará disponible próximamente.',
                            duration: const Duration(seconds: 2),
                          );
                        },
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: const Text('Reportes'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Content Padding Wrapper
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Fiscal Info Section
                      Text(
                        'Información fiscal',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (isCompany) ...[
                        InfoBlock.text(
                          icon: Icons.domain_outlined,
                          label: 'Razón Social',
                          value: client.name,
                        ),
                        const SizedBox(height: 24),
                        InfoBlock.text(
                          icon: Icons.badge_outlined,
                          label: 'RIF/NIF/RUT',
                          value: client.taxId ?? 'No registrado',
                        ),
                        const SizedBox(height: 24),
                        InfoBlock.text(
                          icon: Icons.location_on_outlined,
                          label: 'Dirección Fiscal',
                          value: fullAddress.isNotEmpty
                              ? fullAddress
                              : 'No registrada',
                        ),
                      ] else ...[
                        InfoBlock.text(
                          icon: Icons.person_outline,
                          label: 'Nombre y apellido',
                          value: client.name,
                        ),
                        const SizedBox(height: 24),
                        InfoBlock.text(
                          icon: Icons.badge_outlined,
                          label: 'Número de identificación',
                          value:
                              client.taxId ??
                              'No registrado', // Assuming taxId holds personal ID too
                        ),
                        const SizedBox(height: 24),
                        InfoBlock.text(
                          icon: Icons.location_on_outlined,
                          label: 'Dirección',
                          value: fullAddress.isNotEmpty
                              ? fullAddress
                              : 'Dirección no registrada',
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Contacts Section
                      Text(
                        isCompany ? 'Contactos' : 'Información de contacto',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (isCompany) ...[
                        ...client.contacts
                            .take(3)
                            .map(
                              (c) => ContactListTile(
                                name: c.name,
                                role: c.role ?? '',
                                initial: c.initial,
                                isPrimary: c.isPrimary,
                                onPhoneTap: () =>
                                    ContactUtils.makePhoneCall(c.phone),
                                onWhatsAppTap: () =>
                                    ContactUtils.launchWhatsApp(c.phone),
                                onTap: () {
                                  context.push(
                                    '/clients/$clientId/contacts/details',
                                    extra: {
                                      'companyName': client.name,
                                      'contact': c,
                                    }, // Pass contact object
                                  );
                                },
                              ),
                            ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              context.go(
                                '/clients/$clientId/contacts',
                                extra: {'name': client.name},
                              );
                            },
                            child: Text(
                              'Administrar contactos',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Person Contact Layout
                        InfoBlock.text(
                          icon: Icons.contact_phone_outlined,
                          label: 'Teléfono',
                          value: _formatPhone(client.phone),
                          action: IconButton(
                            onPressed: () {
                              if (client.phone != null &&
                                  client.phone!.isNotEmpty) {
                                Clipboard.setData(
                                  ClipboardData(text: client.phone!),
                                );
                                AppToast.info(
                                  context,
                                  message: 'Teléfono copiado',
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_outlined),
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        InfoBlock.text(
                          icon: Icons.alternate_email_outlined,
                          label: 'Correo Electrónico',
                          value: client.email ?? 'No registrado',
                          action: IconButton(
                            onPressed: () {
                              if (client.email != null &&
                                  client.email!.isNotEmpty) {
                                Clipboard.setData(
                                  ClipboardData(text: client.email!),
                                );
                                AppToast.info(
                                  context,
                                  message: 'Correo copiado',
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_outlined),
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'No registrado';
    // Remove any non-digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 5) {
      // 0414-XXXXXXX
      return '${digits.substring(0, 4)}-${digits.substring(4)}';
    }
    return phone;
  }
}
