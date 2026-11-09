import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';

class DetailQuickStats extends StatelessWidget {
  final Mountain mountain;

  const DetailQuickStats({super.key, required this.mountain});

  @override
  Widget build(BuildContext context) {
    // Calculate average distance
    double avgDist = 0;
    if (mountain.routes.isNotEmpty) {
      final total = mountain.routes.fold<double>(
        0.0,
        (sum, t) => sum + t.distanceKm,
      );
      avgDist = total / mountain.routes.length;
    }

    // Calculate average elevation gain from routes
    int avgElevGain = 0;
    if (mountain.routes.isNotEmpty) {
      final validRoutes = mountain.routes
          .where((r) => r.elevationGainMeters > 0)
          .toList();
      if (validRoutes.isNotEmpty) {
        final totalGain = validRoutes.fold<int>(
          0,
          (sum, r) => sum + r.elevationGainMeters,
        );
        avgElevGain =
            mountain.elevation - (totalGain / validRoutes.length).round();
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Jarak Rata-rata',
            value: avgDist > 0 ? avgDist.toStringAsFixed(1) : '-',
            unit: 'km',
            valueColor: AppTheme.primary,
          ),
          _buildDivider(),
          _buildStatItem(
            label: 'Elevasi Gain',
            value: avgElevGain > 0 ? '+$avgElevGain' : '-',
            unit: 'meter',
            valueColor: AppTheme.primary,
          ),
          _buildDivider(),
          _buildStatItem(
            label: 'Estimasi',
            value: mountain.estimatedTime.isNotEmpty
                ? mountain.estimatedTime
                : '2D1N',
            unit: 'Waktu',
            valueColor: AppTheme.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required String unit,
    required Color valueColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppTheme.outlineVariant.withValues(alpha: 0.35),
    );
  }
}
