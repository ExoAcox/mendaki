import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';

/// Badge atribusi ringkas untuk lisensi OpenTopoMap & OpenStreetMap.
/// Menampilkan teks ringkas legal di layar dan menampilkan detail lengkap saat diklik.
class MapAttributionBadge extends StatelessWidget {
  const MapAttributionBadge({super.key});

  /// Menampilkan dialog atribusi lisensi resmi lengkap
  static void showMapLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2421),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF89EDBA), size: 20),
            SizedBox(width: 8),
            Text(
              'Lisensi Peta',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Peta ini menggunakan OpenTopoMap berlisensi CC-BY-SA 3.0.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'Kartendaten: © OpenStreetMap-Mitwirkende, SRTM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Kartendarstellung: © OpenTopoMap (CC-BY-SA)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: Color(0xFF89EDBA),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showMapLicenseDialog(context),
              splashColor: AppTheme.primary.withValues(alpha: 0.12),
              highlightColor: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: const Text(
                  '© OpenTopoMap',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
