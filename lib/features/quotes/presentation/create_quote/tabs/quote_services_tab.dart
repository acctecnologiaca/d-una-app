import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/create_quote_provider.dart';
import '../providers/quote_service_selection_provider.dart';
import '../widgets/quote_added_service_card.dart';
import '../widgets/quote_service_sale_details_sheet.dart';

class QuoteServicesTab extends ConsumerStatefulWidget {
  const QuoteServicesTab({super.key});

  @override
  ConsumerState<QuoteServicesTab> createState() => _QuoteServicesTabState();
}

class _QuoteServicesTabState extends ConsumerState<QuoteServicesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(createQuoteProvider);

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

    final suggestionsAsync = ref.watch(quoteServiceSuggestionsProvider);
    final serviceModels = suggestionsAsync.value ?? [];
    final executionTimes =
        ref.watch(deliveryTimesForExecutionProvider).valueOrNull ?? [];

    return ListView.builder(
      itemCount: state.services.length,
      itemBuilder: (context, index) {
        final serviceItem = state.services[index];
        final serviceModel = serviceModels
            .where((s) => s.id == serviceItem.serviceId)
            .firstOrNull;
        final categoryName = serviceModel?.category?.name;
        final executionTimeLabel = executionTimes
            .where((e) => e.id == serviceItem.executionTimeId)
            .map((e) => e.name)
            .firstOrNull;

        String rateSuffix;
        String? rateIconName;

        if (serviceModel == null) {
          // Temporal service: use stored symbol directly
          rateSuffix = '/${serviceItem.rateSymbol}';
          rateIconName = serviceItem.rateIconName;
        } else {
          rateSuffix = '/${serviceModel.serviceRate?.symbol ?? 'ud.'}';
          rateIconName =
              serviceModel.serviceRate?.iconName ?? serviceItem.rateIconName;
        }

        return QuoteAddedServiceCard(
          name: serviceItem.name,
          category: categoryName,
          subtotal: serviceItem.unitPrice,
          quantity: serviceItem.quantity,
          rateSuffix: rateSuffix,
          rateIconName: rateIconName,
          executionTimeLabel: executionTimeLabel,
          isTemporal: serviceItem.serviceId == null,
          onDelete: () {
            ref
                .read(createQuoteProvider.notifier)
                .removeService(serviceItem.id);
          },
          onEditSaleDetails: () async {
            final isTemporal = serviceItem.serviceId == null;
            if (isTemporal) {
              final result = await context.push<bool>(
                '/quotes/create/select-service/temporal-service',
                extra: serviceItem,
              );
              if (result == true && mounted) {
                setState(() {});
              }
              return;
            }
            if (serviceModel == null) {
              return; // Cannot edit without full model yet
            }
            final result = await QuoteServiceSaleDetailsSheet.show(
              context,
              service: serviceModel,
              existingItem: serviceItem,
            );
            if (result != null) {
              ref
                  .read(createQuoteProvider.notifier)
                  .updateServiceDetails(result);
            }
          },
          onQuantityChanged: (newQty) {
            ref
                .read(createQuoteProvider.notifier)
                .updateServiceQuantity(serviceItem.id, newQty);
          },
        );
      },
    );
  }
}
