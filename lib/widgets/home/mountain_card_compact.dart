import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mendaki/core/services/download_service.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/image_cache_manager.dart';
import 'package:mendaki/core/services/offline_map_service.dart';
import 'package:mendaki/core/services/supabase_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';

class MountainCardCompact extends StatefulWidget {
  final Mountain mountain;
  final FutureOr<void> Function() onDetailTap;
  final VoidCallback? onDownloaded;
  final VoidCallback? onDeleteTap;

  const MountainCardCompact({
    super.key,
    required this.mountain,
    required this.onDetailTap,
    this.onDownloaded,
    this.onDeleteTap,
  });

  @override
  State<MountainCardCompact> createState() => _MountainCardCompactState();
}

class _MountainCardCompactState extends State<MountainCardCompact> {
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
  void didUpdateWidget(covariant MountainCardCompact oldWidget) {
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
            content: Text('Gagal mengunduh: $e'),
          ),
        );
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF0F3A2B),
      child: Center(
        child: Icon(
          Icons.terrain_rounded,
          size: 30,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mountain = widget.mountain;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isDownloading
              ? null
              : (_isGpxDownloaded || widget.onDeleteTap != null
                    ? _handleOpenDetail
                    : _downloadGpxAndOpen),
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    // Thumbnail Gambar Gunung (74x74)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 74,
                        height: 74,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (mountain.localImagePath != null &&
                                File(mountain.localImagePath!).existsSync())
                              Image.file(
                                File(mountain.localImagePath!),
                                fit: BoxFit.cover,
                              )
                            else if (mountain.imageUrl != null &&
                                mountain.imageUrl!.isNotEmpty)
                              CachedNetworkImage(
                                cacheManager:
                                    MountainImageCacheManager.instance,
                                imageUrl: mountain.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    _buildPlaceholder(),
                                errorWidget: (context, url, error) =>
                                    _buildPlaceholder(),
                              )
                            else
                              _buildPlaceholder(),

                            // Gradient pelindung
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.35),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),

                            // Badge di pojok thumbnail
                            if (!_isDownloading &&
                                (_isGpxDownloaded && _isMapDownloaded))
                              Positioned(
                                top: 5,
                                left: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.8,
                                    ),
                                    borderRadius: BorderRadius.circular(999999),
                                  ),
                                  child: const Icon(
                                    Icons.offline_pin_rounded,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info Utama (Nama, Lokasi, Metadata)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mountain.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppTheme.primary,
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  mountain.location.isNotEmpty
                                      ? mountain.location
                                      : mountain.province,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${mountain.elevation} mdpl',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 0.7,
                                  ),
                                ),
                                child: Text(
                                  '${mountain.displayRoutes.length} rute',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Action di sebelah kanan: HANYA ICON
                    if (widget.onDeleteTap != null)
                      InkWell(
                        onTap: widget.onDeleteTap,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.error,
                            size: 18,
                          ),
                        ),
                      )
                    else if (_isDownloading)
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      )
                    else if (!_isGpxDownloaded)
                      InkWell(
                        onTap: _downloadGpxAndOpen,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.download_rounded,
                            color: AppTheme.primary.withValues(alpha: 0.8),
                            size: 16,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
              if (_isDownloading)
                LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  color: AppTheme.primary,
                  minHeight: 3,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
