import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/view_report_provider.dart';
import '../../create_report/widgets/report_added_product_card.dart';

class ViewReportProductsTab extends ConsumerWidget {
  final String reportId;
  const ViewReportProductsTab({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(viewReportProvider(reportId));

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (report) {
        final products = report.products ?? [];

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay materiales o repuestos en este reporte',
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
          itemCount: products.length,
          padding: const EdgeInsets.only(top: 8, bottom: 120),
          itemBuilder: (context, index) {
            final p = products[index];
            return ReportAddedProductCard(
              product: p,
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
