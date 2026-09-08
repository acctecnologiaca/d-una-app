import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:d_una_app/core/utils/contact_utils.dart';
import 'package:d_una_app/features/clients/presentation/widgets/contact_list_tile.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';

class ViewDeliveryNoteClientTab extends ConsumerWidget {
  final String noteId;
  final double bottomPadding;

  const ViewDeliveryNoteClientTab({
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
      error: (e, _) =>
          Center(child: Text('Error al cargar datos del cliente: $e')),
      data: (note) {
        if (note == null) {
          return const Center(
            child: Text('No se encontró la información de la nota de entrega'),
          );
        }

        final isCompany =
            note.clientType == null || note.clientType == 'company';
        final fullAddress = [
          note.clientAddress,
          note.clientCity,
          note.clientState,
          note.clientCountry,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
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
              ],

              const SizedBox(height: 32),

              // Contact Info Section
              Text(
                isCompany ? 'Contacto' : 'Información de contacto',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              if (isCompany) ...[
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
