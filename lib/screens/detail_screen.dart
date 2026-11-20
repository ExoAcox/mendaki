import 'package:flutter/material.dart';
import 'package:mendaki/core/services/download_service.dart';
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
  bool _isOfflineReady = false;

  bool get _isDownloading =>
      DownloadService.instance.isDownloadingMap(_mountain.id);
  double get _downloadProgress =>
      DownloadService.instance.getMapProgress(_mountain.id);

  @override
  void initState() {
    super.initState();
    _mountain = widget.mountain;
    DownloadService.instance.addListener(_onDownloadServiceUpdate);
    _checkOfflineStatus();
    _loadMountainDetail();
  }

  @override
  void dispose() {
    DownloadService.instance.removeListener(_onDownloadServiceUpdate);
    super.dispose();
  }

  void _onDownloadServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
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

    try {
      final success = await DownloadService.instance.startMapDownload(_mountain);
      if (!mounted) return;

      if (success) {
        setState(() {
          _isOfflineReady = true;
          _mountain = _mountain.copyWith(isMapReady: true);
        });

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
                    'Map offline ${_mountain.name} berhasil disimpan!',
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
            content: Text('Gagal mengunduh map offline: $e'),
          ),
        );
      }
    }
  }

  void _startNavigation() {
    final activeRoute = _mountain.routes.isNotEmpty
        ? _mountain.routes.first
        : null;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NavigationScreen(mountain: _mountain, selectedRoute: activeRoute),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routes = _mountain.routes;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBody: true,
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
            const SizedBox(height: 96),
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
