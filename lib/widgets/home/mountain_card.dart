import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
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
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _isGpxDownloaded = widget.mountain.isGpxReady;
    _isMapDownloaded = widget.mountain.isMapReady;
    _checkDownloadStatus();
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
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

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

      // 2. Unduh berkas GPX
      await GpxStorageService.downloadAndSaveGpx(
        mountainId: widget.mountain.id,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      // 3. Simpan data mountain & routes secara offline
      await GpxStorageService.saveDownloadedMountain(fullMountain);

      if (mounted) {
        setState(() {
          _isGpxDownloaded = true;
          _isDownloading = false;
        });

        widget.onDownloaded?.call();

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
        setState(() {
          _isDownloading = false;
        });

        final isMissingPlugin = e.toString().contains('MissingPluginException');
        final message = isMissingPlugin
            ? 'Plugin baru terpasang. Silakan Stop & Run ulang aplikasi.'
            : 'Gagal mengunduh data GPX: $e';

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
        borderRadius: BorderRadius.circular(18),
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
                      child: Image.network(
                        mountain.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),

                  // Gradient Overlay untuk keterbacaan teks
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0),
                            Colors.black.withValues(
                              alpha: mountain.imageUrl != null ? 0.75 : 0.45,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF006D48,
                              ).withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                  0xFF89EDBA,
                                ).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.offline_pin_rounded,
                                  color: Color(0xFF89EDBA),
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'GPX',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_isMapDownloaded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF006D48,
                              ).withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                  0xFF89EDBA,
                                ).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.offline_pin_rounded,
                                  color: Color(0xFF89EDBA),
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Map',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Floating Delete Button (Hanya muncul jika onDeleteTap diberikan / di Library)
                  if (widget.onDeleteTap != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onDeleteTap,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    bottom: 16,
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
                        const SizedBox(height: 3),
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
                      value: mountain.estimatedTime.isNotEmpty
                          ? mountain.estimatedTime
                          : '6-8 Jam',
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
                  const SizedBox(height: 8),
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
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.outlineVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        child: Text(
                          routeStr,
                          style: const TextStyle(
                            fontSize: 12,
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
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Linear Progress Fill Animation
            FractionallySizedBox(
              widthFactor: _downloadProgress.clamp(0.06, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(color: AppTheme.primary.withValues(alpha: 0.25)),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
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
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_isGpxDownloaded) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _handleOpenDetail,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon(
              //   Icons.check_circle_rounded,
              //   size: 18,
              //   color: Color(0xFF89EDBA),
              // ),
              // SizedBox(width: 8),
              Text(
                'Lihat Jalur Pendakian',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      );
    }

    // Kondisi belum terunduh (Mewajibkan unduh sebelum masuk detail)
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _downloadGpxAndOpen,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_download_outlined, size: 20),
            SizedBox(width: 8),
            Text(
              'Download Data GPX',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
