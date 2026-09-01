import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/ad_banner_model.dart';
import '../../domain/models/ad_placement_setting.dart';

class AdsRepository {
  final SupabaseClient _supabase;

  AdsRepository(this._supabase);

  Future<List<AdBanner>> getBannersForUser({
    List<String> occupationIds = const [],
    String? searchQuery,
    int limit = 10,
  }) async {
    try {
      // debugPrint para diagnóstico
      // ignore: avoid_print
      print('[ADS_DEBUG] Fetching banners for occupationIds: $occupationIds, query: $searchQuery');
      
      final response = await _supabase.rpc(
        'get_banners_for_user',
        params: {
          'p_occupation_ids': occupationIds,
          'p_search_query': searchQuery,
          'p_limit': limit,
        },
      );

      // ignore: avoid_print
      print('[ADS_DEBUG] Supabase RPC raw response: $response');

      final data = response as List<dynamic>;
      final banners = data
          .map((json) => AdBanner.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // ignore: avoid_print
      print('[ADS_DEBUG] Parsed ${banners.length} banners successfully');
      return banners;
    } catch (e, stack) {
      // ignore: avoid_print
      print('[ADS_DEBUG] Error fetching banners: $e\n$stack');
      return [];
    }
  }

  Future<Map<String, AdPlacementSetting>> getPlacementSettings() async {
    try {
      final response = await _supabase
          .from('ad_placement_settings')
          .select('placement_key, parent_module, name, is_enabled');

      final list = (response as List<dynamic>)
          .map((json) => AdPlacementSetting.fromJson(json as Map<String, dynamic>))
          .toList();

      final map = <String, AdPlacementSetting>{};
      for (final setting in list) {
        map[setting.placementKey] = setting;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  void recordClick({
    required String bannerId,
    required String screenContext,
    String? searchQuery,
  }) {
    unawaited(
      _supabase.from('ad_clicks').insert({
        'banner_id': bannerId,
        'screen_context': screenContext,
        'search_query': searchQuery,
      }).catchError((_) => null),
    );
  }
}
