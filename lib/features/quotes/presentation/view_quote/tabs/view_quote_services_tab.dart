import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/view_quote_provider.dart';
import '../../create_quote/widgets/quote_added_service_card.dart';
import '../../create_quote/providers/quote_service_selection_provider.dart';
import '../widgets/view_service_details_sheet.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';

class ViewQuoteServicesTab extends ConsumerWidget {
  final String quoteId;
  const ViewQuoteServicesTab({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(viewQuoteProvider(quoteId));

    if (state.isLoading && state.quote == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
              'No hay servicios en esta cotización',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final suggestionsAsync = ref.watch(quoteServiceSuggestionsProvider);
    final serviceModels = suggestionsAsync.value ?? [];
    final executionTimes = ref.watch(deliveryTimesProvider).valueOrNull ?? [];

    final services = [...state.services]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return ListView.builder(
      itemCount: services.length,
      padding: const EdgeInsets.only(bottom: 120),
      itemBuilder: (context, index) {
        final item = services[index];

        final serviceModel = serviceModels
            .where((s) => s.id == item.serviceId)
            .firstOrNull;
        final categoryName = item.categoryName ?? serviceModel?.category?.name;
        final executionTimeLabel =
            item.executionTimeLabel ??
            executionTimes
                .where((e) => e.id == item.executionTimeId)
                .map((e) => e.name)
                .firstOrNull;

        return QuoteAddedServiceCard(
          name: item.name,
          category: categoryName,
          subtotal: item.unitPrice,
          quantity: item.quantity,
          rateSuffix: item.rateSymbol,
          executionTimeLabel: executionTimeLabel,
          rateIconName: item.rateIconName,
          isTemporal: item.serviceId == null,
          isReadOnly: true,
          onTap: () {
            ViewServiceDetailsSheet.show(
              context,
              serviceName: item.name,
              category: categoryName,
              salePrice: item.unitPrice,
              rateSuffix: item.rateSymbol,
              executionTimeLabel: executionTimeLabel,
              isExternal: item.costPrice > 0,
              externalCost: item.costPrice > 0 ? item.costPrice : null,
              quantity: item.quantity,
              rateIconName: item.rateIconName,
              isTemporal: item.serviceId == null,
              warrantyDisplay: item.warrantyDisplay,
            );
          },
          onDelete: () {},
          onEditSaleDetails: () {},
          onQuantityChanged: (_) {},
        );
      },
    );
  }
}
