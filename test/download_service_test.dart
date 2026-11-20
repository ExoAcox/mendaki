import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/services/download_service.dart';
import 'package:mendaki/models/mountain.dart';

void main() {
  group('DownloadService Tests', () {
    const testMountain = Mountain(
      id: 'test_mountain',
      name: 'Gunung Uji Coba',
      elevation: 2000,
      location: 'Kabupaten Uji',
      province: 'Jawa Tengah',
      difficulty: 'Mudah',
      estimatedTime: '1D',
    );

    test('Initial download state is false for GPX and Map', () {
      expect(DownloadService.instance.isDownloadingGpx('test_mountain'), isFalse);
      expect(DownloadService.instance.isDownloadingMap('test_mountain'), isFalse);
      expect(DownloadService.instance.getGpxProgress('test_mountain'), 0.0);
      expect(DownloadService.instance.getMapProgress('test_mountain'), 0.0);
    });

    test('cancelDownload for GPX cancels only GPX task', () async {
      int notifyCount = 0;
      void listener() {
        notifyCount++;
      }

      DownloadService.instance.addListener(listener);

      final future = DownloadService.instance.startGpxDownload(testMountain);
      expect(DownloadService.instance.isDownloadingGpx('test_mountain'), isTrue);
      expect(DownloadService.instance.isDownloadingMap('test_mountain'), isFalse);

      await DownloadService.instance.cancelDownload('test_mountain', type: DownloadType.gpx);
      expect(DownloadService.instance.isDownloadingGpx('test_mountain'), isFalse);

      await future;
      DownloadService.instance.removeListener(listener);

      expect(notifyCount, greaterThan(0));
    });

    test('cancelDownload for Map cancels only Map task', () async {
      int notifyCount = 0;
      void listener() {
        notifyCount++;
      }

      DownloadService.instance.addListener(listener);

      final future = DownloadService.instance.startMapDownload(testMountain);
      expect(DownloadService.instance.isDownloadingMap('test_mountain'), isTrue);
      expect(DownloadService.instance.isDownloadingGpx('test_mountain'), isFalse);

      await DownloadService.instance.cancelDownload('test_mountain', type: DownloadType.map);
      expect(DownloadService.instance.isDownloadingMap('test_mountain'), isFalse);

      await future;
      DownloadService.instance.removeListener(listener);

      expect(notifyCount, greaterThan(0));
    });
  });
}
