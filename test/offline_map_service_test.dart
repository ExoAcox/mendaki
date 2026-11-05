import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/services/offline_map_service.dart';

void main() {
  group('OfflineMapService Math & Coordinates Test', () {
    test('lon2tileX and lat2tileY convert correctly for Merbabu coordinates', () {
      const lat = -7.455;
      const lon = 110.435;

      final tileX12 = OfflineMapService.lon2tileX(lon, 12);
      final tileY12 = OfflineMapService.lat2tileY(lat, 12);

      expect(tileX12, 3304);
      expect(tileY12, 2133);

      final tileX15 = OfflineMapService.lon2tileX(lon, 15);
      final tileY15 = OfflineMapService.lat2tileY(lat, 15);

      expect(tileX15, 26436);
      expect(tileY15, 17064);
    });

    test('isOfflineMapDownloaded returns false when directory is empty', () async {
      final isDownloaded = await OfflineMapService.isOfflineMapDownloaded(
        'gunung_dummy_non_existent',
      );
      expect(isDownloaded, isFalse);
    });

    test('OfflineFirstTileProvider headers is always mutable even if const map passed', () {
      final provider = OfflineFirstTileProvider(
        mountainId: 'merbabu',
        offlineBasePath: '/tmp/test_dir',
        headers: const {'Existing': 'Value'},
      );

      // Pastikan TileLayer bisa menambahkan 'User-Agent' via putIfAbsent tanpa throw error unmodifiable map
      expect(
        () => provider.headers.putIfAbsent('User-Agent', () => 'flutter_map (test)'),
        returnsNormally,
      );
      expect(provider.headers['User-Agent'], 'flutter_map (test)');
    });

    test('OfflineFirstTileProvider supportsCancelLoading is true', () {
      final provider = OfflineFirstTileProvider(
        mountainId: 'merbabu',
        offlineBasePath: '/tmp/test_dir',
      );

      expect(provider.supportsCancelLoading, isTrue);
    });
  });
}
