import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../collaborators/presentation/providers/collaborators_providers.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../../create_quote/providers/create_quote_provider.dart';

import 'package:d_una_app/features/supplier_orders/domain/models/supplier_order.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart';

final viewQuoteProvider = StateNotifierProvider.autoDispose
    .family<CreateQuoteNotifier, QuoteState, String>((ref, quoteId) {
      final repository = ref.watch(quotesRepositoryProvider);
      final collaboratorsRepository = ref.watch(
        collaboratorsRepositoryProvider,
      );
      final lookupRepository = ref.watch(lookupRepositoryProvider);

      final notifier = CreateQuoteNotifier(
        repository,
        ref,
        collaboratorsRepository: collaboratorsRepository,
        lookupRepository: lookupRepository,
      );

      // Trigger the load
      notifier.loadFinancialParameters().then((_) {
        notifier.loadExistingQuote(quoteId);
      });

      return notifier;
    });

final linkedSupplierOrdersProvider = FutureProvider.autoDispose
    .family<List<SupplierOrder>, String>((ref, quoteId) async {
  final repo = ref.watch(supplierOrdersRepositoryProvider);
  return repo.getSupplierOrdersByQuoteId(quoteId);
});

final quoteActiveFabsCountProvider = Provider.autoDispose
    .family<int, String>((ref, quoteId) {
  final quote = ref.watch(viewQuoteProvider(quoteId)).quote;
  if (quote == null) return 0;
  final currentStatus = quote.status;
  final showWhatsAppFab = currentStatus == QuoteStatus.sent.dbValue ||
      currentStatus == QuoteStatus.resent.dbValue ||
      currentStatus == QuoteStatus.inReview.dbValue ||
      currentStatus == QuoteStatus.opened.dbValue ||
      currentStatus == QuoteStatus.approved.dbValue;
  final canEdit = currentStatus != QuoteStatus.finalized.dbValue;
  return (showWhatsAppFab ? 1 : 0) + (canEdit ? 1 : 0);
});
