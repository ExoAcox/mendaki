import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';

class DetailBottomBar extends StatelessWidget {
  final VoidCallback onStartNavigation;
  final VoidCallback onDownloadGpx;
  final bool isDownloading;
  final bool isOfflineReady;
  final double? downloadProgress;

  const DetailBottomBar({
    super.key,
    required this.onStartNavigation,
    required this.onDownloadGpx,
    this.isDownloading = false,
    this.isOfflineReady = false,
    this.downloadProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _buildActionButton(context),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final progress = downloadProgress ?? 0.0;

    // 1. Sedang Mengunduh -> Bar progress animasi seperti di Home
    if (isDownloading) {
      return Container(
        width: double.infinity,
        height: 52,
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
              widthFactor: progress.clamp(0.06, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(color: AppTheme.primary.withValues(alpha: 0.25)),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Mengunduh Peta Offline... ${(progress * 100).toInt()}%',
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

    // 2. Sudah Terunduh -> Tombol Mulai Navigasi (Lanjut ke next page)
    if (isOfflineReady) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onStartNavigation,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.onPrimary,
            elevation: 2,
            shadowColor: AppTheme.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Row(
            children: [
              const Icon(Icons.hiking_rounded, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mulai Mendaki',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      );
    }

    // 3. Belum Terunduh -> Wajib download maps offline dulu baru bisa lanjut
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onDownloadGpx,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.onPrimary,
          elevation: 2,
          shadowColor: AppTheme.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.file_download_outlined, size: 22),
            SizedBox(width: 10),
            Text(
              'Download Map Offline',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
