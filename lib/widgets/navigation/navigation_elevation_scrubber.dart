import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';

class NavigationElevationScrubber extends StatelessWidget {
  final int baseElevation;
  final int peakElevation;
  final int elevationGain;
  final List<double> elevations;

  const NavigationElevationScrubber({
    super.key,
    required this.baseElevation,
    required this.peakElevation,
    required this.elevationGain,
    required this.elevations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.landscape_rounded,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$baseElevation Mdpl',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(+$elevationGain m)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Sisa Elevasi: ',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${(peakElevation - baseElevation).clamp(0, 9999)} m',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFA33D23),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.flag_rounded,
                    size: 14,
                    color: Color(0xFFA33D23),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 24,
              width: double.infinity,
              child: CustomPaint(
                painter: ElevationSparklinePainter(
                  elevations: elevations.isNotEmpty
                      ? elevations
                      : [
                          baseElevation.toDouble(),
                          baseElevation + elevationGain * 0.25,
                          baseElevation + elevationGain * 0.55,
                          baseElevation + elevationGain * 0.85,
                          peakElevation.toDouble(),
                        ],
                  lineColor: AppTheme.primary,
                  fillColor: AppTheme.primary.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ElevationSparklinePainter extends CustomPainter {
  final List<double> elevations;
  final Color lineColor;
  final Color fillColor;

  ElevationSparklinePainter({
    required this.elevations,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (elevations.isEmpty) return;

    final double minEle = elevations.reduce((a, b) => a < b ? a : b);
    final double maxEle = elevations.reduce((a, b) => a > b ? a : b);
    final double range = (maxEle - minEle) == 0 ? 1.0 : (maxEle - minEle);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (elevations.length - 1).clamp(1, 999999);

    for (int i = 0; i < elevations.length; i++) {
      final x = i * stepX;
      final normalizedY = (elevations[i] - minEle) / range;
      final y = size.height - (normalizedY * (size.height - 4)) - 2;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant ElevationSparklinePainter oldDelegate) {
    return oldDelegate.elevations != elevations ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}

