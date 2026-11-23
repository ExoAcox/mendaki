import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mendaki/core/services/download_service.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/image_cache_manager.dart';
import 'package:mendaki/core/services/offline_map_service.dart';
import 'package:mendaki/core/services/supabase_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/widgets/home/telemetry_item.dart';

class MountainCard extends StatefulWidget {
  final Mountain mountain;
  final FutureOr<void> Function() onDetailTap;
  final VoidCallback? onDownloaded;
  final VoidCallback? onDeleteTap;

  const MountainCard({
    super.key,
    required this.mountain,
    required this.onDetailTap,
    this.onDownloaded,
    this.onDeleteTap,
  });

  @override
  State<MountainCard> createState() => _MountainCardState();
}

class _MountainCardState extends State<MountainCard> {
  bool _isGpxDownloaded = false;
  bool _isMapDownloaded = false;

  bool get _isDownloading =>
      DownloadService.instance.isDownloadingGpx(widget.mountain.id);
  double get _downloadProgress =>
      DownloadService.instance.getGpxProgress(widget.mountain.id);

  @override
  void initState() {
    super.initState();
    _isGpxDownloaded =
        GpxStorageService.isGpxDownloadedCached(widget.mountain.id) ??
        widget.mountain.isGpxReady;
    _isMapDownloaded =
        OfflineMapService.isOfflineMapDownloadedCached(widget.mountain.id) ??
        widget.mountain.isMapReady;
    DownloadService.instance.addListener(_onDownloadServiceUpdate);
    _checkDownloadStatus();
  }

  @override
  void dispose() {
    DownloadService.instance.removeListener(_onDownloadServiceUpdate);
    super.dispose();
  }

