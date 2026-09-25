import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/shared/utils/fab_scroll_padding.dart';

class ContactDetailsScreen extends ConsumerWidget {
  final String clientId;
  final String? companyName;
  final Contact contact;
  final int? contactCount;
  final bool canEdit;

  const ContactDetailsScreen({
    super.key,
    required this.clientId,
    this.companyName,
    required this.contact,
    this.contactCount,
    this.canEdit = true,
  });

  Future<void> _deleteContact(BuildContext context, WidgetRef ref) async {
    final colors = Theme.of(context).colorScheme;
    final confirmed = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.destructive(
        title: 'Eliminar contacto',
        contentText:
            '¿Estás seguro de que deseas eliminar este contacto? Esta acción no se puede deshacer.',
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
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
            context.pop(); // Pop details
            AppToast.success(
              context,
              message: 'Contacto eliminado',
            );
          }
        } catch (e) {
          if (context.mounted) {
            AppToast.error(
              context,
              message: 'Error al eliminar: $e',
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Watch linked documents status for this contact
    final contactLinkedDocsAsync =
        ref.watch(contactHasLinkedDocumentsProvider(contact.id));
    final hasLinkedDocs =
        contactLinkedDocsAsync.value ?? true; // default true while loading
    final isCheckingDocs = contactLinkedDocsAsync.isLoading;

    // --- Delete logic ---
    final isLastContact = contactCount != null && contactCount! <= 1;
    final canDelete =
        canEdit && !isLastContact && !hasLinkedDocs && !isCheckingDocs;

    String deleteTooltip;
    if (isLastContact) {
      deleteTooltip = 'No se puede eliminar el único contacto';
    } else if (hasLinkedDocs) {
      deleteTooltip = 'No se puede eliminar: tiene documentos asociados';
    } else {
      deleteTooltip = 'Eliminar contacto';
    }

    final name = contact.name.trim();
    final phone = contact.phone?.trim();
    final email = contact.email?.trim();
    final role = contact.role?.trim();
    final department = contact.department?.trim();
    final isPrimary = contact.isPrimary;

    final hasPhone = phone != null && phone.isNotEmpty;
    final hasEmail = email != null && email.isNotEmpty;
    final hasRole = role != null && role.isNotEmpty;
    final hasDepartment = department != null && department.isNotEmpty;

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
          if (canEdit)
            IconButton(
              onPressed: canDelete ? () => _deleteContact(context, ref) : null,
              icon: const Icon(Icons.delete_outline),
              tooltip: deleteTooltip,
            ),
        ],
        foregroundColor: colors.onSurface,
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
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
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, FabScrollPadding.single),
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

            if (hasPhone) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.contact_phone_outlined,
                label: 'Teléfono',
                value: _formatPhone(phone),
                action: IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: phone));
                    AppToast.info(
                      context,
                      message: 'Teléfono copiado',
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],

            if (hasEmail) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.alternate_email,
                label: 'Correo Electrónico',
                value: email,
                action: IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: email));
                    AppToast.info(
                      context,
                      message: 'Correo copiado',
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],

            if (hasRole) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.manage_accounts_outlined,
                label: 'Cargo',
                value: role,
              ),
            ],

            if (hasDepartment) ...[
              const SizedBox(height: 24),
              InfoBlock.text(
                icon: Icons.domain_outlined,
                label: 'Departamento',
                value: department,
              ),
            ],
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
