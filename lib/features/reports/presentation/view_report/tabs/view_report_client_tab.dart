import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/info_block.dart';
import '../../../../clients/presentation/widgets/contact_list_tile.dart';
import '../../../../../core/utils/contact_utils.dart';
import '../providers/view_report_provider.dart';

class ViewReportClientTab extends ConsumerWidget {
  final String reportId;
  const ViewReportClientTab({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reportAsync = ref.watch(viewReportProvider(reportId));

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (report) {
        final isCompany = report.clientType == 'company';
        final fullAddress = [
          report.clientAddress,
          report.clientCity,
          report.clientState,
          report.clientCountry,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
                  value: report.clientName ?? 'No registrado',
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.badge_outlined,
                  label: 'RIF / Identificación Fiscal',
                  value: report.clientTaxId ?? 'No registrado',
                ),
              ] else ...[
                InfoBlock.text(
                  icon: Icons.person_outline,
                  label: 'Nombre o Razón Social',
                  value: report.clientName ?? 'No registrado',
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.badge_outlined,
                  label: 'Cédula / Identificación Fiscal',
                  value: report.clientTaxId ?? 'No registrado',
                ),
              ],
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.location_on_outlined,
                label: 'Dirección Fiscal',
                value: fullAddress.isNotEmpty ? fullAddress : 'No registrada',
              ),
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
                if (report.contact != null)
                  ContactListTile(
                    name: report.contact!.name,
                    role: report.contact!.role ?? '',
                    initial: report.contact!.initial,
                    isPrimary: report.contact!.isPrimary,
                    onPhoneTap: () =>
                        ContactUtils.makePhoneCall(report.contact!.phone),
                    onWhatsAppTap: () =>
                        ContactUtils.launchWhatsApp(report.contact!.phone),
                    onTap: () {
                      context.push(
                        '/clients/${report.clientId}/contacts/details',
                        extra: {
                          'companyName': report.clientName,
                          'contact': report.contact,
                          'canEdit': false,
                        },
                      );
                    },
                  )
                else
                  InfoBlock.text(
                    icon: Icons.person_outline,
                    label: 'Persona de contacto',
                    value: report.contactName ?? 'No especificado',
                  ),
              ] else ...[
                InfoBlock.text(
                  icon: Icons.contact_phone_outlined,
                  label: 'Teléfono',
                  value: _formatPhone(report.clientPhone),
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.alternate_email_outlined,
                  label: 'Correo Electrónico',
                  value: report.clientEmail ?? 'No registrado',
                ),
              ],
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
