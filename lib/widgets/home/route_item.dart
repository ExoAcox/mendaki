import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/route.dart';

class RouteItem extends StatelessWidget {
  final HikingRoute track;

  const RouteItem({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hiking_rounded,
                size: 15,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                track.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              if (track.city != null && track.city!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  '(${track.city})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (track.hasWater) ...[
                const SizedBox(width: 6),
                const Text('💧', style: TextStyle(fontSize: 11)),
              ],
            ],
          ),
          Row(
            children: [
              Text(
                '${track.distanceKm.toInt()} km • Start ${track.startElevation} mdpl',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
