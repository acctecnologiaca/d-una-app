import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/view_report_provider.dart';
import '../../create_report/widgets/report_added_service_card.dart';

class ViewReportServicesTab extends ConsumerWidget {
  final String reportId;
  const ViewReportServicesTab({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(viewReportProvider(reportId));

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (report) {
        final services = report.services ?? [];

        if (services.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.handyman_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay servicios o mano de obra en este reporte',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: services.length,
          padding: const EdgeInsets.only(top: 8, bottom: 120),
          itemBuilder: (context, index) {
            final s = services[index];
            return ReportAddedServiceCard(
              service: s,
              isReadOnly: true,
              onDelete: () {},
              onQuantityChanged: (_) {},
            );
          },
        );
      },
    );
  }
}
