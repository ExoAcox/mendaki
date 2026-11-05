import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';

class NavigationFarView extends StatelessWidget {
  final Mountain mountain;
  final double? distanceToMountainKm;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const NavigationFarView({
    super.key,
    required this.mountain,
    required this.distanceToMountainKm,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final distStr = distanceToMountainKm != null
        ? '${distanceToMountainKm!.toStringAsFixed(1)} km'
        : '> 15 km';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
          onPressed: onBack,
          tooltip: 'Kembali',
        ),
        title: const Text(
          'Verifikasi Area Pendakian',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration / Warning Ring
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB067).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFB067).withValues(alpha: 0.4),
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.explore_off_rounded,
                      size: 50,
                      color: Color(0xFFA33D23),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Pill Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA33D23).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFA33D23).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Color(0xFFA33D23),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'DI LUAR AREA PENDAKIAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFA33D23),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                const Text(
                  'Lokasi Terlalu Jauh dari Gunung',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),

                // Message Text
                Text(
                  'Fitur peta dan navigasi live pendakian hanya dapat dibuka saat Anda berada di sekitar area ${mountain.name} (radius maksimal 15 km dari kaki gunung / basecamp).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Status Telemetry Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDistanceInfoRow(
                        icon: Icons.landscape_rounded,
                        label: 'Target Gunung',
                        value: mountain.name,
                        accentColor: AppTheme.primary,
                      ),
                      const Divider(height: 22),
                      _buildDistanceInfoRow(
                        icon: Icons.my_location_rounded,
                        label: 'Jarak GPS Anda Saat Ini',
                        value: distStr,
                        accentColor: const Color(0xFFA33D23),
                        isHighlight: true,
                      ),
                      const Divider(height: 22),
                      _buildDistanceInfoRow(
                        icon: Icons.radar_rounded,
                        label: 'Batas Radius Navigasi',
                        value: 'Maksimal 15.0 km',
                        accentColor: AppTheme.outline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Action 1: Coba Cek Ulang GPS (Retry GPS)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text(
                      'Coba Cek Ulang GPS',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action 2: Kembali (Back)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text(
                      'Kembali ke Detail Gunung',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlight ? 15 : 13,
                  fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
                  color: isHighlight ? accentColor : AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

