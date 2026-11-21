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
  final bool enableNetworkFallback;
  final NetworkTileProvider? _fallbackProvider;

  static final Uint8List transparentTileBytes = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  OfflineFirstTileProvider({
    required this.mountainId,
    required this.offlineBasePath,
    this.enableNetworkFallback = true,
    Map<String, String>? headers,
  }) : _fallbackProvider = enableNetworkFallback
           ? NetworkTileProvider(
               headers: Map<String, String>.of(headers ?? const {}),
               silenceExceptions: true,
             )
           : null,
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

    if (enableNetworkFallback && _fallbackProvider != null) {
      return _fallbackProvider.getImage(coordinates, options);
    }

    return MemoryImage(transparentTileBytes);
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

    if (enableNetworkFallback && _fallbackProvider != null) {
      return _fallbackProvider.getImageWithCancelLoadingSupport(
        coordinates,
        options,
        cancelLoading,
      );
    }

    return MemoryImage(transparentTileBytes);
  }
}

/// Layanan untuk mengunduh, mengecek status, dan mengelola paket peta offline gunung.
class OfflineMapService {
  static final Map<String, bool> _mapDownloadedCache = {};
  static final Map<String, int> _mountainMapSizesBytes = {};

  /// Mengambil status download peta dari memori cache (sinkron tanpa async disk I/O)
  static bool? isOfflineMapDownloadedCached(String mountainId) {
    return _mapDownloadedCache[mountainId];
  }

  /// Menyimpan status download peta ke memori cache
  static void setOfflineMapDownloadedCache(
    String mountainId,
    bool isDownloaded,
  ) {
    _mapDownloadedCache[mountainId] = isDownloaded;
  }

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

  /// Mendapatkan path direktori dasar folder offline_tiles
  static Future<String> getOfflineBaseDir() async {
    if (customOfflineBasePath != null) {
      return '$customOfflineBasePath/offline_tiles';
    }
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return '${Directory.systemTemp.path}/offline_tiles';
    }
    Directory appDir;
    try {
      appDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      appDir = Directory.systemTemp;
    }
    return '${appDir.path}/offline_tiles';
  }

  /// Mendapatkan direktori folder ubin offline untuk gunung tertentu
  static Future<Directory> getOfflineTilesDir(String mountainId) async {
    final basePath = await getOfflineBaseDir();
    return Directory('$basePath/$mountainId');
  }

  /// Memeriksa apakah paket peta offline untuk gunung ini sudah diunduh
  static Future<bool> isOfflineMapDownloaded(String mountainId) async {
    try {
      final dir = await getOfflineTilesDir(mountainId);
      if (!await dir.exists()) {
        _mapDownloadedCache[mountainId] = false;
        return false;
      }
      final metaFile = File('${dir.path}/.metadata.json');
      final exists = await metaFile.exists();
      _mapDownloadedCache[mountainId] = exists;
      return exists;
    } catch (_) {
      _mapDownloadedCache[mountainId] = false;
      return false;
    }
  }

  /// Menghitung ukuran berkas peta offline suatu gunung (dalam bytes) dengan caching
  static Future<int> getOfflineMapSizeBytes(String mountainId) async {
    if (_mountainMapSizesBytes.containsKey(mountainId)) {
      return _mountainMapSizesBytes[mountainId]!;
    }

    try {
      final dir = await getOfflineTilesDir(mountainId);
      if (!await dir.exists()) {
        _mountainMapSizesBytes[mountainId] = 0;
        return 0;
      }

      final metaFile = File('${dir.path}/.metadata.json');
      if (await metaFile.exists()) {
        try {
          final content = await metaFile.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          if (data['totalBytes'] is num) {
            final bytes = (data['totalBytes'] as num).toInt();
            _mountainMapSizesBytes[mountainId] = bytes;
            return bytes;
          }
        } catch (_) {}
      }

      // Fallback: hitung satu gunung, lalu simpan ke .metadata.json jika metaFile ada
      int totalBytes = 0;
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }

      _mountainMapSizesBytes[mountainId] = totalBytes;

      if (await metaFile.exists()) {
        try {
          final content = await metaFile.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          data['totalBytes'] = totalBytes;
          await metaFile.writeAsString(jsonEncode(data));
        } catch (_) {}
      }

      return totalBytes;
    } catch (_) {
      return 0;
    }
  }

  /// Menghitung total ukuran berkas peta offline dalam Megabyte (MB)
  static Future<double> getOfflineMapSizeMb(String mountainId) async {
    final bytes = await getOfflineMapSizeBytes(mountainId);
    return bytes / (1024 * 1024);
  }

  /// Menghitung total ukuran seluruh ubin peta offline yang tersimpan (dalam bytes)
  static Future<int> getTotalOfflineMapsSizeBytes() async {
    try {
      final basePath = await getOfflineBaseDir();
      final dir = Directory(basePath);
      if (!await dir.exists()) return 0;

      int totalBytes = 0;
      await for (final entity in dir.list(
        recursive: false,
        followLinks: false,
      )) {
        if (entity is Directory) {
          final mountainId = entity.uri.pathSegments
              .where((segment) => segment.isNotEmpty)
              .last;
          totalBytes += await getOfflineMapSizeBytes(mountainId);
        }
      }
      return totalBytes;
    } catch (e) {
      debugPrint('Error calculating total offline maps size: $e');
      return 0;
    }
  }

  /// Mengunduh seluruh ubin peta OpenTopoMap di sekitar area gunung.
  /// Secara default mengunduh zoom 16 (detail setapak).
  static Future<void> downloadOfflineMap({
    required String mountainId,
    required double centerLat,
    required double centerLng,
    List<LatLng>? trackPoints,
    int minZoom = 16,
    int maxZoom = 16,
    List<int>? zoomLevels,
    void Function(int downloaded, int total)? onProgress,
    bool Function()? isCancelled,
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
    final levels = zoomLevels ?? [for (int z = minZoom; z <= maxZoom; z++) z];

    final tiles = <({int z, int x, int y})>[];
    for (final z in levels) {
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
      if (isCancelled?.call() == true) {
        debugPrint('Download of map tiles for $mountainId cancelled.');
        client.close(force: true);
        return;
      }
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

    if (isCancelled?.call() == true) {
      client.close(force: true);
      return;
    }

    client.close();

    // 5. Hitung ukuran total dan simpan file metadata penanda unduhan selesai
    int totalBytes = 0;
    try {
      await for (final entity in mountainTilesDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
    } catch (_) {}

    final metaFile = File('${mountainTilesDir.path}/.metadata.json');
    await metaFile.writeAsString(
      jsonEncode({
        'mountainId': mountainId,
        'totalTiles': total,
        'totalBytes': totalBytes,
        'zoomLevels': levels,
        'downloadedAt': DateTime.now().toIso8601String(),
        'attribution':
            'Kartendaten: © OpenStreetMap-Mitwirkende, SRTM | Kartendarstellung: © OpenTopoMap (CC-BY-SA)',
      }),
    );
    _mapDownloadedCache[mountainId] = true;
    _mountainMapSizesBytes[mountainId] = totalBytes;
  }

  /// Menghapus seluruh paket tile peta offline suatu gunung
  static Future<void> deleteOfflineMap(String mountainId) async {
    _mapDownloadedCache[mountainId] = false;
    _mountainMapSizesBytes.remove(mountainId);
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
