import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/repositories/quotes_repository.dart';
import '../../../data/repositories/supabase_quotes_repository.dart';
import '../../../data/repositories/quote_product_selection_repository.dart';
import '../../../domain/models/quote_model.dart' as domain;
// import '../../../data/models/quote.dart' as data;
import '../../../domain/models/quote_validation_result.dart';

final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  return SupabaseQuotesRepository(Supabase.instance.client);
});

final quoteProductSelectionRepositoryProvider =
    Provider<QuoteProductSelectionRepository>((ref) {
      return QuoteProductSelectionRepository(Supabase.instance.client);
    });

final quotesListProvider =
    AsyncNotifierProvider<QuotesListNotifier, List<domain.Quote>>(() {
      return QuotesListNotifier();
    });

class QuotesListNotifier extends AsyncNotifier<List<domain.Quote>> {
  @override
  Future<List<domain.Quote>> build() async {
    final repo = ref.watch(quotesRepositoryProvider);
    final validationRepo = ref.watch(quoteProductSelectionRepositoryProvider);

    // 1. Fetch Quotes (DTOs)
    final quotesDtos = await repo.getQuotes(includeArchived: false);

    if (quotesDtos.isEmpty) return [];

    // 2. Perform Batch Validation
    // Collect unique product IDs and supplier stock IDs
    final Set<String> supplierIds = {};
    final Set<String> ownProductIds = {};

    for (final q in quotesDtos) {
      if (q.products != null) {
        for (final p in q.products!) {
          if (p.supplierBranchStockId != null) {
            supplierIds.add(p.supplierBranchStockId!);
          } else if (p.productId != null) {
            ownProductIds.add(p.productId!);
          }
        }
      }
    }

    Map<String, QuoteValidationResult> validationMap = {};
    if (supplierIds.isNotEmpty || ownProductIds.isNotEmpty) {
      final results = await validationRepo.validateQuoteItems(
        supplierBranchStockIds: supplierIds.toList(),
        productIds: ownProductIds.toList(),
      );
      validationMap = {for (var r in results) r.itemId: r};
    }

    // 3. Map to Domain Entities
    return quotesDtos.map((dto) {
      // Determine Stock Status
      domain.StockStatus stockStatus = domain.StockStatus.available;

      if (dto.products != null && dto.products!.isNotEmpty) {
        for (final p in dto.products!) {
          final dbId = p.supplierBranchStockId ?? p.productId;
          final validation = validationMap[dbId];

          if (validation == null || validation.currentStock < p.quantity) {
            stockStatus = domain.StockStatus.unavailable;
            break;
          }
        }
      }

      return domain.Quote(
        id: dto.id,
        quoteNumber: dto.quoteNumber ?? 'S/N',
        clientName: dto.clientName ?? 'Cliente Desconocido',
        date: dto.dateIssued,
        amount: dto.total,
        status: _mapStatus(dto.status),
        stockStatus: stockStatus,
        categoryId: dto.categoryId,
        categoryName: dto.categoryName,
        isArchived: dto.isArchived,
        quoteTag: dto.quoteTag,
        createdAt: dto.createdAt,
      );
    }).toList();
  }

  domain.QuoteStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return domain.QuoteStatus.draft;
      case 'sent':
        return domain.QuoteStatus.sent;
      case 'resent':
        return domain.QuoteStatus.resent;
      case 'approved':
        return domain.QuoteStatus.approved;
      case 'rejected':
        return domain.QuoteStatus.rejected;
      case 'in_review':
        return domain.QuoteStatus.inReview;
      case 'finalized':
        return domain.QuoteStatus.finalized;
      case 'cancelled':
        return domain.QuoteStatus.cancelled;
      case 'expired':
        return domain.QuoteStatus.expired;
      default:
        return domain.QuoteStatus.draft;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> archiveQuote(String id) async {
    await ref.read(quotesRepositoryProvider).archiveQuote(id, true);
    await refresh();
  }
}
