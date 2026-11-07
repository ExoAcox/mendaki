import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mendaki/core/config/supabase_config.dart';
import 'package:mendaki/core/services/gpx_parser_service.dart';
import 'package:mendaki/core/services/offline_map_service.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:path_provider/path_provider.dart';

class GpxStorageService {
  @visibleForTesting
  static String? customGpxDirectoryPath;

  /// Mendapatkan path direktori penyimpanan GPX offline
  static Future<String> getGpxDirectoryPath() async {
    if (customGpxDirectoryPath != null) {
      final gpxDir = Directory('$customGpxDirectoryPath/gpx');
      if (!await gpxDir.exists()) {
        await gpxDir.create(recursive: true);
      }
      return gpxDir.path;
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      final gpxDir = Directory('${Directory.systemTemp.path}/gpx');
      if (!await gpxDir.exists()) {
        await gpxDir.create(recursive: true);
      }
      return gpxDir.path;
    }

    Directory targetDir;
    try {
      targetDir = await getApplicationDocumentsDirectory();
    } catch (e) {
      debugPrint(
        'path_provider belum ter-link di binary yang berjalan. Menggunakan fallback direktori sistem: $e',
      );
      targetDir = Directory.systemTemp;
    }

    final gpxDir = Directory('${targetDir.path}/gpx');
    if (!await gpxDir.exists()) {
      await gpxDir.create(recursive: true);
    }
    return gpxDir.path;
  }

  /// Mendapatkan path file GPX lokal untuk suatu gunung
  static Future<String> getLocalGpxFilePath(String mountainId) async {
    final dirPath = await getGpxDirectoryPath();
    return '$dirPath/$mountainId.gpx';
  }

  /// Mendapatkan path file metadata GPX untuk caching dan versioning (ETag)
  static Future<String> getLocalMetadataFilePath(String mountainId) async {
    final dirPath = await getGpxDirectoryPath();
    return '$dirPath/$mountainId.meta.json';
  }

  /// Mendapatkan path file data gunung lokal (JSON)
  static Future<String> getLocalMountainFilePath(String mountainId) async {
    final dirPath = await getGpxDirectoryPath();
    return '$dirPath/$mountainId.mountain.json';
  }

  /// Mendapatkan path file foto gunung lokal
  static Future<String> getLocalImageFilePath(String mountainId) async {
    final dirPath = await getGpxDirectoryPath();
    return '$dirPath/$mountainId.image.jpg';
  }

  /// Menyimpan data Mountain lengkap beserta routes & foto secara offline
  static Future<void> saveDownloadedMountain(Mountain mountain) async {
    try {
      String? localImagePath;

      // Unduh & simpan foto gunung secara offline jika ada URL
      if (mountain.imageUrl != null && mountain.imageUrl!.isNotEmpty) {
        final imgPath = await getLocalImageFilePath(mountain.id);
        final imgFile = File(imgPath);
        if (!await imgFile.exists() || await imgFile.length() == 0) {
          final client = HttpClient();
          try {
            final request = await client.getUrl(Uri.parse(mountain.imageUrl!));
            final response = await request.close();
            if (response.statusCode == 200) {
              final sink = imgFile.openWrite();
              await response.pipe(sink);
              localImagePath = imgPath;
            }
          } catch (e) {
            debugPrint('Gagal mengunduh foto gunung ${mountain.id} offline: $e');
          } finally {
            client.close();
          }
        } else {
          localImagePath = imgPath;
        }
      }

      final isMap = await OfflineMapService.isOfflineMapDownloaded(mountain.id);
      final isGpx = await isGpxDownloaded(mountain.id);

      final mountainToSave = mountain.copyWith(
        isGpxReady: isGpx || mountain.isGpxReady,
        isMapReady: isMap || mountain.isMapReady,
        localImagePath: localImagePath ?? mountain.localImagePath,
      );

      final filePath = await getLocalMountainFilePath(mountain.id);
      final file = File(filePath);
      await file.writeAsString(jsonEncode(mountainToSave.toJson()));
      debugPrint('✅ Data gunung & rute ${mountain.id} berhasil disimpan offline di $filePath');
    } catch (e) {
      debugPrint('Error menyimpan data gunung offline: $e');
    }
  }