  void _onDownloadServiceUpdate() {
    if (mounted) {
      _checkDownloadStatus();
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant MountainCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    final gpxDownloaded = await GpxStorageService.isGpxDownloaded(
      widget.mountain.id,
    );
    final mapDownloaded = await OfflineMapService.isOfflineMapDownloaded(
      widget.mountain.id,
    );

    if (mounted) {
      setState(() {
        _isGpxDownloaded = gpxDownloaded || widget.mountain.isGpxReady;
        _isMapDownloaded = mapDownloaded || widget.mountain.isMapReady;
      });
    }
  }

  Future<void> _handleOpenDetail() async {
    final result = widget.onDetailTap();
    if (result is Future) {
      await result;
    }
    if (mounted) {
      await _checkDownloadStatus();
    }
  }

  Future<void> _downloadGpxAndOpen() async {
    if (_isDownloading) return;

    try {
      // 1. Ambil data detail lengkap gunung & rutenya dari Supabase / cache jika belum ada
      Mountain fullMountain = widget.mountain;
      if (fullMountain.routes.isEmpty) {
        try {
          final detail = await SupabaseService.getMountainDetail(
            widget.mountain.id,
          );
          if (detail != null) {
            fullMountain = detail;
          }
        } catch (e) {
          debugPrint('Error fetching mountain detail before download: $e');
        }
      }

      final success = await DownloadService.instance.startGpxDownload(
        fullMountain,
      );
      if (success && mounted) {
        await _checkDownloadStatus();
        widget.onDownloaded?.call();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF89EDBA),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GPX ${widget.mountain.name} berhasil disimpan!',
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
        final isMissingPlugin = e.toString().contains('MissingPluginException');
        final message = isMissingPlugin
            ? 'Plugin baru terpasang. Silakan Stop & Run ulang aplikasi.'
            : 'Gagal mengunduh data offline: $e';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
            content: Text(message),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mountain = widget.mountain;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _isGpxDownloaded ? _handleOpenDetail : null,
            child: Container(
              height: 190,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0F3A2B),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F3A2B),
                    Color(0xFF1E5B44),
                    Color(0xFF11291F),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Gambar Gunung: prioritaskan file offline lokal jika ada, lalu fallback ke network
                  if (mountain.localImagePath != null &&
                      File(mountain.localImagePath!).existsSync())
                    Positioned.fill(
                      child: Image.file(
                        File(mountain.localImagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (mountain.imageUrl != null &&
                      mountain.imageUrl!.isNotEmpty)
                    Positioned.fill(
                      child: CachedNetworkImage(
                        cacheManager: MountainImageCacheManager.instance,
                        imageUrl: mountain.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                      ),
                    ),

                  // Gradient Overlay di bagian bawah untuk keterbacaan teks
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(
                              alpha: mountain.imageUrl != null ? 0.8 : 0.45,
                            ),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Fallback ikon gunung jika tidak ada foto
                  if (mountain.imageUrl == null || mountain.imageUrl!.isEmpty)
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.terrain_rounded,
                        size: 200,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  // Badges (GPX & Peta Tersimpan)
                  Positioned(
                    left: 16,
                    top: 14,
                    right: widget.onDeleteTap != null ? 58 : 16,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (_isGpxDownloaded)
                          _buildBadge(
                            icon: Icons.offline_pin_rounded,
                            label: 'GPX',
                          ),
                        if (_isMapDownloaded)
                          _buildBadge(
                            icon: Icons.offline_pin_rounded,
                            label: 'Map',
                          ),
                      ],
                    ),
                  ),

                  // Floating Delete Button (Hanya muncul jika onDeleteTap diberikan / di Library)
                  if (widget.onDeleteTap != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.onDeleteTap,
                                borderRadius: BorderRadius.circular(20),
                                splashColor: const Color(
                                  0xFFBA1A1A,
                                ).withValues(alpha: 0.15),
                                highlightColor: Colors.transparent,
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.88),
                                        Colors.white.withValues(alpha: 0.62),
                                        Colors.white.withValues(alpha: 0.75),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFBA1A1A),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    bottom: 12,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mountain.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF89EDBA),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                mountain.location.isNotEmpty
                                    ? mountain.location
                                    : mountain.province,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Metadata Telemetry
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TelemetryItem(
                      label: 'ELEVASI',
                      value: '${mountain.elevation} mdpl',
                    ),
                    TelemetryItem(
                      label: 'TINGKAT KESULITAN',
                      value: mountain.difficulty.toUpperCase(),
                    ),
                    TelemetryItem(
                      label: 'ESTIMASI',
                      value: mountain.estimatedTime,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.outlineVariant),
                const SizedBox(height: 14),

                // Jalur Pendakian (Data routes apa adanya dari API)
                if (mountain.displayRoutes.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.alt_route_rounded,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${mountain.displayRoutes.length} Jalur Pendakian :',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: mountain.displayRoutes.map((routeStr) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.outlineVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        child: Text(
                          routeStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Action CTA Button dengan Progress Download
                _buildActionButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (_isDownloading) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.85),
                    Colors.white.withValues(alpha: 0.58),
                    Colors.white.withValues(alpha: 0.72),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(18),
                // border: Border.all(
                //   color: Colors.white.withValues(alpha: 0.5),
                //   width: 1.2,
                // ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: _downloadProgress.clamp(0.06, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Mengunduh GPX... ${(_downloadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isGpxDownloaded) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleOpenDetail,
                splashColor: Colors.white.withValues(alpha: 0.15),
                highlightColor: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.92),
                        const Color(0xFF1E523C).withValues(alpha: 0.78),
                        AppTheme.primary.withValues(alpha: 0.88),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lihat Jalur Pendakian',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Kondisi belum terunduh (Mewajibkan unduh sebelum masuk detail) -> Liquid Glass Download Button
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _downloadGpxAndOpen,
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.92),
                      const Color(0xFF1E523C).withValues(alpha: 0.78),
                      AppTheme.primary.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_download_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Download Data GPX',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({required IconData icon, required String label}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.88),
                  Colors.white.withValues(alpha: 0.62),
                  Colors.white.withValues(alpha: 0.75),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppTheme.primary, size: 13),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
