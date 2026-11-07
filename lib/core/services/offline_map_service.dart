import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

/// Provider tile peta yang memprioritaskan membaca berkas ubin (tile)
/// dari penyimpanan lokal offline di perangkat pengguna.
/// Jika belum tersedia di lokal, akan memanggil fallback network secara mulus.
class OfflineFirstTileProvider extends TileProvider {
  final String mountainId;
  final String offlineBasePath;
  final NetworkTileProvider _fallbackProvider;

  OfflineFirstTileProvider({
    required this.mountainId,
    required this.offlineBasePath,
    Map<String, String>? headers,
  }) : _fallbackProvider = NetworkTileProvider(
         headers: Map<String, String>.of(headers ?? const {}),
         silenceExceptions: true,
       ),
       super(headers: Map<String, String>.of(headers ?? const {}));

  @override
  bool get supportsCancelLoading => true;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final offlineFile = File(
      '$offlineBasePath/offline_tiles/$mountainId/${coordinates.z}/${coordinates.x}/${coordinates.y}.png',
    );

    if (offlineFile.existsSync()) {
      return FileImage(offlineFile);
    }

    return _fallbackProvider.getImage(coordinates, options);
  }

  @override
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) {
    final offlineFile = File(
      '$offlineBasePath/offline_tiles/$mountainId/${coordinates.z}/${coordinates.x}/${coordinates.y}.png',
    );

    if (offlineFile.existsSync()) {
      return FileImage(offlineFile);
    }

    return _fallbackProvider.getImageWithCancelLoadingSupport(
      coordinates,
      options,
      cancelLoading,
    );
  }
}

/// Layanan untuk mengunduh, mengecek status, dan mengelola paket peta offline gunung.
class OfflineMapService {
  /// Mengonversi bujur (longitude) ke koordinat tile X
  static int lon2tileX(double lon, int z) =>
      ((lon + 180.0) / 360.0 * (1 << z)).floor();

  /// Mengonversi lintang (latitude) ke koordinat tile Y
  static int lat2tileY(double lat, int z) {
    final clampedLat = lat.clamp(-85.0511, 85.0511);
    final rad = clampedLat * pi / 180.0;
    return ((1.0 - log(tan(rad) + 1.0 / cos(rad)) / pi) / 2.0 * (1 << z))
        .floor();
  }

  @visibleForTesting
  static String? customOfflineBasePath;

