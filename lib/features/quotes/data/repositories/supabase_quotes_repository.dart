
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/quotes_repository.dart';
import '../../data/models/quote.dart';
import '../../data/models/delivery_time.dart';
import '../../data/models/commercial_condition.dart';
import '../../data/models/collaborator.dart';
import '../../data/models/financial_parameter.dart';
import '../../data/models/quote_item_product.dart';
import '../../data/models/quote_item_service.dart';
import '../../data/models/quote_condition.dart';

class SupabaseQuotesRepository implements QuotesRepository {
  final SupabaseClient _client;

  SupabaseQuotesRepository(this._client);

  @override
  Future<List<DeliveryTime>> getDeliveryTimes() async {
    final response = await _client
        .from('delivery_times')
        .select()
        .eq('is_active', true)
        .order('name');
    
    return (response as List).map((e) => DeliveryTime.fromJson(e)).toList();
  }

  @override
  Future<List<CommercialCondition>> getCommercialConditions() async {
    final response = await _client
        .from('commercial_conditions')
        .select()
        .eq('is_active', true)
        .order('description');

    return (response as List).map((e) => CommercialCondition.fromJson(e)).toList();
  }

  @override
  Future<List<Collaborator>> getCollaborators() async {
    final response = await _client
        .from('collaborators')
        .select()
        .eq('is_active', true)
        .order('full_name');

    return (response as List).map((e) => Collaborator.fromJson(e)).toList();
  }

  @override
  Future<FinancialParameter> getFinancialParameters() async {
    final response = await _client
        .from('financial_parameters')
        .select()
        .limit(1)
        .single();
    
    return FinancialParameter.fromJson(response);
  }

  @override
  Future<List<Quote>> getQuotes({String? status, String? clientId}) async {
    var query = _client.from('quotes').select(); // Simple select for list

    if (status != null) {
      query = query.eq('status', status);
    }
    if (clientId != null) {
      query = query.eq('client_id', clientId);
    }
    
    // Order by date issued descending
    final response = await query.order('date_issued', ascending: false);
    
    return (response as List).map((e) => Quote.fromJson(e)).toList();
  }

  @override
  Future<Quote> getQuoteById(String id) async {
    final response = await _client
        .from('quotes')
        .select('*, quote_items_products(*), quote_items_services(*), quote_conditions(*)')
        .eq('id', id)
        .single();

    return Quote.fromJson(response);
  }

  @override
  Future<Quote> createQuote(Quote quote, {
    List<QuoteItemProduct>? products,
    List<QuoteItemService>? services,
    List<QuoteCondition>? conditions,
  }) async {
    // 1. Insert Header
    final headerResponse = await _client
        .from('quotes')
        .insert({
          'client_id': quote.clientId,
          'contact_id': quote.contactId,
          'advisor_id': quote.advisorId,
          'category_id': quote.categoryId,
          'validity_days': quote.validityDays,
          'notes': quote.notes,
          'status': 'draft', // Always draft initially
          // Subtotal/Total/Tax are calculated via trigger or app logic? 
          // For MVP, letting App logic send them or defaulting to 0 and updating later.
          // Sending calculated totals:
          'subtotal': quote.subtotal,
          'tax_amount': quote.taxAmount,
          'total': quote.total,
        })
        .select()
        .single();
    
    final newQuoteId = headerResponse['id'] as String;

    // 2. Insert Products
    if (products != null && products.isNotEmpty) {
      final productsData = products.map((e) => {
        'quote_id': newQuoteId,
        'product_id': e.productId,
        'supplier_product_id': e.supplierProductId,
        'delivery_time_id': e.deliveryTimeId,
        'name': e.name,
        'brand': e.brand,
        'model': e.model,
        'uom': e.uom,
        'description': e.description,
        'quantity': e.quantity,
        'cost_price': e.costPrice,
        'profit_margin': e.profitMargin,
        'unit_price': e.unitPrice,
        'tax_rate': e.taxRate,
        'tax_amount': e.taxAmount,
        'total_price': e.totalPrice,
        'warranty_time': e.warrantyTime,
      }).toList();
      await _client.from('quote_items_products').insert(productsData);
    }

    // 3. Insert Services
    if (services != null && services.isNotEmpty) {
       final servicesData = services.map((e) => {
        'quote_id': newQuoteId,
        'service_id': e.serviceId,
        'service_rate_id': e.serviceRateId,
        'execution_time_id': e.executionTimeId,
        'name': e.name,
        'description': e.description,
        'quantity': e.quantity,
        'cost_price': e.costPrice,
        'profit_margin': e.profitMargin,
        'unit_price': e.unitPrice,
        'tax_rate': e.taxRate,
        'total_price': e.totalPrice,
        'warranty_time': e.warrantyTime,
      }).toList();
      await _client.from('quote_items_services').insert(servicesData);
    }

    // 4. Insert Conditions
    if (conditions != null && conditions.isNotEmpty) {
      final conditionsData = conditions.map((e) => {
        'quote_id': newQuoteId,
        'condition_id': e.conditionId,
        'description': e.description,
        'order_index': e.orderIndex,
      }).toList();
      await _client.from('quote_conditions').insert(conditionsData);
    }

    // Return full object
    return await getQuoteById(newQuoteId);
  }

  @override
  Future<void> updateQuoteStatus(String id, String status) async {
    await _client.from('quotes').update({'status': status}).eq('id', id);
  }

  @override
  Future<void> deleteQuote(String id) async {
    await _client.from('quotes').delete().eq('id', id);
  }
}
