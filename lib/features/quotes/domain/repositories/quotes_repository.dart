import 'package:flutter/material.dart';
import '../../data/models/quote.dart';
import '../../data/models/delivery_time.dart';
import '../../data/models/commercial_condition.dart';
import '../../data/models/financial_parameter.dart';
import '../../data/models/quote_item_product.dart';
import '../../data/models/quote_item_service.dart';
import '../models/batch_update_result.dart';
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
  
  Future<List<Quote>> getQuotesPaginated({
    required int offset,
    int limit = 25,
    String orderBy = 'date_issued',
    bool ascending = false,
    String? searchQuery,
    String? statusFilter,
    String? categoryFilter,
    DateTimeRange? dateRange,
    bool includeArchived = false,
    String? productId,
    String? clientId,
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
  Future<Quote> updateQuote(
    Quote quote, {
    List<QuoteItemProduct>? products,
    List<QuoteItemService>? services,
    List<QuoteCondition>? conditions,
  });
  Future<void> updateQuoteStatus(String id, String status);
  Future<void> updateQuoteDate(String id, DateTime newDate);
  Future<void> archiveQuote(String id, bool isArchived);
  Future<void> deleteQuote(String id);

  // Batch Operations
  Future<BatchUpdateResult> batchUpdateStatus(List<String> ids, String status);
  Future<void> batchArchive(List<String> ids, bool isArchived);

  // PDF Storage & WebViewer Actions
  Future<String> uploadQuotePdf({
    required String quoteId,
    required List<int> pdfBytes,
    required String fileName,
  });
  Future<String> generateActionToken(String quoteId);
}

class InsufficientStockException implements Exception {
  final List<String> productNames;
  InsufficientStockException(this.productNames);

  @override
  String toString() =>
      'Stock insuficiente para los siguientes productos del inventario propio: ${productNames.join(', ')}';
}
