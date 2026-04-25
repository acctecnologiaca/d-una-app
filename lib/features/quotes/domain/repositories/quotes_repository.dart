import '../../data/models/quote.dart';
import '../../data/models/delivery_time.dart';
import '../../data/models/commercial_condition.dart';
import '../../data/models/financial_parameter.dart';
import '../../data/models/quote_item_product.dart';
import '../../data/models/quote_item_service.dart';
import '../../data/models/quote_condition.dart';

abstract class QuotesRepository {
  // Auxiliary Data
  Future<List<DeliveryTime>> getDeliveryTimes();
  Future<List<CommercialCondition>> getCommercialConditions();
  Future<FinancialParameter> getFinancialParameters();
  Future<void> updateFinancialParameters(FinancialParameter params);

  // Quote CRUD
  Future<List<Quote>> getQuotes({
    String? status,
    String? clientId,
    bool includeArchived = false,
  });
  Future<Quote> getQuoteById(String id);
  Future<Quote> getQuoteWithDetails(String id);
  Future<String?> getLastQuoteNumber();
  Future<Quote> createQuote(
    Quote quote, {
    List<QuoteItemProduct>? products,
    List<QuoteItemService>? services,
    List<QuoteCondition>? conditions,
  });
  Future<void> updateQuoteStatus(String id, String status);
  Future<void> archiveQuote(String id, bool isArchived);
  Future<void> deleteQuote(String id);
}
