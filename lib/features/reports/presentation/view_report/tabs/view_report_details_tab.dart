import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/widgets/info_block.dart';
import '../providers/view_report_provider.dart';
import '../../../domain/models/service_report_model.dart';

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

        final hasAdditionalInfo =
            (report.recommendations != null &&
                report.recommendations!.trim().isNotEmpty) ||
            (report.notes != null && report.notes!.trim().isNotEmpty) ||
            (report.reportTag != null && report.reportTag!.trim().isNotEmpty);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tipo de servicio y categoría
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

              // 2. Horario y técnicos
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

              // 3. Trabajo técnico
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

              // 4. Información adicional
              if (hasAdditionalInfo) ...[
                Text(
                  'Información adicional',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 24),

                if (report.notes != null &&
                    report.notes!.trim().isNotEmpty) ...[
                  InfoBlock.text(
                    icon: Icons.notes,
                    label: 'Notas internas',
                    value: report.notes!,
                  ),
                  const SizedBox(height: 24),
                ],

                if (report.reportTag != null &&
                    report.reportTag!.trim().isNotEmpty) ...[
                  InfoBlock.text(
                    icon: Icons.label_outline,
                    label: 'Etiqueta del reporte',
                    value: report.reportTag!,
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
}
