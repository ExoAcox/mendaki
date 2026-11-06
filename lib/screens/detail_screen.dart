import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mendaki/core/services/gpx_parser_service.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/offline_map_service.dart';
import 'package:mendaki/core/services/supabase_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/screens/navigation_screen.dart';
import 'package:mendaki/widgets/detail/detail_bottom_bar.dart';
import 'package:mendaki/widgets/detail/detail_map_header.dart';
import 'package:mendaki/widgets/detail/detail_quick_stats.dart';
import 'package:mendaki/widgets/detail/detail_route_item.dart';

class DetailScreen extends StatefulWidget {
  final Mountain mountain;

  const DetailScreen({super.key, required this.mountain});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Mountain _mountain;
  bool _isLoadingDetail = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isOfflineReady = false;

  @override
  void initState() {
    super.initState();
    _mountain = widget.mountain;
    _checkOfflineStatus();
    _loadMountainDetail();
  }

  Future<void> _loadMountainDetail() async {
    // Jika rute belum terisi, fetch data lengkap dari Supabase
    if (_mountain.routes.isNotEmpty) return;

    setState(() {
      _isLoadingDetail = true;
    });

    try {
      final detail = await SupabaseService.getMountainDetail(_mountain.id);
      if (mounted && detail != null) {
        setState(() {
          _mountain = detail;
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading mountain detail: $e');
    } finally {
      if (mounted && _isLoadingDetail) {
        setState(() {
          _isLoadingDetail = false;
        });
      }
    }
  }

  Future<void> _checkOfflineStatus() async {
    final isReady = await OfflineMapService.isOfflineMapDownloaded(
      _mountain.id,
    );
    if (mounted) {
      setState(() {
        _isOfflineReady = isReady;
      });
    }
  }

  Future<void> _downloadOfflinePackage() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // 1. Unduh atau pastikan berkas GPX tersimpan di lokal
      await GpxStorageService.downloadAndSaveGpx(mountainId: _mountain.id);

      // 2. Simpan data Mountain & Routes lengkap ke penyimpanan lokal offline
      await GpxStorageService.saveDownloadedMountain(_mountain);

      // 3. Ambil titik track untuk bounding box akurat
      final gpxFile = await GpxStorageService.getLocalGpxFile(_mountain.id);
      List<LatLng>? trackPoints;
      if (gpxFile != null && await gpxFile.exists()) {
        final gpxData = await GpxParserService.parseFile(gpxFile);
        trackPoints = gpxData.tracks
            .expand((t) => t.trackPoints)
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
      }

      // 4. Unduh seluruh ubin peta (tiles) area gunung zoom 11 sampai 15
      await OfflineMapService.downloadOfflineMap(
        mountainId: _mountain.id,
        centerLat: _mountain.latitude ?? -7.455,
        centerLng: _mountain.longitude ?? 110.435,
        trackPoints: trackPoints,
        minZoom: 11,
        maxZoom: 15,
        onProgress: (downloaded, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = total > 0 ? downloaded / total : 0.0;
            });
          }
        },
      );

      final sizeMb = await OfflineMapService.getOfflineMapSizeMb(_mountain.id);

      if (mounted) {
        setState(() {
          _isOfflineReady = true;
          _mountain = _mountain.copyWith(
            isGpxReady: true,
            isMapReady: true,
          );
        });
        await GpxStorageService.saveDownloadedMountain(_mountain);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F5238),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.offline_pin_rounded,
                  color: Color(0xFF89EDBA),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Paket peta offline ${_mountain.name} (${sizeMb.toStringAsFixed(1)} MB) berhasil diunduh! Siap dibuka tanpa sinyal.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
            content: Text('Gagal mengunduh paket offline: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _startNavigation() {
    final activeRoute =
        _mountain.routes.isNotEmpty ? _mountain.routes.first : null;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          mountain: _mountain,
          selectedRoute: activeRoute,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routes = _mountain.routes;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Map Header (Immersive fullscreen top)
            DetailMapHeader(
              mountain: _mountain,
              onDownloadTap: _downloadOfflinePackage,
              isOfflineReady: _isOfflineReady,
              isDownloading: _isDownloading,
              downloadProgress: _downloadProgress,
            ),

            // Quick Stats Floating Strip (overlapping hero with negative transform)
            Transform.translate(
              offset: const Offset(0, -18),
              child: DetailQuickStats(mountain: _mountain),
            ),

            // Daftar Jalur Pendakian
            if (_isLoadingDetail)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.primary,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Memuat detail jalur pendakian...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else if (routes.isNotEmpty) ...[
              DetailRouteItem(
                routes: routes,
                peakElevation: _mountain.elevation,
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: DetailBottomBar(
        onStartNavigation: _startNavigation,
        onDownloadGpx: _downloadOfflinePackage,
        isDownloading: _isDownloading,
        isOfflineReady: _isOfflineReady,
        downloadProgress: _downloadProgress,
      ),
    );
  }
}
