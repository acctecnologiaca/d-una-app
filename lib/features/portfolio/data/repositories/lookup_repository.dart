import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_rate_model.dart';
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../models/uom_model.dart';
import '../../domain/models/unaffiliated_supplier_model.dart';
import '../../../quotes/data/models/collaborator.dart';
import '../../../quotes/data/models/commercial_condition.dart';
import '../../../settings/data/models/shipping_company.dart';
import '../models/delivery_time_model.dart';

class LookupRepository {
  final SupabaseClient _client;

  LookupRepository(this._client);

  Future<List<Category>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .order('name', ascending: true);
    return (response as List).map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Brand>> getBrands() async {
    final response = await _client
        .from('brands')
        .select()
        .order('name', ascending: true);
    return (response as List).map((e) => Brand.fromJson(e)).toList();
  }

  Future<List<ServiceRate>> getServiceRates() async {
    final response = await _client
        .from('service_rates')
        .select()
        .order('name', ascending: true);
    return (response as List).map((e) => ServiceRate.fromJson(e)).toList();
  }

  Future<List<Uom>> getUoms() async {
    final response = await _client
        .from('uoms')
        .select()
        .order('name', ascending: true);
    return (response as List).map((e) => Uom.fromJson(e)).toList();
  }

  Future<List<Collaborator>> getCollaborators() async {
    final response = await _client
        .from('collaborators')
        .select()
        .eq('is_active', true)
        .order('full_name', ascending: true);
    return (response as List).map((e) => Collaborator.fromJson(e)).toList();
  }

  Future<List<CommercialCondition>> getCommercialConditions() async {
    final response = await _client
        .from('commercial_conditions')
        .select()
        .eq('is_active', true)
        .order('description', ascending: true);
    return (response as List)
        .map((e) => CommercialCondition.fromJson(e))
        .toList();
  }

  Future<CommercialCondition> addCommercialCondition({
    required String description,
    required bool isDefaultQuote,
    required bool isDefaultReport,
  }) async {
    final response = await _client
        .from('commercial_conditions')
        .insert({
          'description': description,
          'is_default_quote': isDefaultQuote,
          'is_default_report': isDefaultReport,
          'is_active': true,
          'user_id': _client.auth.currentUser?.id,
        })
        .select()
        .single();
    return CommercialCondition.fromJson(response);
  }

  Future<void> updateCommercialCondition({
    required String id,
    required String description,
    required bool isDefaultQuote,
    required bool isDefaultReport,
  }) async {
    await _client
        .from('commercial_conditions')
        .update({
          'description': description,
          'is_default_quote': isDefaultQuote,
          'is_default_report': isDefaultReport,
        })
        .eq('id', id);
  }

  Future<void> deleteCommercialCondition(String id) async {
    final response = await _client
        .from('commercial_conditions')
        .delete()
        .eq('id', id)
        .select();
    if ((response as List).isEmpty) {
      throw Exception(
        'La condición no pudo ser eliminada (posible bloqueo por permisos RLS o uso en otros registros).',
      );
    }
  }

  // ...
  Future<Brand> addBrand(String name) async {
    final response = await _client
        .from('brands')
        .insert({'name': name})
        .select()
        .single();
    return Brand.fromJson(response);
  }

  Future<void> updateBrand(String id, String newName) async {
    await _client.from('brands').update({'name': newName}).eq('id', id);
  }

  Future<void> deleteBrand(String id) async {
    final response = await _client
        .from('brands')
        .delete()
        .eq('id', id)
        .select();
    if ((response as List).isEmpty) {
      throw Exception(
        'La marca no pudo ser eliminada (posible bloqueo por permisos RLS o uso en otros registros).',
      );
    }
  }

  Future<Category> addCategory(String name) async {
    final response = await _client
        .from('categories')
        .insert({'name': name, 'type': 'product'})
        .select()
        .single();
    return Category.fromJson(response);
  }

  Future<void> updateCategory(String id, String newName) async {
    await _client.from('categories').update({'name': newName}).eq('id', id);
  }

  Future<void> deleteCategory(String id) async {
    final response = await _client
        .from('categories')
        .delete()
        .eq('id', id)
        .select();
    if ((response as List).isEmpty) {
      throw Exception(
        'La categoría no pudo ser eliminada (posible bloqueo por permisos RLS o uso en otros registros).',
      );
    }
  }

  Future<ServiceRate> addServiceRate(String name, String symbol) async {
    final response = await _client
        .from('service_rates')
        .insert({'name': name, 'symbol': symbol})
        .select()
        .single();
    return ServiceRate.fromJson(response);
  }

  Future<void> updateServiceRate(
    String id,
    String newName,
    String newSymbol,
  ) async {
    await _client
        .from('service_rates')
        .update({'name': newName, 'symbol': newSymbol})
        .eq('id', id);
  }

  Future<void> deleteServiceRate(String id) async {
    final response = await _client
        .from('service_rates')
        .delete()
        .eq('id', id)
        .select();
    if ((response as List).isEmpty) {
      throw Exception(
        'La tarifa no pudo ser eliminada (posible bloqueo por permisos RLS o uso en otros registros).',
      );
    }
  }

  Future<Uom> addUom(String name, String symbol) async {
    final response = await _client
        .from('uoms')
        .insert({'name': name, 'symbol': symbol})
        .select()
        .single();
    return Uom.fromJson(response);
  }

  Future<void> updateUom(String id, String newName, String newSymbol) async {
    await _client
        .from('uoms')
        .update({'name': newName, 'symbol': newSymbol})
        .eq('id', id);
  }

