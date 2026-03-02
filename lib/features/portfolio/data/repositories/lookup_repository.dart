import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_rate_model.dart';
import '../models/category_model.dart';
import '../models/brand_model.dart';
import '../models/uom_model.dart';
import '../../../quotes/data/models/collaborator.dart';
import '../../../quotes/data/models/commercial_condition.dart';

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

  // ...
  Future<Brand> addBrand(String name) async {
    final response = await _client
        .from('brands')
        .insert({'name': name})
        .select()
        .single();
    return Brand.fromJson(response);
  }

  Future<Category> addCategory(String name) async {
    final response = await _client
        .from('categories')
        .insert({'name': name, 'type': 'product'}) // Assuming 'product' type
        .select()
        .single();
    return Category.fromJson(response);
  }

  Future<ServiceRate> addServiceRate(String name, String symbol) async {
    final response = await _client
        .from('service_rates')
        .insert({'name': name, 'symbol': symbol})
        .select()
        .single();
    return ServiceRate.fromJson(response);
  }
}
