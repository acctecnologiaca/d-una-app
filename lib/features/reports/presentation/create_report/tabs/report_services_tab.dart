import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/service_report_item_service.dart';
import '../providers/create_report_provider.dart';
import '../providers/report_service_selection_provider.dart';
import '../widgets/report_added_service_card.dart';
import '../widgets/report_service_sale_details_sheet.dart';

class ReportServicesTab extends ConsumerStatefulWidget {
  const ReportServicesTab({super.key});

  @override
  ConsumerState<ReportServicesTab> createState() => _ReportServicesTabState();
}

class _ReportServicesTabState extends ConsumerState<ReportServicesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(createReportProvider);
    final notifier = ref.read(createReportProvider.notifier);

    if (state.services.isEmpty) {
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
              'No hay servicios agregados',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final suggestionsAsync = ref.watch(reportServiceSuggestionsProvider);
    final serviceModels = suggestionsAsync.value ?? [];

    final services = [...state.services]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 120),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        final originalIndex = state.services.indexOf(service);
        final serviceModel = serviceModels
            .where((s) => s.id == service.serviceId)
            .firstOrNull;

        return ReportAddedServiceCard(
          service: service,
          isReadOnly: state.isReadOnly,
          onQuantityChanged: (newQty) {
            final newSubtotal = service.unitPrice * newQty;
            final taxAmount = newSubtotal * (service.taxRate / 100);
            final updated = service.copyWith(
              quantity: newQty,
              taxAmount: taxAmount,
              totalPrice: newSubtotal,
            );
            notifier.updateService(originalIndex, updated);
          },
          onDelete: () {
            notifier.removeService(originalIndex);
          },
          onEditSaleDetails: () async {
            final isTemporal = service.serviceId == null;
            if (isTemporal) {
              final updatedItem =
                  await context.push<ServiceReportItemService>(
                '/reports/create/select-service/temporal',
                extra: service,
              );
              if (updatedItem != null && mounted) {
                notifier.updateService(originalIndex, updatedItem);
              }
              return;
            }
            if (serviceModel == null) {
              return;
            }
            final result = await ReportServiceSaleDetailsSheet.show(
              context,
              service: serviceModel,
              existingItem: service,
            );
            if (result != null && mounted) {
              notifier.updateService(originalIndex, result);
            }
          },
        );
      },
    );
  }
}
