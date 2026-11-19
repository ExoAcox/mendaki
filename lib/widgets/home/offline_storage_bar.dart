import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';

/// Container utama untuk menampilkan ringkasan penyimpanan offline (GPX & Peta)
class OfflineStorageBar extends StatelessWidget {
  final int gpxBytes;
  final int mapBytes;
  final Color gpxColor;
  final Color mapColor;

  const OfflineStorageBar({
    super.key,
    required this.gpxBytes,
    required this.mapBytes,
    this.gpxColor = const Color(0xFF2D6A4F),
    this.mapColor = const Color(0xFF1E88E5),
  });

  int get totalBytes => gpxBytes + mapBytes;

  double get gpxPercentage =>
      totalBytes > 0 ? (gpxBytes / totalBytes) * 100 : 0.0;

  double get mapPercentage =>
      totalBytes > 0 ? (mapBytes / totalBytes) * 100 : 0.0;

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
          OfflineStorageHeader(totalFormatted: formatBytes(totalBytes)),
          const SizedBox(height: 10),
          OfflineStorageProgressBar(
            gpxBytes: gpxBytes,
            mapBytes: mapBytes,
            gpxPercentage: gpxPercentage,
            mapPercentage: mapPercentage,
            gpxColor: gpxColor,
            mapColor: mapColor,
          ),
          const SizedBox(height: 10),
          OfflineStorageLegend(
            gpxBytes: gpxBytes,
            mapBytes: mapBytes,
            gpxPercentage: gpxPercentage,
            mapPercentage: mapPercentage,
            gpxColor: gpxColor,
            mapColor: mapColor,
          ),
        ],
      ),
    );
  }
}

/// Header baris judul dan ukuran total penyimpanan offline
class OfflineStorageHeader extends StatelessWidget {
  final String totalFormatted;

  const OfflineStorageHeader({super.key, required this.totalFormatted});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    );
  }
}

/// Horizontal progress bar bersegmen proporsional untuk GPX dan Peta
class OfflineStorageProgressBar extends StatelessWidget {
  final int gpxBytes;
  final int mapBytes;
  final double gpxPercentage;
  final double mapPercentage;
  final Color gpxColor;
  final Color mapColor;

  const OfflineStorageProgressBar({
    super.key,
    required this.gpxBytes,
    required this.mapBytes,
    required this.gpxPercentage,
    required this.mapPercentage,
    this.gpxColor = const Color(0xFF2D6A4F),
    this.mapColor = const Color(0xFF1E88E5),
  });

  int get totalBytes => gpxBytes + mapBytes;

  @override
  Widget build(BuildContext context) {
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
                  if (gpxBytes > 0 && mapBytes > 0) const SizedBox(width: 2),
                  if (mapBytes > 0)
                    Expanded(
                      flex: (mapPercentage * 10).round().clamp(1, 1000),
                      child: Container(color: mapColor),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Bagian keterangan legenda (persentase & ukuran) untuk GPX dan Peta
class OfflineStorageLegend extends StatelessWidget {
  final int gpxBytes;
  final int mapBytes;
  final double gpxPercentage;
  final double mapPercentage;
  final Color gpxColor;
  final Color mapColor;

  const OfflineStorageLegend({
    super.key,
    required this.gpxBytes,
    required this.mapBytes,
    required this.gpxPercentage,
    required this.mapPercentage,
    this.gpxColor = const Color(0xFF2D6A4F),
    this.mapColor = const Color(0xFF1E88E5),
  });

  int get totalBytes => gpxBytes + mapBytes;

  @override
  Widget build(BuildContext context) {
    if (totalBytes == 0) {
      return const Text(
        'Belum ada data yang tersimpan secara offline.',
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.outline,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OfflineStorageLegendItem(
          color: gpxColor,
          label: 'GPX',
          bytes: gpxBytes,
          percentage: gpxPercentage,
        ),
        OfflineStorageLegendItem(
          color: mapColor,
          label: 'Peta',
          bytes: mapBytes,
          percentage: mapPercentage,
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
  final double percentage;

  const OfflineStorageLegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.bytes,
    required this.percentage,
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
          '$label: ${OfflineStorageBar.formatBytes(bytes)} (${percentage.toStringAsFixed(percentage > 0 && percentage < 1 ? 1 : 0)}%)',
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
