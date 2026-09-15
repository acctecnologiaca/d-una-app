import 'dart:async';
import 'package:flutter/foundation.dart';
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
      final response = await _supabase.rpc(
        'get_banners_for_user',
        params: {
          'p_occupation_ids': occupationIds,
          'p_search_query': searchQuery,
          'p_limit': limit,
        },
      );

      final data = response as List<dynamic>;
      return data
          .map((json) => AdBanner.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      debugPrint('[AdsRepository] Error fetching banners: $e\n$stack');
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
    } catch (e) {
      debugPrint('[AdsRepository] Error fetching placement settings: $e');
      return {};
    }
  }

  /// Escucha en tiempo real cambios en la configuración de activación de ubicaciones
  Stream<Map<String, AdPlacementSetting>> streamPlacementSettings() {
    return _supabase
        .from('ad_placement_settings')
        .stream(primaryKey: ['placement_key'])
        .map((rows) {
          final map = <String, AdPlacementSetting>{};
          for (final json in rows) {
            final setting = AdPlacementSetting.fromJson(json);
            map[setting.placementKey] = setting;
          }
          return map;
        });
  }

  /// Emite un evento cada vez que un anuncio es insertado, modificado o eliminado en Supabase
  Stream<void> streamBannersChangeTrigger() {
    return _supabase
        .from('ad_banners')
        .stream(primaryKey: ['id'])
        .map((_) {});
  }

  void recordClick({
    required String bannerId,
    required String screenContext,
    String? searchQuery,
  }) {
    unawaited(
      _supabase.from('ad_clicks').insert({
        'banner_id': bannerId,
        'user_id': _supabase.auth.currentUser?.id,
        'screen_context': screenContext,
        'search_query': searchQuery,
      }).catchError((e) {
        debugPrint('[AdsRepository] Error recording click: $e');
        return null;
      }),
    );
  }
}
