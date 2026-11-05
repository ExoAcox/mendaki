import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/route.dart';

class DetailRouteItem extends StatelessWidget {
  final List<HikingRoute> routes;
  final int? peakElevation;

  const DetailRouteItem({
    super.key,
    required this.routes,
    this.peakElevation,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${routes.length} Jalur Pendakian',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Column of Route Cards
          Column(
            children: [
              for (int i = 0; i < routes.length; i++) ...[
                _buildRouteCard(route: routes[i]),
                if (i < routes.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard({required HikingRoute route}) {
    final gain =
        peakElevation != null && peakElevation! > route.basecampElevation
            ? peakElevation! - route.basecampElevation
            : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Route Name & Distance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jalur ${route.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          if (route.city != null &&
                              route.city!.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 11,
                                    color: AppTheme.outline,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      route.city!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      route.estimatedDuration.isNotEmpty
                          ? route.estimatedDuration
                          : '-',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 1: Elevasi Basecamp & Elevasi Gain
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.terrain_rounded,
                    iconColor: AppTheme.secondary,
                    label: 'Elevasi Basecamp',
                    value: '${route.basecampElevation} mdpl',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.trending_up_rounded,
                    iconColor: AppTheme.primary,
                    label: 'Elevasi Gain',
                    value: gain != null ? '+$gain m' : '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.straighten_rounded,
                    iconColor: AppTheme.primary,
                    label: 'Estimasi Jarak',
                    value:
                        '${route.distanceKm.toStringAsFixed(route.distanceKm.truncateToDouble() == route.distanceKm ? 0 : 1)} km',

                    // route.estimatedDuration.isNotEmpty
                    //     ? route.estimatedDuration
                    //     : '-',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF0288D1),
                    label: 'Sumber Air',
                    value: route.hasWater ? 'Tersedia' : 'Tidak Tersedia',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