  Future<void> deleteUom(String id) async {
    final response = await _client.from('uoms').delete().eq('id', id).select();
    if ((response as List).isEmpty) {
      throw Exception(
        'La unidad de medida no pudo ser eliminada (posible bloqueo por permisos RLS o uso en otros registros).',
      );
    }
  }

  // ── Proveedores No Afiliados ────────────────────────────────────────────────

  Future<List<UnaffiliatedSupplier>> getUnaffiliatedSuppliers() async {
    final response = await _client
        .from('suppliers')
        .select(
          'id, name, legal_name, phone, email, tax_id, created_by, is_verified',
        )
        .eq('is_affiliated', false)
        .order('name');
    return (response as List)
        .map((json) => UnaffiliatedSupplier.fromJson(json))
        .toList();
  }

  Future<UnaffiliatedSupplier> addUnaffiliatedSupplier({
    required String name,
    String? legalName,
    String? phone,
    String? email,
    String? taxId,
  }) async {
    final response = await _client
        .from('suppliers')
        .insert({
          'name': name,
          'legal_name': legalName,
          'phone': phone,
          'email': email,
          'tax_id': taxId,
          'is_affiliated': false,
        })
        .select()
        .single();
    return UnaffiliatedSupplier.fromJson(response);
  }

  Future<void> updateUnaffiliatedSupplier({
    required String id,
    required String name,
    String? legalName,
    String? phone,
    String? email,
    String? taxId,
  }) async {
    await _client
        .from('suppliers')
        .update({
          'name': name,
          'legal_name': legalName,
          'phone': phone,
          'email': email,
          'tax_id': taxId,
        })
        .eq('id', id);
  }

  Future<void> deleteUnaffiliatedSupplier(String id) async {
    final response = await _client
        .from('suppliers')
        .delete()
        .eq('id', id)
        .select();
    if ((response as List).isEmpty) {
      throw Exception(
        'El proveedor no pudo ser eliminado (posible bloqueo por permisos RLS o uso en otros registros).',
      );
    }
  }

  // ── Empresas de Encomienda ────────────────────────────────────────────────

  Future<List<ShippingCompany>> getShippingCompanies() async {
    final response = await _client
        .from('shipping_companies')
        .select()
        .order('name');
    return (response as List)
        .map((json) => ShippingCompany.fromJson(json))
        .toList();
  }

  Future<ShippingCompany> addShippingCompany({
    required String legalName,
    required String taxId,
    String? name,
  }) async {
    final response = await _client
        .from('shipping_companies')
        .insert({
          'legal_name': legalName,
          'tax_id': taxId,
          'name': name,
          'is_verified': false,
          'created_by': _client.auth.currentUser?.id,
        })
        .select()
        .single();
    return ShippingCompany.fromJson(response);
  }

  Future<void> updateShippingCompany({
    required String id,
    required String legalName,
    required String taxId,
    String? name,
  }) async {
    await _client
        .from('shipping_companies')
        .update({'legal_name': legalName, 'tax_id': taxId, 'name': name})
        .eq('id', id);
  }

  Future<void> deleteShippingCompany(String id) async {
    final response = await _client
        .from('shipping_companies')
        .delete()
        .eq('id', id)
        .select();
    if ((response as List).isEmpty) {
      throw Exception(
        'La empresa de encomienda no pudo ser eliminada (posible bloqueo por permisos RLS o uso en otros registros).',
      );
    }
  }

  // ── Tiempos de Entrega y Ejecución ────────────────────────────────────────

  Future<List<DeliveryTime>> getDeliveryTimes() async {
    final response = await _client
        .from('delivery_times')
        .select()
        .order('order_idx', ascending: true);
    return (response as List)
        .map((json) => DeliveryTime.fromJson(json))
        .toList();
  }

  Future<DeliveryTime> addDeliveryTime({
    required String name,
    required String type,
    required String unit,
    int? minValue,
    int? maxValue,
    required int orderIdx,
  }) async {
    final response = await _client
        .from('delivery_times')
        .insert({
          'name': name,
          'type': type,
          'unit': unit,
          'min_value': minValue,
          'max_value': maxValue,
          'order_idx': orderIdx,
          'user_id': _client.auth.currentUser?.id,
        })
        .select()
        .single();
    return DeliveryTime.fromJson(response);
  }

  Future<void> updateDeliveryTime({
    required String id,
    required String name,
    required String type,
    required String unit,
    int? minValue,
    int? maxValue,
  }) async {
    await _client
        .from('delivery_times')
        .update({
          'name': name,
          'type': type,
          'unit': unit,
          'min_value': minValue,
          'max_value': maxValue,
        })
        .eq('id', id);
  }

  Future<void> deleteDeliveryTime(String id) async {
    final response = await _client
        .from('delivery_times')
        .delete()
        .eq('id', id)
        .select();
    if ((response as List).isEmpty) {
      throw Exception(
        'El tiempo no pudo ser eliminado (posible bloqueo por permisos o uso en otros registros).',
      );
    }
  }

  Future<void> reorderDeliveryTimes(List<Map<String, dynamic>> updates) async {
    // updates should be a list of maps with 'id' and 'order_idx'
    // Since Supabase RPC for bulk update might not be there, update one by one
    // It's a small list, so it should be fast enough.
    for (final update in updates) {
      await _client
          .from('delivery_times')
          .update({'order_idx': update['order_idx']})
          .eq('id', update['id']);
    }
  }
}
