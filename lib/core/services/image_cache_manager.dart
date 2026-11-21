import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache Manager khusus untuk gambar gunung dengan masa stale 30 hari (1 bulan)
/// Mendukung HTTP ETag (304 Not Modified) otomatis saat file tidak berubah di server.
class MountainImageCacheManager {
  static const String key = 'mountain_image_cache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
    ),
  );
}

