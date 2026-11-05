import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';

class NavigationBottomHud extends StatelessWidget {
  final Mountain mountain;
  final HikingRoute? route;
  final int elevationGain;
  final Duration elapsed;
  final bool isTracking;
  final VoidCallback onToggleTracking;
  final VoidCallback onRecenter;
  final VoidCallback onFinishHike;

  const NavigationBottomHud({
    super.key,
    required this.mountain,
    this.route,
    required this.elevationGain,
    required this.elapsed,
    required this.isTracking,
    required this.onToggleTracking,
    required this.onRecenter,
    required this.onFinishHike,
  });

  String _formatStopwatch(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final distanceText =
        route != null ? '${route!.distanceKm.toStringAsFixed(1)} km' : '6.0 km';
    final durationText =
        route?.estimatedDuration.isNotEmpty == true
            ? route!.estimatedDuration
            : mountain.estimatedTime;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Target Berikutnya Card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'TARGET BERIKUTNYA',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (route?.hasWater == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Air Tersedia 💧',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Puncak ${mountain.name} (${mountain.elevation}m)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        'Jarak: $distanceText • Estimasi: $durationText',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quad Telemetry Metrics Grid
          Row(
            children: [
              Expanded(
                child: NavigationMetricTile(
                  icon: Icons.timer_outlined,
                  iconColor: AppTheme.primary,
                  label: 'WAKTU BERJALAN',
                  value: _formatStopwatch(elapsed),
                  subtitle: isTracking ? 'Status: Berjalan' : 'Status: Jeda',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NavigationMetricTile(
                  icon: Icons.straighten_rounded,
                  iconColor: const Color(0xFFA33D23),
                  label: 'JARAK RUTE',
                  value: distanceText,
                  subtitle: route != null ? 'Jalur ${route!.name}' : 'Total Rute',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: NavigationMetricTile(
                  icon: Icons.schedule_rounded,
                  iconColor: const Color(0xFF006D48),
                  label: 'ESTIMASI WAKTU',
                  value: durationText,
                  subtitle: 'Tingkat: ${mountain.difficulty}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NavigationMetricTile(
                  icon: Icons.north_east_rounded,
                  iconColor: AppTheme.primary,
                  label: 'KETINGGIAN PUNCAK',
                  value: '${mountain.elevation} Mdpl',
                  subtitle: 'Total naik: +$elevationGain m',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Control Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onToggleTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTracking
                          ? AppTheme.primary
                          : const Color(0xFFA33D23),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isTracking
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isTracking ? 'Jeda Lacak' : 'Lanjutkan',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                width: 48,
                child: OutlinedButton(
                  onPressed: onRecenter,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: AppTheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                width: 48,
                child: OutlinedButton(
                  onPressed: onFinishHike,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: AppTheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Color(0xFFA33D23),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NavigationMetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const NavigationMetricTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.outline,
                  letterSpacing: 0.3,
                ),
              ),
              Icon(icon, size: 14, color: iconColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