  /// Mendapatkan direktori folder ubin offline untuk gunung tertentu
  static Future<Directory> getOfflineTilesDir(String mountainId) async {
    if (customOfflineBasePath != null) {
      return Directory('$customOfflineBasePath/offline_tiles/$mountainId');
    }
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Directory('${Directory.systemTemp.path}/offline_tiles/$mountainId');
    }
    Directory appDir;
    try {
      appDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      appDir = Directory.systemTemp;
    }
    final dir = Directory('${appDir.path}/offline_tiles/$mountainId');
    return dir;
  }

  /// Memeriksa apakah paket peta offline untuk gunung ini sudah diunduh
  static Future<bool> isOfflineMapDownloaded(String mountainId) async {
    try {
      final dir = await getOfflineTilesDir(mountainId);
      if (!await dir.exists()) return false;
      final metaFile = File('${dir.path}/.metadata.json');
      return await metaFile.exists();
    } catch (_) {
      return false;
    }
  }

  /// Menghitung total ukuran berkas peta offline dalam Megabyte (MB)
  static Future<double> getOfflineMapSizeMb(String mountainId) async {
    try {
      final dir = await getOfflineTilesDir(mountainId);
      if (!await dir.exists()) return 0.0;

      int totalBytes = 0;
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return totalBytes / (1024 * 1024);
    } catch (_) {
      return 0.0;
    }
  }

  /// Mengunduh seluruh ubin peta OpenTopoMap di sekitar area gunung
  /// untuk rentang zoom level 11 (tinjauan makro) sampai 15 (jalur rinci).
  static Future<void> downloadOfflineMap({
    required String mountainId,
    required double centerLat,
    required double centerLng,
    List<LatLng>? trackPoints,
    int minZoom = 11,
    int maxZoom = 15,
    void Function(int downloaded, int total)? onProgress,
  }) async {
    // 1. Tentukan batas koordinat bounding box
    double minLat;
    double maxLat;
    double minLng;
    double maxLng;

    if (trackPoints != null && trackPoints.isNotEmpty) {
      minLat = trackPoints.first.latitude;
      maxLat = trackPoints.first.latitude;
      minLng = trackPoints.first.longitude;
      maxLng = trackPoints.first.longitude;

      for (final pt in trackPoints) {
        if (pt.latitude < minLat) minLat = pt.latitude;
        if (pt.latitude > maxLat) maxLat = pt.latitude;
        if (pt.longitude < minLng) minLng = pt.longitude;
        if (pt.longitude > maxLng) maxLng = pt.longitude;
      }
      // Tambahkan batas aman 0.03 derajat (~3.3 km) di sekeliling seluruh trek
      minLat -= 0.03;
      maxLat += 0.03;
      minLng -= 0.03;
      maxLng += 0.03;
    } else {
      // Fallback jika belum ada data koordinat rute: radius 0.045 derajat
      minLat = centerLat - 0.045;
      maxLat = centerLat + 0.045;
      minLng = centerLng - 0.045;
      maxLng = centerLng + 0.045;
    }

    // 2. Kumpulkan daftar tile yang perlu diunduh
    final tiles = <({int z, int x, int y})>[];
    for (int z = minZoom; z <= maxZoom; z++) {
      final minX = lon2tileX(minLng, z);
      final maxX = lon2tileX(maxLng, z);
      final minY = lat2tileY(
        maxLat,
        z,
      ); // Kutub utara memiliki nilai Y lebih kecil
      final maxY = lat2tileY(minLat, z);

      for (int x = minX; x <= maxX; x++) {
        for (int y = minY; y <= maxY; y++) {
          tiles.add((z: z, x: x, y: y));
        }
      }
    }

    final total = tiles.length;
    if (total == 0) return;

    // 3. Siapkan direktori penyimpanan
    final mountainTilesDir = await getOfflineTilesDir(mountainId);
    if (!await mountainTilesDir.exists()) {
      await mountainTilesDir.create(recursive: true);
    }

    // 4. Unduh ubin secara efisien dengan pool worker konkuren (4 worker)
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 12);
    client.userAgent = 'ayo.mendaki.bersama';

    int downloaded = 0;
    const concurrency = 4;

    for (int i = 0; i < tiles.length; i += concurrency) {
      final chunk = tiles.sublist(i, (i + concurrency).clamp(0, tiles.length));
      await Future.wait(
        chunk.map((tile) async {
          final file = File(
            '${mountainTilesDir.path}/${tile.z}/${tile.x}/${tile.y}.png',
          );
          if (await file.exists() && await file.length() > 500) {
            downloaded++;
            onProgress?.call(downloaded, total);
            return;
          }

          try {
            final uri = Uri.parse(
              'https://tile.opentopomap.org/${tile.z}/${tile.x}/${tile.y}.png',
            );
            final request = await client.getUrl(uri);
            final response = await request.close();

            if (response.statusCode == 200) {
              await file.parent.create(recursive: true);
              final bytesBuilder = await response.fold<BytesBuilder>(
                BytesBuilder(),
                (builder, data) => builder..add(data),
              );
              await file.writeAsBytes(bytesBuilder.takeBytes());
            }
          } catch (e) {
            debugPrint(
              'Failed to download tile ${tile.z}/${tile.x}/${tile.y}: $e',
            );
          } finally {
            downloaded++;
            onProgress?.call(downloaded, total);
          }
        }),
      );
    }

    client.close();

    // 5. Simpan file metadata penanda unduhan selesai
    final metaFile = File('${mountainTilesDir.path}/.metadata.json');
    await metaFile.writeAsString(
      jsonEncode({
        'mountainId': mountainId,
        'totalTiles': total,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'downloadedAt': DateTime.now().toIso8601String(),
        'attribution':
            'Kartendaten: © OpenStreetMap-Mitwirkende, SRTM | Kartendarstellung: © OpenTopoMap (CC-BY-SA)',
      }),
    );
  }

  /// Menghapus seluruh paket tile peta offline suatu gunung
  static Future<void> deleteOfflineMap(String mountainId) async {
    try {
      final dir = await getOfflineTilesDir(mountainId);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error deleting offline map: $e');
    }
  }
}
