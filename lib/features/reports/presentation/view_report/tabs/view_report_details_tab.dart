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
        final intervention =
            InterventionType.fromDbValue(report.interventionType);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Información técnica',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.numbers,
                label: 'Número de Reporte',
                value: report.reportNumber ?? 'RS-PENDIENTE',
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: intervention.icon,
                label: 'Tipo de Intervención',
                value: intervention.label,
              ),
              const SizedBox(height: 24),

              if (report.categoryName != null) ...[
                InfoBlock.text(
                  icon: Icons.category_outlined,
                  label: 'Categoría',
                  value: report.categoryName!,
                ),
                const SizedBox(height: 24),
              ],

              if (report.advisorName != null) ...[
                InfoBlock.text(
                  icon: Icons.person_outline,
                  label: 'Técnico Asignado',
                  value: report.advisorName!,
                ),
                const SizedBox(height: 24),
              ],

              InfoBlock.text(
                icon: Icons.calendar_today_outlined,
                label: 'Fecha de Servicio',
                value: dateFormat.format(report.serviceDate),
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
                  label: 'Duración Estimada',
                  value:
                      '${report.durationMinutes! ~/ 60}h ${report.durationMinutes! % 60}m',
                ),
                const SizedBox(height: 24),
              ],

              if (report.reportTag != null &&
                  report.reportTag!.isNotEmpty) ...[
                InfoBlock.text(
                  icon: Icons.label_outline,
                  label: 'Etiqueta del Reporte',
                  value: report.reportTag!,
                ),
                const SizedBox(height: 24),
              ],

              Text(
                'Descripción del servicio',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.assignment_outlined,
                label: 'Solicitud del Cliente',
                value: (report.requestDescription != null &&
                        report.requestDescription!.isNotEmpty)
                    ? report.requestDescription!
                    : 'Sin descripción de solicitud',
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.build_circle_outlined,
                label: 'Diagnóstico y Trabajo Realizado',
                value: (report.workDescription != null &&
                        report.workDescription!.isNotEmpty)
                    ? report.workDescription!
                    : 'Sin detalle de trabajo realizado',
              ),
              const SizedBox(height: 24),

              if (report.recommendations != null &&
                  report.recommendations!.isNotEmpty) ...[
                InfoBlock.text(
                  icon: Icons.lightbulb_outline,
                  label: 'Recomendaciones y Observaciones',
                  value: report.recommendations!,
                ),
                const SizedBox(height: 24),
              ],

              if (report.notes != null && report.notes!.isNotEmpty) ...[
                InfoBlock.text(
                  icon: Icons.notes,
                  label: 'Notas Internas',
                  value: report.notes!,
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}
