import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:d_una_app/features/clients/presentation/widgets/contact_list_tile.dart';
import 'package:d_una_app/core/utils/contact_utils.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';

class ViewDeliveryNoteDetailsTab extends ConsumerWidget {
  final String noteId;
  final double bottomPadding;

  const ViewDeliveryNoteDetailsTab({
    super.key,
    required this.noteId,
    this.bottomPadding = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final noteAsync = ref.watch(deliveryNoteDetailProvider(noteId));

    return noteAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error al cargar detalles: $e'),
      ),
      data: (note) {
        if (note == null) {
          return const Center(
            child: Text('No se encontró la información de la nota de entrega'),
          );
        }

        final dateFormat = DateFormat('dd/MM/yyyy');
        final isCompany =
            note.clientType == null || note.clientType == 'company';
        final fullAddress = [
          note.clientAddress,
          note.clientCity,
          note.clientState,
          note.clientCountry,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        final hasLinkedDoc =
            (note.quoteId != null && note.quoteId!.isNotEmpty) ||
            (note.supplierOrderId != null && note.supplierOrderId!.isNotEmpty);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Sección Cliente y Contacto
              Text(
                isCompany ? 'Cliente y Contacto' : 'Datos del Cliente',
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
                  value: note.clientName,
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.badge_outlined,
                  label: 'RIF/NIF/RUT',
                  value: note.clientTaxId ?? 'No registrado',
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.location_on_outlined,
                  label: 'Dirección Fiscal',
                  value: fullAddress.isNotEmpty ? fullAddress : 'No registrada',
                ),
                const SizedBox(height: 24),
                if (note.contact != null)
                  ContactListTile(
                    name: note.contact!.name,
                    role: note.contact!.role ?? '',
                    initial: note.contact!.initial,
                    isPrimary: note.contact!.isPrimary,
                    onPhoneTap: () =>
                        ContactUtils.makePhoneCall(note.contact!.phone),
                    onWhatsAppTap: () =>
                        ContactUtils.launchWhatsApp(note.contact!.phone),
                    onTap: () {
                      context.push(
                        '/clients/${note.clientId}/contacts/details',
                        extra: {
                          'companyName': note.clientName,
                          'contact': note.contact,
                          'canEdit': false,
                        },
                      );
                    },
                  )
                else if (note.contactName != null &&
                    note.contactName!.trim().isNotEmpty)
                  ContactListTile(
                    name: note.contactName!,
                    role: note.contactPhone ?? '',
                    initial: note.contactName!.trim().isNotEmpty
                        ? note.contactName!.trim()[0].toUpperCase()
                        : 'C',
                    isPrimary: false,
                    onPhoneTap:
                        note.contactPhone != null &&
                            note.contactPhone!.isNotEmpty
                        ? () => ContactUtils.makePhoneCall(note.contactPhone)
                        : null,
                    onWhatsAppTap:
                        note.contactPhone != null &&
                            note.contactPhone!.isNotEmpty
                        ? () => ContactUtils.launchWhatsApp(note.contactPhone)
                        : null,
                  )
                else
                  InfoBlock.text(
                    icon: Icons.person_outline,
                    label: 'Persona de contacto',
                    value: 'No especificado',
                  ),
              ] else ...[
                InfoBlock.text(
                  icon: Icons.person_outline,
                  label: 'Nombre y apellido',
                  value: note.clientName,
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.badge_outlined,
                  label: 'Número de identificación',
                  value: note.clientTaxId ?? 'No registrado',
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.location_on_outlined,
                  label: 'Dirección',
                  value: fullAddress.isNotEmpty
                      ? fullAddress
                      : 'Dirección no registrada',
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.contact_phone_outlined,
                  label: 'Teléfono',
                  value: _formatPhone(note.clientPhone),
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.alternate_email_outlined,
                  label: 'Correo Electrónico',
                  value: note.clientEmail ?? 'No registrado',
                ),
              ],

              const SizedBox(height: 32),

              // 2. Sección Emisión y referencias
              Text(
                'Emisión y referencias',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.calendar_today_outlined,
                label: 'Fecha de Emisión',
                value: dateFormat.format(note.date),
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.shopping_cart_outlined,
                label: 'Orden de Compra del Cliente (O/C)',
                value: note.clientPoNumber ?? 'No especificada',
              ),
              const SizedBox(height: 24),

              if (hasLinkedDoc) ...[
                if (note.quoteId != null && note.quoteId!.isNotEmpty) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    color: colors.surface,
                    child: ListTile(
                      leading: Icon(
                        Icons.description_outlined,
                        color: colors.primary,
                      ),
                      title: const Text(
                        'Cotización vinculada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${note.quoteId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/quotes/view/${note.quoteId}'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (note.supplierOrderId != null &&
                    note.supplierOrderId!.isNotEmpty) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colors.outlineVariant),
                    ),
                    color: colors.surface,
                    child: ListTile(
                      leading: Icon(
                        Icons.shopping_bag_outlined,
                        color: colors.primary,
                      ),
                      title: const Text(
                        'Orden de Compra vinculada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${note.supplierOrderId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        '/supplier-orders/view/${note.supplierOrderId}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],

              InfoBlock.text(
                icon: Icons.tag,
                label: 'Etiqueta',
                value: note.tag ?? 'Sin etiqueta',
              ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'No registrado';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 5) {
      return '${digits.substring(0, 4)}-${digits.substring(4)}';
    }
    return phone;
  }
}
