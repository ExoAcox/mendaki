import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';

/// Container utama untuk menampilkan ringkasan penyimpanan offline (GPX, Peta & Gambar)
class OfflineStorageBar extends StatelessWidget {
  final int gpxBytes;
  final int mapBytes;
  final int imageBytes;
  final int? availableBytes;
  final Color gpxColor;
  final Color mapColor;
  final Color imageColor;
  final Color availableColor;

  const OfflineStorageBar({
    super.key,
    required this.gpxBytes,
    required this.mapBytes,
    this.imageBytes = 0,
    this.availableBytes,
    this.gpxColor = const Color(0xFF2D6A4F),
    this.mapColor = const Color(0xFF1E88E5),
    this.imageColor = const Color(0xFFD97706),
    this.availableColor = const Color(0xFFCBD5E1),
  });

  int get totalBytes => gpxBytes + mapBytes + imageBytes;

  double get gpxPercentage =>
      totalBytes > 0 ? (gpxBytes / totalBytes) * 100 : 0.0;

  double get mapPercentage =>
      totalBytes > 0 ? (mapBytes / totalBytes) * 100 : 0.0;

  double get imagePercentage =>
      totalBytes > 0 ? (imageBytes / totalBytes) * 100 : 0.0;

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OfflineStorageHeader(
            totalFormatted: formatBytes(totalBytes),
            availableFormatted: availableBytes != null
                ? formatBytes(availableBytes!)
                : null,
          ),
          const SizedBox(height: 10),
          OfflineStorageProgressBar(
            gpxBytes: gpxBytes,
            mapBytes: mapBytes,
            imageBytes: imageBytes,
            availableBytes: availableBytes,
            gpxPercentage: gpxPercentage,
            mapPercentage: mapPercentage,
            imagePercentage: imagePercentage,
            gpxColor: gpxColor,
            mapColor: mapColor,
            imageColor: imageColor,
            availableColor: availableColor,
          ),
          const SizedBox(height: 10),
          OfflineStorageLegend(
            gpxBytes: gpxBytes,
            mapBytes: mapBytes,
            imageBytes: imageBytes,
            availableBytes: availableBytes,
            gpxPercentage: gpxPercentage,
            mapPercentage: mapPercentage,
            imagePercentage: imagePercentage,
            gpxColor: gpxColor,
            mapColor: mapColor,
            imageColor: imageColor,
            availableColor: availableColor,
          ),
        ],
      ),
    );
  }
}

/// Header baris judul dan ukuran total penyimpanan offline
class OfflineStorageHeader extends StatelessWidget {
  final String totalFormatted;
  final String? availableFormatted;

