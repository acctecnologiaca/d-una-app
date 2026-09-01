import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/service_reports_repository.dart';
import '../../data/models/models.dart';
import '../../../portfolio/data/models/category_model.dart';
import '../../../quotes/data/models/commercial_condition.dart';
import '../../../quotes/data/models/financial_parameter.dart';

class SupabaseServiceReportsRepository implements ServiceReportsRepository {
  final SupabaseClient _client;

  SupabaseServiceReportsRepository(this._client);

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
  Future<List<Category>> getCategories() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('categories')
        .select()
        .or('user_id.eq.$userId,user_id.is.null')
        .order('name');

    return (response as List).map((e) => Category.fromJson(e)).toList();
  }

  @override
  Future<List<ServiceReport>> getReports({
    String? status,
    String? clientId,
    bool includeArchived = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    var query = _client
        .from('service_reports')
        .select('''
          *,
          clients(name),
          categories(name),
          service_report_items_products(*),
          service_report_items_services(*)
        ''')
        .eq('user_id', userId);

    if (status != null) {
      query = query.eq('status', status);
    }
    if (clientId != null) {
      query = query.eq('client_id', clientId);
    }
    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    final response = await query.order('service_date', ascending: false);
    return (response as List).map((e) => ServiceReport.fromJson(e)).toList();
  }

  @override
  Future<List<ServiceReport>> getReportsPaginated({
    required int offset,
    int limit = 25,
    String orderBy = 'service_date',
    bool ascending = false,
    String? searchQuery,
    String? statusFilter,
    String? categoryFilter,
    DateTimeRange? dateRange,
    bool includeArchived = false,
    String? productId,
    String? clientId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final selectQuery = productId != null
        ? '*, clients(name), categories(name), collaborators!advisor_id(full_name), service_report_collaborators(collaborator_id, collaborators(*)), service_report_items_products!inner(*), service_report_items_services(*)'
        : '*, clients(name), categories(name), collaborators!advisor_id(full_name), service_report_collaborators(collaborator_id, collaborators(*)), service_report_items_products(*), service_report_items_services(*)';

    var query = _client
        .from('service_reports')
        .select(selectQuery)
        .eq('user_id', userId);

    if (productId != null) {
      query = query.eq('service_report_items_products.product_id', productId);
    }

    if (clientId != null) {
      query = query.eq('client_id', clientId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchQueryClean = searchQuery.trim();
      List<String> matchingClientIds = [];
      List<String> matchingReportIdsFromProducts = [];

      try {
        final clientResponse = await _client
            .from('clients')
            .select('id')
            .eq('user_id', userId)
            .ilike('name', '%$searchQueryClean%');
        matchingClientIds =
            (clientResponse as List).map((e) => e['id'].toString()).toList();
      } catch (_) {}

      try {
        final itemsResponse = await _client
            .from('service_report_items_products')
            .select('report_id')
            .or('name.ilike.%$searchQueryClean%,model.ilike.%$searchQueryClean%,brand.ilike.%$searchQueryClean%');
        matchingReportIdsFromProducts = (itemsResponse as List)
            .map((e) => e['report_id'].toString())
            .toSet()
            .toList();
      } catch (_) {}

      List<String> orClauses = [
        'report_number.ilike.%$searchQueryClean%',
        'report_tag.ilike.%$searchQueryClean%',
        'request_description.ilike.%$searchQueryClean%',
        'work_description.ilike.%$searchQueryClean%',
      ];

      if (matchingClientIds.isNotEmpty) {
        final idsStr = matchingClientIds.join(',');
        orClauses.add('client_id.in.($idsStr)');
      }

      if (matchingReportIdsFromProducts.isNotEmpty) {
        final repIdsStr = matchingReportIdsFromProducts.join(',');
        orClauses.add('id.in.($repIdsStr)');
      }

      query = query.or(orClauses.join(','));
    }

    if (statusFilter != null) {
      query = query.eq('status', statusFilter);
    }

    if (categoryFilter != null) {
      query = query.eq('category_id', categoryFilter);
    }

    if (dateRange != null) {
      query = query
          .gte('service_date', dateRange.start.toIso8601String().split('T').first)
          .lte('service_date', dateRange.end.toIso8601String().split('T').first);
    }

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    var orderQuery = query.order(orderBy, ascending: ascending);
    if (orderBy == 'service_date' || orderBy == 'report_number') {
      orderQuery = orderQuery.order('created_at', ascending: false);
    }

    final response = await orderQuery.range(offset, offset + limit - 1);
    return (response as List).map((e) => ServiceReport.fromJson(e)).toList();
  }

  @override
  Future<ServiceReport> getReportById(String id) async {
    final response = await _client
        .from('service_reports')
        .select(
          '*, clients(name), categories(name), collaborators!advisor_id(full_name), service_report_collaborators(collaborator_id, collaborators(*)), service_report_items_products(*), service_report_items_services(*), service_report_conditions(*)',
        )
        .eq('id', id)
        .single();

    return ServiceReport.fromJson(response);
  }

  @override
  Future<ServiceReport> getReportWithDetails(String id) async {
    final response = await _client
        .from('service_reports')
        .select(
          '*, clients(*), contacts(*), collaborators!advisor_id(full_name), service_report_collaborators(collaborator_id, collaborators(*)), categories(name), service_report_items_products(*), service_report_items_services(*), service_report_conditions(*)',
        )
        .eq('id', id)
        .single();

    return ServiceReport.fromJson(response);
  }

  @override
  Future<String?> getLastReportNumber() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('service_reports')
        .select('report_number')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response?['report_number'] as String?;
  }

  @override
  Future<ServiceReport> createReport(
    ServiceReport report, {
    List<ServiceReportItemProduct>? products,
    List<ServiceReportItemService>? services,
    List<ServiceReportCondition>? conditions,
    List<String>? technicianIds,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    // 1. Insert Header
    final headerResponse = await _client
        .from('service_reports')
        .insert({
          'user_id': userId,
          'report_number': report.reportNumber,
          'client_id': report.clientId,
          'contact_id': report.contactId,
          'advisor_id': report.advisorId,
          'category_id': report.categoryId,
          'status': report.status,
          'intervention_type': report.interventionType,
          'request_description': report.requestDescription,
          'work_description': report.workDescription,
          'recommendations': report.recommendations,
          'service_date': report.serviceDate.toIso8601String().split('T').first,
          'start_time': report.startTime,
          'end_time': report.endTime,
          'duration_minutes': report.durationMinutes,
          'subtotal': report.subtotal,
          'tax_amount': report.taxAmount,
          'total': report.total,
          'notes': report.notes,
          'report_tag': report.reportTag,
        })
        .select()
        .single();

    final newReportId = headerResponse['id'] as String;

    // 2. Insert Products
    if (products != null && products.isNotEmpty) {
      final productsData = products
          .map(
            (e) => {
              'report_id': newReportId,
              'product_id': e.productId,
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
              'group_index': e.groupIndex,
              'warranty_time': e.warrantyTime,
              'warranty_unit': e.warrantyUnit,
            },
          )
          .toList();

      await _client
          .from('service_report_items_products')
          .insert(productsData);
    }

    // 3. Insert Services
    if (services != null && services.isNotEmpty) {
      final servicesData = services
          .map(
            (e) => {
              'report_id': newReportId,
              'service_id': e.serviceId,
              'name': e.name,
              'description': e.description,
              'quantity': e.quantity,
              'cost_price': e.costPrice,
              'profit_margin': e.profitMargin,
              'unit_price': e.unitPrice,
              'tax_rate': e.taxRate,
              'tax_amount': e.taxAmount,
              'total_price': e.totalPrice,
              'rate_symbol': e.rateSymbol,
              'rate_icon_name': e.rateIconName,
              'order_index': e.orderIndex,
              'warranty_time': e.warrantyTime,
              'warranty_unit': e.warrantyUnit,
            },
          )
          .toList();

      await _client
          .from('service_report_items_services')
          .insert(servicesData);
    }

    // 4. Insert Conditions
    if (conditions != null && conditions.isNotEmpty) {
      final conditionsData = conditions
          .map(
            (e) => {
              'report_id': newReportId,
              'condition_id': e.conditionId,
              'description': e.description,
              'order_index': e.orderIndex,
            },
          )
          .toList();

      await _client
          .from('service_report_conditions')
          .insert(conditionsData);
    }

    // 5. Insert Collaborators/Technicians
    final finalTechIds =
        technicianIds ?? report.technicians?.map((t) => t.id).toList();
    if (finalTechIds != null && finalTechIds.isNotEmpty) {
      final collabData = finalTechIds
          .toSet()
          .map(
            (collabId) => {
              'report_id': newReportId,
              'collaborator_id': collabId,
            },
          )
          .toList();

      await _client
          .from('service_report_collaborators')
          .insert(collabData);
    }

    return getReportWithDetails(newReportId);
  }

  @override
  Future<ServiceReport> updateReport(
    ServiceReport report, {
    List<ServiceReportItemProduct>? products,
    List<ServiceReportItemService>? services,
    List<ServiceReportCondition>? conditions,
    List<String>? technicianIds,
  }) async {
    // 1. Update Header
    await _client.from('service_reports').update({
      'client_id': report.clientId,
      'contact_id': report.contactId,
      'advisor_id': report.advisorId,
      'category_id': report.categoryId,
      'status': report.status,
      'intervention_type': report.interventionType,
      'request_description': report.requestDescription,
      'work_description': report.workDescription,
      'recommendations': report.recommendations,
      'service_date': report.serviceDate.toIso8601String().split('T').first,
      'start_time': report.startTime,
      'end_time': report.endTime,
      'duration_minutes': report.durationMinutes,
      'subtotal': report.subtotal,
      'tax_amount': report.taxAmount,
      'total': report.total,
      'notes': report.notes,
      'report_tag': report.reportTag,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', report.id);

    // 2. Sync Products
    if (products != null) {
      await _client
          .from('service_report_items_products')
          .delete()
          .eq('report_id', report.id);

      if (products.isNotEmpty) {
        final productsData = products
            .map(
              (e) => {
                'report_id': report.id,
                'product_id': e.productId,
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
                'group_index': e.groupIndex,
                'warranty_time': e.warrantyTime,
                'warranty_unit': e.warrantyUnit,
              },
            )
            .toList();

        await _client
            .from('service_report_items_products')
            .insert(productsData);
      }
    }

    // 3. Sync Services
    if (services != null) {
      await _client
          .from('service_report_items_services')
          .delete()
          .eq('report_id', report.id);

      if (services.isNotEmpty) {
        final servicesData = services
            .map(
              (e) => {
                'report_id': report.id,
                'service_id': e.serviceId,
                'name': e.name,
                'description': e.description,
                'quantity': e.quantity,
                'cost_price': e.costPrice,
                'profit_margin': e.profitMargin,
                'unit_price': e.unitPrice,
                'tax_rate': e.taxRate,
                'tax_amount': e.taxAmount,
                'total_price': e.totalPrice,
                'rate_symbol': e.rateSymbol,
                'rate_icon_name': e.rateIconName,
                'order_index': e.orderIndex,
                'warranty_time': e.warrantyTime,
                'warranty_unit': e.warrantyUnit,
              },
            )
            .toList();

        await _client
            .from('service_report_items_services')
            .insert(servicesData);
      }
    }

    // 4. Sync Conditions
    if (conditions != null) {
      await _client
          .from('service_report_conditions')
          .delete()
          .eq('report_id', report.id);

      if (conditions.isNotEmpty) {
        final conditionsData = conditions
            .map(
              (e) => {
                'report_id': report.id,
                'condition_id': e.conditionId,
                'description': e.description,
                'order_index': e.orderIndex,
              },
            )
            .toList();

        await _client
            .from('service_report_conditions')
            .insert(conditionsData);
      }
    }

    // 5. Sync Collaborators/Technicians
    final finalTechIds =
        technicianIds ?? report.technicians?.map((t) => t.id).toList();
    if (finalTechIds != null) {
      await _client
          .from('service_report_collaborators')
          .delete()
          .eq('report_id', report.id);

      if (finalTechIds.isNotEmpty) {
        final collabData = finalTechIds
            .toSet()
            .map(
              (collabId) => {
                'report_id': report.id,
                'collaborator_id': collabId,
              },
            )
            .toList();

        await _client
            .from('service_report_collaborators')
            .insert(collabData);
      }
    }

    return getReportWithDetails(report.id);
  }

  @override
  Future<void> updateReportStatus(String id, String status) async {
    await _client.from('service_reports').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> updateReportDate(String id, DateTime newDate) async {
    await _client.from('service_reports').update({
      'service_date': newDate.toIso8601String().split('T').first,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> archiveReport(String id, bool isArchived) async {
    await _client.from('service_reports').update({
      'is_archived': isArchived,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> deleteReport(String id) async {
    await _client.from('service_reports').delete().eq('id', id);
  }

  @override
  Future<List<String>> batchUpdateStatus(
      List<String> ids, String status) async {
    if (ids.isEmpty) return [];

    await _client
        .from('service_reports')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .inFilter('id', ids);

    return ids;
  }

  @override
  Future<void> batchArchive(List<String> ids, bool isArchived) async {
    if (ids.isEmpty) return;

    await _client
        .from('service_reports')
        .update({
          'is_archived': isArchived,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .inFilter('id', ids);
  }

  @override
  Future<String> uploadReportPdf({
    required String reportId,
    required List<int> pdfBytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final path = '$userId/service_reports/$reportId/$fileName';

    await _client.storage.from('documents').uploadBinary(
          path,
          Uint8List.fromList(pdfBytes),
          fileOptions: const FileOptions(upsert: true),
        );

    final pdfUrl = _client.storage.from('documents').getPublicUrl(path);

    await _client
        .from('service_reports')
        .update({'pdf_url': pdfUrl}).eq('id', reportId);

    return pdfUrl;
  }

  @override
  Future<String> generateActionToken(String reportId) async {
    final response = await _client.rpc(
      'generate_report_action_token',
      params: {'p_report_id': reportId},
    );

    if (response == null) {
      throw Exception('Error al generar token de acción para reporte de servicio');
    }

    return response.toString();
  }
}
