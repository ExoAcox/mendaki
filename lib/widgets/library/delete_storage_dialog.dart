import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/widgets/library/offline_storage_bar.dart';

/// Hasil seleksi kategori penyimpanan yang akan dihapus
class DeleteStorageResult {
  final bool gpx;
  final bool maps;
  final bool images;

  const DeleteStorageResult({
    required this.gpx,
    required this.maps,
    required this.images,
  });

  bool get hasAny => gpx || maps || images;
}

/// Alur lengkap dialog hapus penyimpanan: modal seleksi checkbox -> modal konfirmasi
class DeleteStorageFlow {
  /// Menjalankan alur penghapusan storage:
  /// 1. Buka dialog pilihan checkbox (GPX, Maps, Images)
  /// 2. Jika user klik Hapus, buka dialog konfirmasi rincian kategori
  /// 3. Jika user konfirmasi "Ya, Hapus", kembalikan [DeleteStorageResult]
  /// 4. Jika dibatalkan di tahap manapun, kembalikan null
  static Future<DeleteStorageResult?> show(
    BuildContext context, {
    required int gpxBytes,
    required int mapBytes,
    required int imageBytes,
  }) async {
    final selection = await showDialog<DeleteStorageResult>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => DeleteStorageDialog(
        gpxBytes: gpxBytes,
        mapBytes: mapBytes,
        imageBytes: imageBytes,
      ),
    );

    if (selection == null || !selection.hasAny) return null;

    int totalBytes = 0;
    if (selection.gpx) totalBytes += gpxBytes;
    if (selection.maps) totalBytes += mapBytes;
    if (selection.images) totalBytes += imageBytes;

    if (!context.mounted) return null;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => ConfirmDeleteStorageDialog(
        totalSizeFormatted: OfflineStorageBar.formatBytes(totalBytes),
      ),
    );

    if (confirmed == true) {
      return selection;
    }
    return null;
  }
}

/// Modal dialog pemilihan checklist kategori data offline yang ingin dihapus
class DeleteStorageDialog extends StatefulWidget {
  final int gpxBytes;
  final int mapBytes;
  final int imageBytes;

  const DeleteStorageDialog({
    super.key,
    required this.gpxBytes,
    required this.mapBytes,
    required this.imageBytes,
  });

  @override
  State<DeleteStorageDialog> createState() => _DeleteStorageDialogState();
}

class _DeleteStorageDialogState extends State<DeleteStorageDialog> {
  bool _deleteGpx = true;
  bool _deleteMaps = true;
  bool _deleteImages = true;

  @override
  Widget build(BuildContext context) {
    final hasSelection = _deleteGpx || _deleteMaps || _deleteImages;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.60),
                    Colors.white.withValues(alpha: 0.78),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFDC2626,
                          ).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFDC2626,
                            ).withValues(alpha: 0.20),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Hapus Penyimpanan',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pilih data offline yang ingin dihapus dari memori perangkat:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Checkbox GPX
                  StorageCheckboxItem(
                    title: 'GPX',
                    sizeFormatted: OfflineStorageBar.formatBytes(
                      widget.gpxBytes,
                    ),
                    color: const Color(0xFF2D6A4F),
                    icon: Icons.route_rounded,
                    value: _deleteGpx,
                    onChanged: (val) {
                      setState(() {
                        _deleteGpx = val ?? false;
                      });
                    },
                  ),

                  // 2. Checkbox Maps
                  StorageCheckboxItem(
                    title: 'Maps',
                    sizeFormatted: OfflineStorageBar.formatBytes(
                      widget.mapBytes,
                    ),
                    color: const Color(0xFF1E88E5),
                    icon: Icons.map_rounded,
                    value: _deleteMaps,
                    onChanged: (val) {
                      setState(() {
                        _deleteMaps = val ?? false;
                      });
                    },
                  ),

                  // 3. Checkbox Images
                  StorageCheckboxItem(
                    title: 'Images',
                    sizeFormatted: OfflineStorageBar.formatBytes(
                      widget.imageBytes,
                    ),
                    color: const Color(0xFFD97706),
                    icon: Icons.photo_size_select_actual_rounded,
                    value: _deleteImages,
                    onChanged: (val) {
                      setState(() {
                        _deleteImages = val ?? false;
                      });
                    },
                  ),

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.35,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.7),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Opacity(
                          opacity: hasSelection ? 1.0 : 0.45,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: hasSelection
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFDC2626,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: hasSelection
                                      ? () => Navigator.of(context).pop(
                                          DeleteStorageResult(
                                            gpx: _deleteGpx,
                                            maps: _deleteMaps,
                                            images: _deleteImages,
                                          ),
                                        )
                                      : null,
                                  splashColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(
                                            0xFFEF4444,
                                          ).withValues(alpha: 0.90),
                                          const Color(
                                            0xFFDC2626,
                                          ).withValues(alpha: 0.85),
                                          const Color(
                                            0xFFB91C1C,
                                          ).withValues(alpha: 0.90),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                        width: 1.2,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal dialog konfirmasi final sebelum data offline benar-benar dihapus
class ConfirmDeleteStorageDialog extends StatelessWidget {
  final String? totalSizeFormatted;
  final List<String>? selectedCategories;

  const ConfirmDeleteStorageDialog({
    super.key,
    this.totalSizeFormatted,
    this.selectedCategories,
  });

  String get _displayTotalSize {
    if (totalSizeFormatted != null && totalSizeFormatted!.isNotEmpty) {
      return totalSizeFormatted!;
    }
    return selectedCategories?.join(', ') ?? '0 B';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.60),
                    Colors.white.withValues(alpha: 0.78),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFDC2626,
                          ).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFDC2626,
                            ).withValues(alpha: 0.20),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Konfirmasi Hapus',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Apakah Anda yakin ingin menghapus data offline yang dipilih?',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total size :',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          _displayTotalSize,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.35,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.7),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFDC2626,
                                ).withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(true),
                                splashColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.90),
                                        const Color(
                                          0xFFDC2626,
                                        ).withValues(alpha: 0.85),
                                        const Color(
                                          0xFFB91C1C,
                                        ).withValues(alpha: 0.90),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 1.2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Ya, Hapus',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Item checklist checkbox individual dalam modal hapus penyimpanan
class StorageCheckboxItem extends StatelessWidget {
  final String title;
  final String sizeFormatted;
  final Color color;
  final IconData icon;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const StorageCheckboxItem({
    super.key,
    required this.title,
    required this.sizeFormatted,
    required this.color,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? color.withValues(alpha: 0.55)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '($sizeFormatted)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Checkbox(
                  value: value,
                  activeColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