  /// Mengambil data Mountain dari penyimpanan lokal offline
  static Future<Mountain?> getDownloadedMountain(String mountainId) async {
    try {
      final filePath = await getLocalMountainFilePath(mountainId);
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        var m = Mountain.fromJson(json);

        // Periksa apakah foto lokal ada
        final imgPath = await getLocalImageFilePath(mountainId);
        if (await File(imgPath).exists()) {
          m = m.copyWith(localImagePath: imgPath);
        }
        final isGpx = await isGpxDownloaded(mountainId);
        final isMap = await OfflineMapService.isOfflineMapDownloaded(mountainId);
        return m.copyWith(isGpxReady: isGpx, isMapReady: isMap);
      }
    } catch (e) {
      debugPrint('Error membaca data gunung offline untuk $mountainId: $e');
    }
    return null;
  }

  /// Mengambil semua daftar Mountain yang sudah tersimpan offline di perangkat.
  /// Jika [onlyFullyReady] bernilai true, hanya mengembalikan gunung yang kedua-duanya
  /// (berkas GPX dan paket peta offline) sudah siap di perangkat.
  static Future<List<Mountain>> getDownloadedMountains({
    bool onlyFullyReady = true,
  }) async {
    final List<Mountain> list = [];
    final Set<String> processedIds = {};

    try {
      final dirPath = await getGpxDirectoryPath();
      final dir = Directory(dirPath);
      if (!await dir.exists()) return [];

      final files = dir.listSync();

      // 1. Baca semua file .mountain.json
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.mountain.json')) {
          try {
            final content = await entity.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            var m = Mountain.fromJson(json);
            final imgPath = await getLocalImageFilePath(m.id);
            if (await File(imgPath).exists()) {
              m = m.copyWith(localImagePath: imgPath);
            }
            final isGpx = await isGpxDownloaded(m.id);
            final isMap = await OfflineMapService.isOfflineMapDownloaded(m.id);

            if (onlyFullyReady && (!isGpx || !isMap)) {
              continue;
            }

            list.add(m.copyWith(isGpxReady: isGpx, isMapReady: isMap));
            processedIds.add(m.id);
          } catch (e) {
            debugPrint('Error parse ${entity.path}: $e');
          }
        }
      }

      // 2. Pemulihan otomatis: jika file .gpx ada di disk tapi belum ada file .mountain.json
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.gpx')) {
          final fileName = entity.uri.pathSegments.last;
          final mountainId = fileName.substring(0, fileName.length - 4);
          if (!processedIds.contains(mountainId) && await entity.length() > 0) {
            try {
              final isMap =
                  await OfflineMapService.isOfflineMapDownloaded(mountainId);
              if (onlyFullyReady && !isMap) {
                continue;
              }
              final gpxData = await GpxParserService.parseFile(entity);
              final m = Mountain(
                id: mountainId,
                name: gpxData.name.isNotEmpty
                    ? gpxData.name
                    : Mountain.formatRouteName(mountainId),
                elevation: 0,
                location: '',
                province: '',
                difficulty: 'Sedang',
                estimatedTime: '',
                isGpxReady: true,
                isMapReady: isMap,
              );
              list.add(m);
              processedIds.add(mountainId);
              saveDownloadedMountain(m);
            } catch (e) {
              debugPrint('Error recovering mountain from gpx $fileName: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error getDownloadedMountains: $e');
    }
    return list;
  }

  /// Menghitung total gunung yang sudah tersimpan offline lengkap di perangkat
  static Future<int> getDownloadedMountainsCount({
    bool onlyFullyReady = true,
  }) async {
    final list = await getDownloadedMountains(onlyFullyReady: onlyFullyReady);
    return list.length;
  }

  /// Menghapus paket data gunung offline (gpx, metadata, mountain json, foto)
  static Future<void> deleteDownloadedMountain(String mountainId) async {
    try {
      final gpxPath = await getLocalGpxFilePath(mountainId);
      final metaPath = await getLocalMetadataFilePath(mountainId);
      final mtnPath = await getLocalMountainFilePath(mountainId);
      final imgPath = await getLocalImageFilePath(mountainId);

      for (final p in [gpxPath, metaPath, mtnPath, imgPath]) {
        final f = File(p);
        if (await f.exists()) {
          await f.delete();
        }
      }
    } catch (e) {
      debugPrint('Error deleting downloaded mountain $mountainId: $e');
    }
  }

  /// Membaca metadata GPX lokal
  static Future<Map<String, dynamic>?> getLocalMetadata(String mountainId) async {
    try {
      final metaPath = await getLocalMetadataFilePath(mountainId);
      final metaFile = File(metaPath);
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error membaca metadata untuk $mountainId: $e');
    }
    return null;
  }

  /// Menyimpan metadata GPX lokal (ETag, Last-Modified, size)
  static Future<void> saveLocalMetadata({
    required String mountainId,
    String? etag,
    String? lastModified,
    int? contentLength,
  }) async {
    try {
      final metaPath = await getLocalMetadataFilePath(mountainId);
      final metaFile = File(metaPath);
      final data = {
        'etag': etag,
        'lastModified': lastModified,
        'contentLength': contentLength,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await metaFile.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error menyimpan metadata untuk $mountainId: $e');
    }
  }

  /// Mengecek apakah file GPX untuk gunung ini sudah tersimpan di perangkat
  static Future<bool> isGpxDownloaded(String mountainId) async {
    try {
      final filePath = await getLocalGpxFilePath(mountainId);
      final file = File(filePath);
      if (await file.exists()) {
        final length = await file.length();
        return length > 0;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Mengambil objek File GPX lokal jika ada
  static Future<File?> getLocalGpxFile(String mountainId) async {
    final filePath = await getLocalGpxFilePath(mountainId);
    final file = File(filePath);
    if (await file.exists() && await file.length() > 0) {
      return file;
    }
    return null;
  }

  /// Mengecek apakah ada pembaruan GPX di Supabase Storage via HTTP HEAD (ETag / Last-Modified).
  /// Jika terdeteksi file baru atau belum ada di lokal, otomatis mengunduh dan mengembalikan File yang baru.
  /// Jika file lokal sudah yang terbaru, mengembalikan null.
  static Future<File?> checkAndSyncGpx({
    required String mountainId,
    void Function(double progress)? onProgress,
  }) async {
    final url =
        '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/${SupabaseConfig.gpxBucket}/$mountainId.gpx';

    final client = HttpClient();
    try {
      // 1. Kirim HTTP HEAD request (ringan, 0 byte payload)
      final request = await client.openUrl('HEAD', Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        debugPrint(
          'HTTP HEAD untuk $mountainId.gpx status ${response.statusCode}',
        );
        return null;
      }

      final remoteEtag = response.headers.value('etag');
      final remoteLastModified = response.headers.value('last-modified');
      final remoteContentLength = response.contentLength;

      // 2. Bandingkan dengan metadata lokal
      final localFile = await getLocalGpxFile(mountainId);
      final localMeta = await getLocalMetadata(mountainId);

      if (localFile != null && localMeta != null) {
        final localEtag = localMeta['etag'];
        final localLastMod = localMeta['lastModified'];

        // Jika ETag cocok (atau fallback last-modified cocok), file lokal sudah versi terbaru
        final isMatch = (remoteEtag != null && remoteEtag == localEtag) ||
            (remoteEtag == null &&
                remoteLastModified != null &&
                remoteLastModified == localLastMod &&
                localFile.lengthSync() == remoteContentLength);

        if (isMatch) {
          debugPrint(
            '✅ File GPX $mountainId sudah up-to-date (ETag cocok: $remoteEtag)',
          );
          return null;
        }
      }

      // 3. ETag berbeda atau metadata belum ada -> download pembaruan
      debugPrint(
        '🔄 Versi baru GPX terdeteksi di Supabase untuk $mountainId (Remote ETag: $remoteEtag, Local: ${localMeta?['etag']}). Mengunduh versi terbaru...',
      );

      final updatedFile = await downloadAndSaveGpx(
        mountainId: mountainId,
        onProgress: onProgress,
      );

      return updatedFile;
    } catch (e) {
      debugPrint('Error saat sinkronisasi GPX $mountainId: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Mengunduh file GPX dari Supabase Storage dengan streaming progress (0.0 - 1.0)
  /// dan otomatis menyimpan metadata ETag untuk sinkronisasi berikutnya
  static Future<File> downloadAndSaveGpx({
    required String mountainId,
    void Function(double progress)? onProgress,
  }) async {
    final finalPath = await getLocalGpxFilePath(mountainId);
    final tempPath = '$finalPath.tmp';
    final tempFile = File(tempPath);

    // Hapus file sementara jika ada dari proses sebelumnya yang terputus
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final url =
        '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/${SupabaseConfig.gpxBucket}/$mountainId.gpx';

    final client = HttpClient();
    IOSink? sink;

    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException(
          'Gagal mengunduh file GPX (HTTP ${response.statusCode})',
          uri: Uri.parse(url),
        );
      }

      final etag = response.headers.value('etag');
      final lastModified = response.headers.value('last-modified');
      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      sink = tempFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        if (totalBytes > 0 && onProgress != null) {
          final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          onProgress(progress);
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      // Pindahkan dari temp ke final file secara atomik
      final finalFile = File(finalPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(finalPath);

      // Simpan metadata ETag & Last-Modified untuk auto-update
      await saveLocalMetadata(
        mountainId: mountainId,
        etag: etag,
        lastModified: lastModified,
        contentLength: totalBytes,
      );

      if (onProgress != null) {
        onProgress(1.0);
      }

      return finalFile;
    } catch (e) {
      debugPrint('Error saat mengunduh GPX: $e');
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      client.close();
    }
  }
}
