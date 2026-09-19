import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/info_block.dart';
import '../../../../clients/presentation/widgets/contact_list_tile.dart';
import '../../../../../core/utils/contact_utils.dart';
import '../providers/view_report_provider.dart';
import '../../../domain/models/service_report_model.dart';
import '../../../../../shared/utils/fab_scroll_padding.dart';

class ViewReportDetailsTab extends ConsumerWidget {
  final String reportId;
  const ViewReportDetailsTab({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reportAsync = ref.watch(viewReportProvider(reportId));

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (report) {
        final dateFormat = DateFormat('dd/MM/yyyy');
        final intervention = InterventionType.fromDbValue(
          report.interventionType,
        );

        final isCompany = report.clientType == 'company';
        final fullAddress = [
          report.clientAddress,
          report.clientCity,
          report.clientState,
          report.clientCountry,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        final hasAdditionalInfo =
            (report.recommendations != null &&
                report.recommendations!.trim().isNotEmpty) ||
            (report.notes != null && report.notes!.trim().isNotEmpty) ||
            (report.reportTag != null && report.reportTag!.trim().isNotEmpty);

        final isFinalized =
            report.status == ServiceReportStatus.finalized.dbValue;
        final bottomPadding = isFinalized
            ? FabScrollPadding.none
            : FabScrollPadding.single;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cliente y Contacto
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
                  value: report.clientName ?? 'No registrado',
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.badge_outlined,
                  label: 'RIF / Identificación Fiscal',
                  value: report.clientTaxId ?? 'No registrado',
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.location_on_outlined,
                  label: 'Dirección Fiscal',
                  value: fullAddress.isNotEmpty ? fullAddress : 'No registrada',
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.location_on_outlined,
                  label: 'Dirección Fiscal',
                  value: fullAddress.isNotEmpty ? fullAddress : 'No registrada',
                ),
                const SizedBox(height: 24),
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
              const SizedBox(height: 32),

              // 2. Tipo de servicio y categoría
              Text(
                'Tipo de servicio y categoría',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: intervention.icon,
                label: 'Tipo de servicio',
                value: intervention.label,
              ),
              const SizedBox(height: 24),

              if (report.categoryName != null &&
                  report.categoryName!.trim().isNotEmpty) ...[
                InfoBlock.text(
                  icon: Icons.category_outlined,
                  label: 'Categoría',
                  value: report.categoryName!,
                ),
                const SizedBox(height: 24),
              ],

              // 3. Horario y técnicos
              Text(
                'Horario y técnicos',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.calendar_today_outlined,
                label: 'Fecha de servicio',
                value: dateFormat.format(report.serviceDate.toLocal()),
              ),
              const SizedBox(height: 24),

              if (report.startTime != null || report.endTime != null) ...[
                InfoBlock.text(
                  icon: Icons.access_time_outlined,
                  label: 'Horario',
                  value:
                      '${report.startTime ?? "--"} - ${report.endTime ?? "--"}',
                ),
                const SizedBox(height: 24),
              ],

              if (report.durationMinutes != null &&
                  report.durationMinutes! > 0) ...[
                InfoBlock.text(
                  icon: Icons.timer_outlined,
                  label: 'Duración',
                  value:
                      '${report.durationMinutes! ~/ 60}h ${report.durationMinutes! % 60}m',
                ),
                const SizedBox(height: 24),
              ],

              if (report.advisorName != null &&
                  report.advisorName!.trim().isNotEmpty) ...[
                InfoBlock.text(
                  icon: Icons.badge_outlined,
                  label: 'Técnicos responsables',
                  value: report.advisorName!,
                ),
                const SizedBox(height: 24),
              ],

              // 4. Trabajo técnico
              Text(
                'Informe técnico',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.assignment_outlined,
                label: 'Requerimiento o falla reportada',
                value:
                    (report.requestDescription != null &&
                        report.requestDescription!.trim().isNotEmpty)
                    ? report.requestDescription!
                    : 'Sin descripción',
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.build_circle_outlined,
                label: 'Diagnóstico y/o trabajo realizado',
                value:
                    (report.workDescription != null &&
                        report.workDescription!.trim().isNotEmpty)
                    ? report.workDescription!
                    : 'Sin detalle de trabajo realizado',
              ),
              const SizedBox(height: 24),

              if (report.recommendations != null &&
                  report.recommendations!.trim().isNotEmpty) ...[
                InfoBlock.text(
                  icon: Icons.lightbulb_outline,
                  label: 'Recomendaciones',
                  value: report.recommendations!,
                ),
                const SizedBox(height: 24),
              ],

              // 5. Información adicional
              if (hasAdditionalInfo) ...[
                Text(
                  'Información adicional',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 24),

                if (report.reportTag != null &&
                    report.reportTag!.trim().isNotEmpty) ...[
                  InfoBlock.text(
                    icon: Icons.label_outline,
                    label: 'Etiqueta',
                    value: report.reportTag!,
                  ),
                  const SizedBox(height: 24),
                ],

                if (report.notes != null &&
                    report.notes!.trim().isNotEmpty) ...[
                  Text(
                    'Notas internas',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Text(
                      report.notes!,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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
