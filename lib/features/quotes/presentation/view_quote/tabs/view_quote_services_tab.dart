import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/view_quote_provider.dart';
import '../../create_quote/widgets/quote_added_service_card.dart';

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
              Symbols.rebase_edit,
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

    return ListView.builder(
      itemCount: state.services.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final item = state.services[index];

        return QuoteAddedServiceCard(
          name: item.name,
          category: null, // Model doesn't have category snapshot currently
          subtotal: item.unitPrice,
          quantity: item.quantity,
          rateSuffix: item.rateSymbol,
          executionTimeLabel: null, // Model doesn't have execution time snapshot
          rateIconName: item.rateIconName,
          isTemporal: item.serviceId == null,
          isReadOnly: true,
          onDelete: () {},
          onEditSaleDetails: () {},
          onQuantityChanged: (_) {},
        );
      },
    );
  }
}
