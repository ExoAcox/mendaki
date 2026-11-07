import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/widgets/navigation/navigation_floating_button.dart';
import 'package:mendaki/widgets/navigation/navigation_markers.dart';

/// Single unified chip di bagian paling bawah yang menampilkan 3 info navigasi:
/// 1. Waktu berlalu (Elapsed time)
/// 2. Ketinggian saat ini (Altitude mdpl)
/// 3. Jarak yang dilalui (Distance walked) dengan ikon kaki
class NavigationMetricsChip extends StatelessWidget {
  final Duration elapsedDuration;
  final double? altitude;
  final double distanceKm;

  const NavigationMetricsChip({
    super.key,
    required this.elapsedDuration,
    this.altitude,
    this.distanceKm = 0.0,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Elapsed Time
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: AppTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _formatDuration(elapsedDuration),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildDivider(),

          // 2. Jarak yang dilalui (icon kaki)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_walk_rounded,
                  color: AppTheme.primary,
                  size: 17,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _formatDistance(distanceKm),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildDivider(),

          // 3. Altitude
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.landscape_rounded,
                  color: AppTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    altitude != null ? '${altitude!.round()} mdpl' : '-- mdpl',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 1,
        height: 14,
        color: Colors.black.withValues(alpha: 0.15),
      ),
    );
  }
}

/// Kolom kontrol melayang di sebelah kanan atas chip navigasi:
/// - Bagian atas: Button Compass
/// - Bagian bawah: Button Find Me
class NavigationFloatingControls extends StatelessWidget {
  final double currentRotation;
  final VoidCallback onCompassTap;
  final VoidCallback onFindMeTap;

  const NavigationFloatingControls({
    super.key,
    required this.currentRotation,
    required this.onCompassTap,
    required this.onFindMeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 1. Floating Compass Button (Di Atas)
        NavigationFloatingButton(
          customChild: CompassNeedle(rotationDegrees: currentRotation),
          onTap: onCompassTap,
        ),
        const SizedBox(height: 10),

        // 2. Floating Find Me Button (Di Bawah Compass)
        NavigationFloatingButton(
          icon: Icons.my_location_rounded,
          color: AppTheme.primary,
          onTap: onFindMeTap,
        ),
      ],
    );
  }
}