  const OfflineStorageHeader({
    super.key,
    required this.totalFormatted,
    this.availableFormatted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Row(
          children: [
            Icon(Icons.storage_rounded, size: 16, color: AppTheme.primary),
            SizedBox(width: 6),
            Text(
              'Penyimpanan Offline',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              totalFormatted,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Horizontal progress bar bersegmen proporsional untuk GPX, Peta, Gambar, dan Ruang Available
class OfflineStorageProgressBar extends StatelessWidget {
  final int gpxBytes;
  final int mapBytes;
  final int imageBytes;
  final int? availableBytes;
  final double gpxPercentage;
  final double mapPercentage;
  final double imagePercentage;
  final Color gpxColor;
  final Color mapColor;
  final Color imageColor;
  final Color availableColor;

  const OfflineStorageProgressBar({
    super.key,
    required this.gpxBytes,
    required this.mapBytes,
    this.imageBytes = 0,
    required this.gpxPercentage,
    required this.mapPercentage,
    this.imagePercentage = 0.0,
    this.availableBytes,
    this.gpxColor = const Color(0xFF2D6A4F),
    this.mapColor = const Color(0xFF1E88E5),
    this.imageColor = const Color(0xFFD97706),
    this.availableColor = const Color(0xFFCBD5E1),
  });

  int get totalBytes => gpxBytes + mapBytes + imageBytes;

  @override
  Widget build(BuildContext context) {
    final hasOffline = totalBytes > 0;
    final hasAvailable = availableBytes != null && availableBytes! > 0;

    if (!hasOffline && !hasAvailable) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 8,
          width: double.infinity,
          color: AppTheme.surfaceContainer,
        ),
      );
    }

    if (hasAvailable) {
      final totalAll = gpxBytes + mapBytes + imageBytes + availableBytes!;
      final int gpxFlex = gpxBytes > 0
          ? math.max(10, ((gpxBytes / totalAll) * 1000).round())
          : 0;
      final int mapFlex = mapBytes > 0
          ? math.max(20, ((mapBytes / totalAll) * 1000).round())
          : 0;
      final int imageFlex = imageBytes > 0
          ? math.max(10, ((imageBytes / totalAll) * 1000).round())
          : 0;
      final int availableFlex = 1000 - gpxFlex - mapFlex - imageFlex;

      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 8,
          width: double.infinity,
          color: AppTheme.surfaceContainer,
          child: Row(
            children: [
              if (gpxBytes > 0)
                Expanded(
                  flex: gpxFlex,
                  child: Container(color: gpxColor),
                ),
              if (gpxBytes > 0 &&
                  (mapBytes > 0 || imageBytes > 0 || hasAvailable))
                const SizedBox(width: 2),
              if (mapBytes > 0)
                Expanded(
                  flex: mapFlex,
                  child: Container(color: mapColor),
                ),
              if (mapBytes > 0 && (imageBytes > 0 || hasAvailable))
                const SizedBox(width: 2),
              if (imageBytes > 0)
                Expanded(
                  flex: imageFlex,
                  child: Container(color: imageColor),
                ),
              if (imageBytes > 0 && hasAvailable) const SizedBox(width: 2),
              if (hasAvailable)
                Expanded(
                  flex: availableFlex,
                  child: Container(color: availableColor),
                ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 8,
        width: double.infinity,
        color: AppTheme.surfaceContainer,
        child: totalBytes == 0
            ? const SizedBox.shrink()
            : Row(
                children: [
                  if (gpxBytes > 0)
                    Expanded(
                      flex: (gpxPercentage * 10).round().clamp(1, 1000),
                      child: Container(color: gpxColor),
                    ),
                  if (gpxBytes > 0 && (mapBytes > 0 || imageBytes > 0))
                    const SizedBox(width: 2),
                  if (mapBytes > 0)
                    Expanded(
                      flex: (mapPercentage * 10).round().clamp(1, 1000),
                      child: Container(color: mapColor),
                    ),
                  if (mapBytes > 0 && imageBytes > 0) const SizedBox(width: 2),
                  if (imageBytes > 0)
                    Expanded(
                      flex: (imagePercentage * 10).round().clamp(1, 1000),
                      child: Container(color: imageColor),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Bagian keterangan legenda (persentase & ukuran) untuk GPX, Peta, dan Gambar
class OfflineStorageLegend extends StatelessWidget {
  final int gpxBytes;
  final int mapBytes;
  final int imageBytes;
  final int? availableBytes;
  final double gpxPercentage;
  final double mapPercentage;
  final double imagePercentage;
  final Color gpxColor;
  final Color mapColor;
  final Color imageColor;
  final Color availableColor;

  const OfflineStorageLegend({
    super.key,
    required this.gpxBytes,
    required this.mapBytes,
    this.imageBytes = 0,
    required this.gpxPercentage,
    required this.mapPercentage,
    this.imagePercentage = 0.0,
    this.availableBytes,
    this.gpxColor = const Color(0xFF2D6A4F),
    this.mapColor = const Color(0xFF1E88E5),
    this.imageColor = const Color(0xFFD97706),
    this.availableColor = const Color(0xFFCBD5E1),
  });

  int get totalBytes => gpxBytes + mapBytes + imageBytes;

  @override
  Widget build(BuildContext context) {
    if (totalBytes == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Belum ada data yang tersimpan secara offline.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (availableBytes != null)
            OfflineStorageLegendItem(
              color: availableColor,
              label: 'Available',
              bytes: availableBytes!,
            ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        OfflineStorageLegendItem(
          color: gpxColor,
          label: 'GPX',
          bytes: gpxBytes,
          percentage: gpxPercentage,
        ),
        OfflineStorageLegendItem(
          color: mapColor,
          label: 'Maps',
          bytes: mapBytes,
          percentage: mapPercentage,
        ),
        OfflineStorageLegendItem(
          color: imageColor,
          label: 'Images',
          bytes: imageBytes,
          percentage: imagePercentage,
        ),

        if (availableBytes != null)
          OfflineStorageLegendItem(
            color: availableColor,
            label: 'Available',
            bytes: availableBytes!,
            percentage: 0,
          ),
      ],
    );
  }
}

/// Komponen item legenda individu dengan dot warna, label, ukuran, dan persentase
class OfflineStorageLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int bytes;
  final double? percentage;

  const OfflineStorageLegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.bytes,
    this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${OfflineStorageBar.formatBytes(bytes)}',
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Widget teks keterangan status offline pada halaman Library
class OfflineStorageNotice extends StatelessWidget {
  const OfflineStorageNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.offline_pin_rounded,
          color: AppTheme.primary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Data dan peta gunung di halaman ini tersimpan offline di perangkat Anda.',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
