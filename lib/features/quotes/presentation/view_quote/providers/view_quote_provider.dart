import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../collaborators/presentation/providers/collaborators_providers.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../../create_quote/providers/create_quote_provider.dart';

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
      notifier.loadExistingQuote(quoteId);

      return notifier;
    });
