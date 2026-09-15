import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/ads_repository.dart';
import '../../domain/models/ad_banner_model.dart';
import '../../domain/models/ad_placement_setting.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

final adsRepositoryProvider = Provider<AdsRepository>((ref) {
  return AdsRepository(Supabase.instance.client);
});

final dismissedBannerIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Provider de configuración de activación de módulos y listas
final adPlacementSettingsProvider =
    FutureProvider<Map<String, AdPlacementSetting>>((ref) async {
  final repo = ref.watch(adsRepositoryProvider);
  return repo.getPlacementSettings();
});

/// Provider que evalúa si un placement (lista o módulo) está activo considerando la jerarquía
final isAdPlacementEnabledProvider =
    Provider.family<bool, String>((ref, placementKey) {
  final settingsAsync = ref.watch(adPlacementSettingsProvider);
  final settings = settingsAsync.valueOrNull;

  // Si aún está cargando o no hay conexión, mantener habilitado por defecto
  if (settings == null || settings.isEmpty) return true;

  final placement = settings[placementKey];
  if (placement == null) return true;

  // 1. Si la lista específica está desactivada -> false
  if (!placement.isEnabled) return false;

  // 2. Si tiene módulo padre y el módulo padre está desactivado -> false
  if (placement.parentModule != null && placement.parentModule!.isNotEmpty) {
    final parent = settings[placement.parentModule!];
    if (parent != null && !parent.isEnabled) return false;
  }

  return true;
});

/// Helper que extrae de forma reactiva los IDs de ocupación del usuario logueado
final userOccupationIdsProvider = Provider<List<String>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile == null) return const [];
  return [
    if (profile.occupationId != null && profile.occupationId!.isNotEmpty)
      profile.occupationId!,
    ...profile.secondaryOccupationIds,
  ];
});

class AdBannerParams {
  final List<String> occupationIds;
  final String? searchQuery;

  const AdBannerParams({
    this.occupationIds = const [],
    this.searchQuery,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdBannerParams &&
          runtimeType == other.runtimeType &&
          listEquals(occupationIds, other.occupationIds) &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(Object.hashAll(occupationIds), searchQuery);
}

/// Provider principal de banners que respeta el orden de prioridad del backend
final adBannersProvider =
    FutureProvider.family<List<AdBanner>, AdBannerParams>((ref, params) async {
  final repo = ref.watch(adsRepositoryProvider);

  final banners = await repo.getBannersForUser(
    occupationIds: params.occupationIds,
    searchQuery: params.searchQuery,
  );

  // El backend ya los ordena por b.priority DESC, RANDOM().
  // Retornamos la lista directa preservando la jerarquía comercial.
  return banners;
});

/// Parámetros para el helper de ubicación
typedef PlacementBannerKey = ({String placementKey, String? searchQuery});

/// Provider de conveniencia para consumir banners en cualquier pantalla con 1 sola línea
final placementBannersProvider =
    Provider.family<List<AdBanner>, PlacementBannerKey>((ref, key) {
  final isEnabled = ref.watch(isAdPlacementEnabledProvider(key.placementKey));
  if (!isEnabled) return const [];

  final occupationIds = ref.watch(userOccupationIdsProvider);
  final bannersAsync = ref.watch(
    adBannersProvider(
      AdBannerParams(
        occupationIds: occupationIds,
        searchQuery: key.searchQuery,
      ),
    ),
  );

  return bannersAsync.valueOrNull ?? const [];
});
