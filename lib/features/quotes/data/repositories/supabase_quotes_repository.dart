import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/quotes_repository.dart';
import '../../data/models/quote.dart';
import '../../data/models/delivery_time.dart';
import '../../data/models/commercial_condition.dart';
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

    return (response as List)
        .map((e) => CommercialCondition.fromJson(e))
        .toList();
  }

  @override
  Future<FinancialParameter> getFinancialParameters() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('financial_parameters')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // Return default parameters if none exist for user
      return FinancialParameter(
        id: '',
        userId: userId,
        profitMargin: 20.0,
        taxRate: 16.0,
        currencyCode: 'USD',
        pricingMethod: 'margin',
        updatedAt: DateTime.now(),
      );
    }

    return FinancialParameter.fromJson(response);
  }

  @override
  Future<void> updateFinancialParameters(FinancialParameter params) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final data = params.toJson();
    data['user_id'] = userId;

    if (params.id.isEmpty) {
      // If it's a new record (no ID), insert without ID to let DB generate it
      data.remove('id');
      await _client.from('financial_parameters').insert(data);
    } else {
      await _client.from('financial_parameters').upsert(data);
    }
  }

  @override
  Future<List<Quote>> getQuotes({
    String? status,
    String? clientId,
    bool includeArchived = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    var query = _client
        .from('quotes')
        .select('''
          *,
          clients(name),
          category:categories(name),
          quote_items_products(*)
        ''')
        .eq('user_id', userId);

    if (status != null) {
      query = query.eq('status', status);
    }
    if (clientId != null) {
      query = query.eq('client_id', clientId);
    }

    // Filter by archive status
    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    // Order by date issued descending
    final response = await query.order('date_issued', ascending: false);

    return (response as List).map((e) => Quote.fromJson(e)).toList();
  }

  @override
  Future<Quote> getQuoteById(String id) async {
    final response = await _client
        .from('quotes')
        .select(
          '*, clients(name), category:categories(name), quote_items_products(*, supplier_branch_stock(supplier_branches(suppliers(name)))), quote_items_services(*), quote_conditions(*)',
        )
        .eq('id', id)
        .single();

    return Quote.fromJson(response);
  }

  @override
  Future<Quote> getQuoteWithDetails(String id) async {
    final response = await _client
        .from('quotes')
        .select(
          '*, clients(*), contacts(*), advisor:collaborators!advisor_id(full_name), category:categories(name), quote_items_products(*, supplier_branch_stock(supplier_branches(suppliers(name)))), quote_items_services(*), quote_conditions(*)',
        )
        .eq('id', id)
        .single();

    return Quote.fromJson(response);
  }

  @override
  Future<String?> getLastQuoteNumber() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('quotes')
        .select('quote_number')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response?['quote_number'] as String?;
  }

  @override
  Future<Quote> createQuote(
    Quote quote, {
    List<QuoteItemProduct>? products,
    List<QuoteItemService>? services,
    List<QuoteCondition>? conditions,
  }) async {
    // 1. Insert Header
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final headerResponse = await _client
        .from('quotes')
        .insert({
          'user_id': userId,
          'quote_number': quote.quoteNumber,
          'client_id': quote.clientId,
          'contact_id': quote.contactId,
          'advisor_id': quote.advisorId,
          'category_id': quote.categoryId,
          'validity_days': quote.validityDays,
          'notes': quote.notes,
          'quote_tag': quote.quoteTag,
          'status': 'draft',
          'subtotal': quote.subtotal,
          'tax_amount': quote.taxAmount,
          'total': quote.total,
        })
        .select()
        .single();

    final newQuoteId = headerResponse['id'] as String;

    // 2. Insert Products
    if (products != null && products.isNotEmpty) {
      final productsData = products
          .map(
            (e) => {
              'quote_id': newQuoteId,
              'product_id': e.productId,
              'supplier_branch_stock_id': e.supplierBranchStockId,
              'delivery_time_id': e.deliveryTimeId,
              'name': e.name,
              'brand': e.brand,
              'model': e.model,
              'uom': e.uom,
              'uom_icon_name': e.uomIconName,
              'description': e.description,
              'quantity': e.quantity,
              'cost_price': e.costPrice,
              'profit_margin': e.profitMargin,
              'unit_price': e.unitPrice,
              'tax_rate': e.taxRate,
              'tax_amount': e.taxAmount,
              'total_price': e.totalPrice,
              'warranty_time': e.warrantyTime,
              'warranty_unit': e.warrantyUnit,
              'external_provider_name': e.externalProviderName,
              'source_type': e.sourceType.name,
              'group_index': e.groupIndex,
            },
          )
          .toList();
      await _client.from('quote_items_products').insert(productsData);
    }

    // 3. Insert Services
    if (services != null && services.isNotEmpty) {
      final servicesData = services
          .map(
            (e) => {
              'quote_id': newQuoteId,
              'service_id': e.serviceId,
              'execution_time_id': e.executionTimeId,
              'name': e.name,
              'description': e.description,
              'quantity': e.quantity,
              'cost_price': e.costPrice,
              'profit_margin': e.profitMargin,
              'unit_price': e.unitPrice,
              'tax_rate': e.taxRate,
              'tax_amount': e.taxAmount,
              'total_price': e.totalPrice,
              'warranty_time': e.warrantyTime,
              'warranty_unit': e.warrantyUnit,
              'rate_symbol': e.rateSymbol,
              'rate_icon_name': e.rateIconName,
              'category_name': e.categoryName,
              'execution_time_label': e.executionTimeLabel,
              'order_index': e.orderIndex,
            },
          )
          .toList();
      await _client.from('quote_items_services').insert(servicesData);
    }

    // 4. Insert Conditions
    if (conditions != null && conditions.isNotEmpty) {
      final conditionsData = conditions
          .map(
            (e) => {
              'quote_id': newQuoteId,
              'condition_id': e.conditionId,
              'description': e.description,
              'order_index': e.orderIndex,
            },
          )
          .toList();
      await _client.from('quote_conditions').insert(conditionsData);
    }

    // Return full object
    return await getQuoteById(newQuoteId);
  }

  @override
  Future<Quote> updateQuote(
    Quote quote, {
    List<QuoteItemProduct>? products,
    List<QuoteItemService>? services,
    List<QuoteCondition>? conditions,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    if (quote.id.isEmpty) {
      throw Exception('La cotización no tiene ID para actualizar');
    }

    // 1. Update Header
    await _client
        .from('quotes')
        .update({
          'client_id': quote.clientId,
          'contact_id': quote.contactId,
          'advisor_id': quote.advisorId,
          'category_id': quote.categoryId,
          'validity_days': quote.validityDays,
          'notes': quote.notes,
          'quote_tag': quote.quoteTag,
          'status': quote.status, // might update status to pending or keep it
          'subtotal': quote.subtotal,
          'tax_amount': quote.taxAmount,
          'total': quote.total,
        })
        .eq('id', quote.id);

    // 2. Clear old items and conditions
    await _client
        .from('quote_items_products')
        .delete()
        .eq('quote_id', quote.id);
    await _client
        .from('quote_items_services')
        .delete()
        .eq('quote_id', quote.id);
    await _client.from('quote_conditions').delete().eq('quote_id', quote.id);

    // 3. Insert new Products
    if (products != null && products.isNotEmpty) {
      final productsData = products
          .map(
            (e) => {
              'quote_id': quote.id,
              'product_id': e.productId,
              'supplier_branch_stock_id': e.supplierBranchStockId,
              'delivery_time_id': e.deliveryTimeId,
              'name': e.name,
              'brand': e.brand,
              'model': e.model,
              'uom': e.uom,
              'uom_icon_name': e.uomIconName,
              'description': e.description,
              'quantity': e.quantity,
              'cost_price': e.costPrice,
              'profit_margin': e.profitMargin,
              'unit_price': e.unitPrice,
              'tax_rate': e.taxRate,
              'tax_amount': e.taxAmount,
              'total_price': e.totalPrice,
              'warranty_time': e.warrantyTime,
              'warranty_unit': e.warrantyUnit,
              'external_provider_name': e.externalProviderName,
              'source_type': e.sourceType.name,
              'group_index': e.groupIndex,
            },
          )
          .toList();
      await _client.from('quote_items_products').insert(productsData);
    }

    // 4. Insert new Services
    if (services != null && services.isNotEmpty) {
      final servicesData = services
          .map(
            (e) => {
              'quote_id': quote.id,
              'service_id': e.serviceId,
              'execution_time_id': e.executionTimeId,
              'name': e.name,
              'description': e.description,
              'quantity': e.quantity,
              'cost_price': e.costPrice,
              'profit_margin': e.profitMargin,
              'unit_price': e.unitPrice,
              'tax_rate': e.taxRate,
              'tax_amount': e.taxAmount,
              'total_price': e.totalPrice,
              'warranty_time': e.warrantyTime,
              'warranty_unit': e.warrantyUnit,
              'rate_symbol': e.rateSymbol,
              'rate_icon_name': e.rateIconName,
              'category_name': e.categoryName,
              'execution_time_label': e.executionTimeLabel,
              'order_index': e.orderIndex,
            },
          )
          .toList();
      await _client.from('quote_items_services').insert(servicesData);
    }

    // 5. Insert new Conditions
    if (conditions != null && conditions.isNotEmpty) {
      final conditionsData = conditions
          .map(
            (e) => {
              'quote_id': quote.id,
              'condition_id': e.conditionId,
              'description': e.description,
              'order_index': e.orderIndex,
            },
          )
          .toList();
      await _client.from('quote_conditions').insert(conditionsData);
    }

    // Return full updated object
    return await getQuoteById(quote.id);
  }

  @override
  Future<void> updateQuoteStatus(String id, String status) async {
    if (status == 'approved') {
      final List<dynamic> insufficient = await _client.rpc(
        'check_quote_insufficient_stock',
        params: {'p_quote_id': id},
      );

      if (insufficient.isNotEmpty) {
        final names = insufficient
            .map((item) => item['product_name'] as String)
            .toList();
        throw InsufficientStockException(names);
      }
    }
    await _client.from('quotes').update({'status': status}).eq('id', id);
  }

  @override
  Future<void> archiveQuote(String id, bool isArchived) async {
    await _client
        .from('quotes')
        .update({'is_archived': isArchived})
        .eq('id', id);
  }

  @override
  Future<void> deleteQuote(String id) async {
    await _client.from('quotes').delete().eq('id', id);
  }

  @override
  Future<void> batchUpdateStatus(List<String> ids, String status) async {
    if (status == 'approved') {
      final List<String> allInsufficientNames = [];
      for (final id in ids) {
        final List<dynamic> insufficient = await _client.rpc(
          'check_quote_insufficient_stock',
          params: {'p_quote_id': id},
        );
        if (insufficient.isNotEmpty) {
          allInsufficientNames.addAll(
            insufficient.map((item) => item['product_name'] as String),
          );
        }
      }
      if (allInsufficientNames.isNotEmpty) {
        throw InsufficientStockException(allInsufficientNames.toSet().toList());
      }
    }
    await _client.from('quotes').update({'status': status}).inFilter('id', ids);
  }

  @override
  Future<void> batchArchive(List<String> ids, bool isArchived) async {
    await _client
        .from('quotes')
        .update({'is_archived': isArchived})
        .inFilter('id', ids);
  }
}
