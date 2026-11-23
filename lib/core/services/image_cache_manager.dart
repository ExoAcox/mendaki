import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'supabase_service.dart';

/// Cache Manager khusus untuk gambar gunung dengan masa stale 30 hari (1 bulan)
/// Mendukung HTTP ETag (304 Not Modified) otomatis saat file tidak berubah di server.
class MountainImageCacheManager {
  static const String key = 'mountain_image_cache';

  static final CacheInfoRepository _repo = !kIsWeb &&
          (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
      ? CacheObjectProvider(databaseName: key)
      : JsonCacheInfoRepository(databaseName: key);

  static CacheManager? _instance;
  static CacheManager get instance {
    return _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 200,
        repo: _repo,
      ),
    );
  }

  @visibleForTesting
  static set mockInstance(CacheManager? mock) {
    _instance = mock;
  }

  /// Mereset stale time (validTill) seluruh cache gambar agar dianggap expired/stale,
  /// TANPA menghapus file fisik di disk dan TANPA melakukan request network sekaligus (upfront).
  ///
  /// Dengan menandai validTill kedaluwarsa:
  /// 1. CachedNetworkImage di UI langsung menampilkan file cache yang sudah ada dari disk (tidak ada blank/flicker).
  /// 2. flutter_cache_manager secara otomatis (lazy) mengecek HTTP ETag (If-None-Match) di latar belakang
  ///    hanya untuk gambar yang sedang tampil / dirender di halaman tersebut.
  static Future<void> resetStaleTime() async {
    try {
      PaintingBinding.instance.imageCache.clearLiveImages();
      PaintingBinding.instance.imageCache.clear();

      if (Platform.environment.containsKey('FLUTTER_TEST')) return;

      // 1. Kosongkan memori cache pada CacheStore agar widget mengevaluasi ulang data dari DB
      instance.store.emptyMemoryCache();

      // 2. Set validTill = 0 (expired) pada metadata cache
      await _repo.open();
      if (_repo is CacheObjectProvider) {
        final db = (_repo as CacheObjectProvider).db;
        if (db != null && db.isOpen) {
          await db.execute('UPDATE cacheObject SET validTill = 0');
          debugPrint('🔄 MountainImageCacheManager: Stale time reset (validTill = 0) via SQLite');
          return;
        }
      }

      final allObjects = await _repo.getAllObjects();
      final expired = DateTime.fromMillisecondsSinceEpoch(0);
      for (final obj in allObjects) {
        await _repo.update(obj.copyWith(validTill: expired), setTouchedToNow: false);
      }
      debugPrint('🔄 MountainImageCacheManager: Stale time reset untuk ${allObjects.length} objek cache');
    } catch (e) {
      debugPrint('Error resetting mountain image cache stale time: $e');
    }
  }

  /// Mengecek dan menyinkronkan ETag untuk daftar URL gambar secara langsung.
  /// Mengirimkan HTTP request dengan If-None-Match.
  /// - Jika server merespons 304 (Not Modified), file lokal tetap digunakan tanpa download data ulang.
  /// - Jika server merespons 200 (gambar diperbarui di server), file baru diunduh dan cache diupdate.
  /// Mengembalikan true jika ada setidaknya satu gambar yang diperbarui.
  static Future<bool> revalidateImages(List<String> imageUrls) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    if (imageUrls.isEmpty) return false;

    final uniqueUrls = imageUrls
        .where(
          (u) =>
              u.isNotEmpty &&
              (u.startsWith('http://') || u.startsWith('https://')),
        )
        .toSet();

    if (uniqueUrls.isEmpty) return false;

    bool anyUpdated = false;

    await Future.wait(
      uniqueUrls.map((url) async {
        try {
          final fileInfo = await instance.downloadFile(url, force: true);
          if (fileInfo.statusCode == 200) {
            anyUpdated = true;
            debugPrint('🔄 ETag berubah, gambar baru diunduh untuk: $url');
            await CachedNetworkImageProvider(url, cacheManager: instance).evict();
          } else if (fileInfo.statusCode == 304) {
            debugPrint('✅ ETag cocok (304 Not Modified) untuk: $url');
          }
        } catch (e) {
          debugPrint('Gagal memeriksa ETag gambar $url: $e');
        }
      }),
    );

    if (anyUpdated) {
      PaintingBinding.instance.imageCache.clearLiveImages();
    }

    return anyUpdated;
  }

  /// Mengecek ETag untuk seluruh gambar gunung di Supabase
  static Future<bool> revalidateAll({List<String>? fallbackUrls}) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    try {
      var urls = await SupabaseService.getAllImageUrls();
      if (urls.isEmpty && fallbackUrls != null && fallbackUrls.isNotEmpty) {
        urls = fallbackUrls;
      }
      if (urls.isNotEmpty) {
        return await revalidateImages(urls);
      }
    } catch (e) {
      debugPrint('Error revalidating all mountain images: $e');
    }
    return false;
  }
}
