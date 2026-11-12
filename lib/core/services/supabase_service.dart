import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mendaki/core/config/supabase_config.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';

class SupabaseService {
  static bool _isInitialized = false;

  /// Inisialisasi Supabase saat aplikasi dibuka
  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint(
        'ℹ️ Supabase belum dikonfigurasi. Buat file .env dari .env.example dan jalankan dengan: flutter run --dart-define-from-file=.env',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('✅ Supabase berhasil diinisialisasi.');
    } catch (e) {
      debugPrint('❌ Gagal inisialisasi Supabase: $e');
    }
  }

  static bool get isReady => _isInitialized && SupabaseConfig.isConfigured;

  static SupabaseClient get client {
    if (!isReady) {
      throw StateError(
        'Supabase belum diinisialisasi. Pastikan SupabaseConfig telah diisi.',
      );
    }
    return Supabase.instance.client;
  }

  /// Mengambil daftar gunung dengan pagination (ringan dan cepat)
  static Future<List<Mountain>> getMountains({
    String? province,
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    if (!isReady) {
      throw StateError(
        'Supabase belum diinisialisasi atau belum dikonfigurasi.',
      );
    }

    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      var query = client.from('mountain').select('*');

      if (search != null && search.isNotEmpty) {
        query = query.ilike('name', '%$search%');
      }

      // Filter provinsi langsung di sisi API / Database Supabase
      if (province != null && province.isNotEmpty && province != 'Semua') {
        if (province == 'Luar Jawa') {
          query = query.not(
            'province',
            'ov',
            '{Jawa Tengah,Jawa Barat,Jawa Timur}',
          );
        } else {
          // Kolom province bertipe array TEXT[], gunakan filter contains ('cs')
          query = query.contains('province', [province]);
        }
      }

      final List<dynamic> mountainRows = await query
          .order('elevation', ascending: false)
          .range(from, to);

      return mountainRows
          .map((mData) => _mapJsonToMountain(mData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching mountains from Supabase: $e');
      rethrow;
    }
  }

  /// Mengambil detail gunung beserta rutenya dalam 1x hit query
  static Future<Mountain?> getMountainDetail(String mountainId) async {
    if (!isReady) {
      return await GpxStorageService.getDownloadedMountain(mountainId);
    }

    try {
      final mData = await client
          .from('mountain')
          .select('*, route(*)')
          .eq('id', mountainId)
          .maybeSingle();
      if (mData != null) {
        return _mapJsonToMountain(mData);
      }
    } catch (e) {
      debugPrint('Error fetching mountain detail from Supabase, checking offline cache: $e');
    }

    // Fallback data lokal offline jika sedang tidak ada koneksi
    return await GpxStorageService.getDownloadedMountain(mountainId);
  }

  /// Mapping response JSON dari Supabase (termasuk relasi `route`)
  static Mountain _mapJsonToMountain(Map<String, dynamic> json) {
    final routesJson = (json['route'] as List<dynamic>?) ?? [];
    final List<HikingRoute> routesList = [];
    for (final r in routesJson) {
      final routeMap = r as Map<String, dynamic>;
      final routeName = routeMap['name'] as String? ?? 'Jalur';
      final distanceVal = (routeMap['distance'] as num?)?.toDouble() ?? 0.0;
      final eleGain = (routeMap['elevation'] as num?)?.toInt() ?? 0;
      final hasWater = routeMap['has_water'] as bool? ?? false;
      final cityVal = routeMap['city'] as String?;

      // Estimasi waktu spesifik per rute dari Supabase (dukung estimated_time & estimatedTime)
      String estimatedDuration = '';
      final rawRouteEstimated =
          routeMap['estimated_time'] ?? routeMap['estimatedTime'];
      if (rawRouteEstimated is Map) {
        final eMap = rawRouteEstimated as Map<String, dynamic>;
        final min = eMap['min'];
        final max = eMap['max'];
        if (min != null && max != null) {
          estimatedDuration = '$min - $max Jam';
        }
      } else if (rawRouteEstimated is String) {
        estimatedDuration = rawRouteEstimated.toString();
      }

      routesList.add(
        HikingRoute(
          id: routeMap['id']?.toString() ?? 'route',
          name: routeName,
          basecampName: 'Basecamp $routeName',
          distanceKm: distanceVal,
          estimatedDuration: estimatedDuration,
          elevationGainMeters: eleGain,
          difficulty: eleGain > 1500 ? 'Curam' : 'Sedang',
          hasWater: hasWater,
          city: cityVal,
          waypoints: const [],
        ),
      );
    }

    // Lokasi & Koordinat
    double? latitude;
    double? longitude;
    String locationStr = '';
    if (json['location'] is Map) {
      final loc = json['location'] as Map<String, dynamic>;
      latitude = (loc['latitude'] as num?)?.toDouble();
      longitude = (loc['longitude'] as num?)?.toDouble();
    }

    // Kota / Kabupaten
    final List<String> cities =
        (json['city'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const [];
    if (locationStr.isEmpty && cities.isNotEmpty) {
      locationStr = cities.join(', ');
    }
    if (locationStr.isEmpty) {
      locationStr = 'Indonesia';
    }

    // Provinsi
    String provinceStr = 'Indonesia';
    if (json['province'] is List && (json['province'] as List).isNotEmpty) {
      provinceStr = (json['province'] as List<dynamic>).first.toString();
    }

    // Estimasi Waktu (dukung estimated_time baru dan estimatedTime lama)
    String estimatedTimeStr = '';
    final rawEstimatedTime = json['estimated_time'] ?? json['estimatedTime'];
    if (rawEstimatedTime is Map) {
      final eMap = rawEstimatedTime as Map<String, dynamic>;
      final min = eMap['min'];
      final max = eMap['max'];
      final unit = 'Jam';
      estimatedTimeStr = '$min - $max $unit';
    } else if (rawEstimatedTime is String) {
      estimatedTimeStr = rawEstimatedTime;
    }

    // Tingkat Kesulitan
    final rawDiff = (json['difficulty']?.toString() ?? 'medium').toLowerCase();
    String difficultyStr;
    switch (rawDiff) {
      case 'easy':
        difficultyStr = 'Mudah';
        break;
      case 'hard':
        difficultyStr = 'Sulit';
        break;
      case 'challenging':
        difficultyStr = 'Menantang';
        break;
      case 'medium':
        difficultyStr = 'Sedang';
        break;
      default:
        difficultyStr = json['difficulty']?.toString() ?? 'Sedang';
        break;
    }

    // Status
    final rawStatus = (json['status']?.toString() ?? 'open').toLowerCase();
    String statusStr;
    switch (rawStatus) {
      case 'open':
        statusStr = 'Buka';
        break;
      case 'closed':
        statusStr = 'Tutup';
        break;
      case 'alert':
      case 'warning':
        statusStr = 'Waspada';
        break;
      default:
        statusStr = json['status']?.toString() ?? 'Buka';
        break;
    }

    // Routes apa adanya dari tabel mountain (array text)
    final List<String> rawRoutes =
        (json['routes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const [];

    // Urutkan rute sesuai urutan array routes di tabel mountain (API)
    if (rawRoutes.isNotEmpty) {
      routesList.sort((a, b) {
        int getIndex(HikingRoute route) {
          int idx = rawRoutes.indexOf(route.id);
          if (idx != -1) return idx;

          final cleanName = route.name.trim().toLowerCase();
          idx = rawRoutes.indexWhere((o) {
            final cleanO = o.trim().toLowerCase();
            return cleanO == cleanName ||
                cleanO.endsWith('-$cleanName') ||
                cleanO.endsWith('.$cleanName') ||
                cleanO.contains(cleanName);
          });
          return idx != -1 ? idx : 999999;
        }

        return getIndex(a).compareTo(getIndex(b));
      });
    }

    // URL Foto / Banner Gunung
    final String? imageUrl = json['image_url'] as String?;

    return Mountain(
      id: json['id']?.toString() ?? 'unknown',
      name: json['name'] ?? 'Gunung',
      elevation: (json['elevation'] as num?)?.toInt() ?? 0,
      location: locationStr,
      province: provinceStr,
      difficulty: difficultyStr,
      estimatedTime: estimatedTimeStr,
      routes: routesList,
      rawRoutes: rawRoutes,
      imageUrl: imageUrl,
      status: statusStr,
      latitude: latitude,
      longitude: longitude,
      cities: cities,
      isGpxReady: false,
      isMapReady: false,
      assetUrl: json['asset_url'],
      allWaypoints: const [],
    );
  }
}
