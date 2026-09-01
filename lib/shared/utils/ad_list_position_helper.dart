import '../../features/ads/domain/models/ad_banner_model.dart';

class AdSlotInfo {
  final int realItemThreshold; // Cantidad de items reales antes de este banner
  final AdBanner banner;

  const AdSlotInfo({
    required this.realItemThreshold,
    required this.banner,
  });
}

class AdListPositionHelper {
  /// Retorna la lista de slots de banners activos para una lista de [realCount] items.
  static List<AdSlotInfo> getActiveSlots({
    required int realCount,
    required List<AdBanner> banners,
    Set<String> dismissedIds = const {},
    int firstIndex = 3,
    int interval = 6,
  }) {
    if (realCount == 0 || banners.isEmpty || realCount < firstIndex) {
      return const [];
    }

    final realInterval = interval - 1;
    final maxSlots = ((realCount - firstIndex) ~/ realInterval) + 1;
    final activeSlots = <AdSlotInfo>[];

    for (int s = 0; s < maxSlots; s++) {
      final banner = banners[s % banners.length];
      if (!dismissedIds.contains(banner.id)) {
        final threshold = firstIndex + (s * realInterval);
        activeSlots.add(AdSlotInfo(
          realItemThreshold: threshold,
          banner: banner,
        ));
      }
    }

    return activeSlots;
  }

  /// Calcula el total de elementos visibles (items reales + slots de banners activos).
  static int calculateTotalCount({
    required int realCount,
    required List<AdBanner> banners,
    Set<String> dismissedIds = const {},
    int firstIndex = 3,
    int interval = 6,
  }) {
    final activeSlots = getActiveSlots(
      realCount: realCount,
      banners: banners,
      dismissedIds: dismissedIds,
      firstIndex: firstIndex,
      interval: interval,
    );
    return realCount + activeSlots.length;
  }

  /// Determina si [visualIndex] corresponde a un banner y retorna dicho banner (o null si es un item real).
  static AdBanner? getBannerAtVisualIndex(
    int visualIndex, {
    required int realCount,
    required List<AdBanner> banners,
    Set<String> dismissedIds = const {},
    int firstIndex = 3,
    int interval = 6,
  }) {
    final activeSlots = getActiveSlots(
      realCount: realCount,
      banners: banners,
      dismissedIds: dismissedIds,
      firstIndex: firstIndex,
      interval: interval,
    );

    int insertedBannersBefore = 0;
    for (final slot in activeSlots) {
      final targetVisualIndex = slot.realItemThreshold + insertedBannersBefore;
      if (visualIndex == targetVisualIndex) {
        return slot.banner;
      }
      if (visualIndex > targetVisualIndex) {
        insertedBannersBefore++;
      }
    }

    return null;
  }

  /// Obtiene el índice del item real para una posición visual [visualIndex].
  static int getRealIndex(
    int visualIndex, {
    required int realCount,
    required List<AdBanner> banners,
    Set<String> dismissedIds = const {},
    int firstIndex = 3,
    int interval = 6,
  }) {
    final activeSlots = getActiveSlots(
      realCount: realCount,
      banners: banners,
      dismissedIds: dismissedIds,
      firstIndex: firstIndex,
      interval: interval,
    );

    int bannersBefore = 0;
    for (final slot in activeSlots) {
      final targetVisualIndex = slot.realItemThreshold + bannersBefore;
      if (visualIndex > targetVisualIndex) {
        bannersBefore++;
      }
    }

    return visualIndex - bannersBefore;
  }
}
