import 'package:flutter_test/flutter_test.dart';
import 'package:d_una_app/shared/utils/ad_list_position_helper.dart';
import 'package:d_una_app/features/ads/domain/models/ad_banner_model.dart';

void main() {
  group('AdListPositionHelper', () {
    final bannerA = AdBanner(id: 'banner_a', title: 'Banner A');
    final bannerB = AdBanner(id: 'banner_b', title: 'Banner B');
    final sampleBanners = [bannerA, bannerB];

    test('retorna vacio si la lista de items reales es 0 o banners vacio', () {
      final slotsEmptyReal = AdListPositionHelper.getActiveSlots(
        realCount: 0,
        banners: sampleBanners,
      );
      expect(slotsEmptyReal, isEmpty);
      expect(
        AdListPositionHelper.calculateTotalCount(
          realCount: 0,
          banners: sampleBanners,
        ),
        0,
      );

      final slotsEmptyBanners = AdListPositionHelper.getActiveSlots(
        realCount: 10,
        banners: const [],
      );
      expect(slotsEmptyBanners, isEmpty);
      expect(
        AdListPositionHelper.calculateTotalCount(
          realCount: 10,
          banners: const [],
        ),
        10,
      );
    });

    test('retorna vacio si la lista de items reales es menor que firstIndex', () {
      final slots = AdListPositionHelper.getActiveSlots(
        realCount: 2,
        banners: sampleBanners,
        firstIndex: 3,
      );
      expect(slots, isEmpty);
      expect(
        AdListPositionHelper.calculateTotalCount(
          realCount: 2,
          banners: sampleBanners,
          firstIndex: 3,
        ),
        2,
      );
      expect(
        AdListPositionHelper.getBannerAtVisualIndex(
          0,
          realCount: 2,
          banners: sampleBanners,
        ),
        isNull,
      );
    });

    test('calcula correctamente slots para 10 items con firstIndex=3 e interval=6', () {
      final total = AdListPositionHelper.calculateTotalCount(
        realCount: 10,
        banners: sampleBanners,
        firstIndex: 3,
        interval: 6,
      );
      // 10 items + 2 banners (en thresholds 3 y 8) = 12 total
      expect(total, 12);

      final slots = AdListPositionHelper.getActiveSlots(
        realCount: 10,
        banners: sampleBanners,
        firstIndex: 3,
        interval: 6,
      );
      expect(slots.length, 2);
      expect(slots[0].realItemThreshold, 3);
      expect(slots[0].banner.id, 'banner_a');
      expect(slots[1].realItemThreshold, 8);
      expect(slots[1].banner.id, 'banner_b');

      // Visual 3 debe ser banner A
      expect(
        AdListPositionHelper.getBannerAtVisualIndex(
          3,
          realCount: 10,
          banners: sampleBanners,
        )?.id,
        'banner_a',
      );

      // Visual 9 debe ser banner B (threshold 8 + 1 banner previo)
      expect(
        AdListPositionHelper.getBannerAtVisualIndex(
          9,
          realCount: 10,
          banners: sampleBanners,
        )?.id,
        'banner_b',
      );

      // Visual 0, 1, 2, 4, 8, 10, 11 no deben ser banners
      for (final idx in [0, 1, 2, 4, 5, 6, 7, 8, 10, 11]) {
        expect(
          AdListPositionHelper.getBannerAtVisualIndex(
            idx,
            realCount: 10,
            banners: sampleBanners,
          ),
          isNull,
        );
      }

      // Mapeo de indices reales:
      // Visual 0..2 -> Real 0..2
      expect(AdListPositionHelper.getRealIndex(0, realCount: 10, banners: sampleBanners), 0);
      expect(AdListPositionHelper.getRealIndex(1, realCount: 10, banners: sampleBanners), 1);
      expect(AdListPositionHelper.getRealIndex(2, realCount: 10, banners: sampleBanners), 2);
      // Visual 4 -> Real 3 (descuenta 1 banner previo)
      expect(AdListPositionHelper.getRealIndex(4, realCount: 10, banners: sampleBanners), 3);
      // Visual 8 -> Real 7
      expect(AdListPositionHelper.getRealIndex(8, realCount: 10, banners: sampleBanners), 7);
      // Visual 10 -> Real 8 (descuenta 2 banners previos)
      expect(AdListPositionHelper.getRealIndex(10, realCount: 10, banners: sampleBanners), 8);
      // Visual 11 -> Real 9
      expect(AdListPositionHelper.getRealIndex(11, realCount: 10, banners: sampleBanners), 9);
    });

    test('omite banners descartados en dismissedIds dinamicamente', () {
      final totalWithDismiss = AdListPositionHelper.calculateTotalCount(
        realCount: 10,
        banners: sampleBanners,
        dismissedIds: {'banner_a'},
      );
      // Solo banner B activo -> 10 + 1 = 11
      expect(totalWithDismiss, 11);

      // Visual 3 ya no es banner
      expect(
        AdListPositionHelper.getBannerAtVisualIndex(
          3,
          realCount: 10,
          banners: sampleBanners,
          dismissedIds: {'banner_a'},
        ),
        isNull,
      );

      // Visual 8 es ahora el banner B (threshold 8 + 0 previos)
      expect(
        AdListPositionHelper.getBannerAtVisualIndex(
          8,
          realCount: 10,
          banners: sampleBanners,
          dismissedIds: {'banner_a'},
        )?.id,
        'banner_b',
      );
    });
  });
}
