import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';

class NavigationScaleIndicator extends StatelessWidget {
  final Mountain mountain;
  final double? distanceToMountainKm;

  const NavigationScaleIndicator({
    super.key,
    required this.mountain,
    this.distanceToMountainKm,
  });

  @override
  Widget build(BuildContext context) {
    final distText = distanceToMountainKm != null
        ? '${distanceToMountainKm!.toStringAsFixed(1)} km ke pusat gunung'
        : 'Tinggi: ${mountain.elevation} mdpl';

    return Positioned(
      left: 14,
      bottom: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'JARAK GPS',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppTheme.outline,
              ),
            ),
            Text(
              distText,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

