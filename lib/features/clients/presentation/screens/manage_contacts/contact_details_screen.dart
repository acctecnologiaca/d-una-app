import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';

class ContactDetailsScreen extends ConsumerWidget {
  final String clientId;
  final String? companyName;
  final Contact contact;
  final int? contactCount;

  const ContactDetailsScreen({
    super.key,
    required this.clientId,
    this.companyName,
    required this.contact,
    this.contactCount,
  });

  Future<void> _deleteContact(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar contacto'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este contacto? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
        // Show loading indicator or simple UI block could be better,
        // but for now we'll just fire and pop.
        // Ideally we should wait, but `deleteContact` in provider is void async
        // and updates state.

        try {
          await ref.read(clientsProvider.notifier).deleteContact(contact.id);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Contacto eliminado')));
            context.pop(); // Pop details
            // context.pop(); // Pop manage list? No, usually list updates via provider check.
            // Actually, we just pop the details screen, returning to ManageContactsScreen
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final name = contact.name;
    final role = contact.role ?? 'Sin cargo';
    final phone = contact.phone ?? 'No registrado';
    final email = contact.email ?? '';
    final department =
        contact.department ??
        'Tecnología de la Información'; // Mock default from image
    final isPrimary = contact.isPrimary;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Detalles del contacto',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
            if (companyName != null)
              Text(
                companyName!,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: (contactCount != null && contactCount! > 1)
                ? () => _deleteContact(context, ref)
                : null,
            icon: const Icon(Icons.delete_outline),
            tooltip: (contactCount != null && contactCount! > 1)
                ? 'Eliminar contacto'
                : 'No se puede eliminar el único contacto',
          ),
        ],
        foregroundColor: colors.onSurface,
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: FloatingActionButton(
          onPressed: () {
            context.go(
              '/clients/$clientId/contacts/edit',
              extra: {
                'companyName': companyName,
                'contact': contact,
                'contactCount': contactCount,
              },
            );
          },
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.edit_outlined),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Section
            InfoBlock(
              icon: Icons.person_outline,
              label: 'Nombre y apellido',
              content: Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        color: colors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isPrimary) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'P',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Phone Section
            InfoBlock.text(
              icon: Icons.contact_phone_outlined,
              label: 'Teléfono',
              value: _formatPhone(phone),
              action: IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teléfono copiado')),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Email Section
            InfoBlock.text(
              icon: Icons.alternate_email,
              label: 'Correo Electrónico',
              value: email,
              action: IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: email));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correo copiado')),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Role Section
            InfoBlock.text(
              icon: Icons.manage_accounts_outlined,
              label: 'Cargo',
              value: role,
            ),
            const SizedBox(height: 24),

            // Department Section
            InfoBlock.text(
              icon: Icons.domain_outlined,
              label: 'Departamento',
              value: department,
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
