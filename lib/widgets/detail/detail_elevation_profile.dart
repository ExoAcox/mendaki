import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/route.dart';

class DetailElevationProfile extends StatelessWidget {
  final HikingRoute route;
  final int peakElevation;

  const DetailElevationProfile({
    super.key,
    required this.route,
    required this.peakElevation,
  });

  @override
  Widget build(BuildContext context) {
    // Elevasi basecamp dari API dan elevasi gain ke puncak
    final basecampElevation = route.basecampElevation;
    final elevationGain = peakElevation > basecampElevation
        ? peakElevation - basecampElevation
        : 0;

    final pos2Elevation =
        basecampElevation + (elevationGain * 0.35).round();
    final pos3Elevation =
        basecampElevation + (elevationGain * 0.75).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profil Elevasi Jalur ${route.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Kontur ketinggian & pos pendakian',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Tanjakan',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '+$elevationGain m',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Elevation Chart Visual
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                painter: _ElevationChartPainter(),
              ),
            ),
            const SizedBox(height: 8),

            // Waypoint Elevation Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWaypointLabel('Basecamp', '${basecampElevation}m', AppTheme.onSurface),
                _buildWaypointLabel(route.hasWater ? 'Pos Air' : 'Pos 2', '${pos2Elevation}m', const Color(0xFF0288D1)),
                _buildWaypointLabel('Pos Camp', '${pos3Elevation}m', AppTheme.primary),
                _buildWaypointLabel('Puncak', '${peakElevation}m', const Color(0xFFBA1A1A)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointLabel(String name, String elevation, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          elevation,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ElevationChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw dashed horizontal grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFBFC9C1).withValues(alpha: 0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double y = h * 0.25; y < h; y += h * 0.35) {
      _drawDashedLine(canvas, Offset(0, y), Offset(w, y), gridPaint);
    }

    // Path points
    final p0 = Offset(0, h * 0.88);
    final p1 = Offset(w * 0.28, h * 0.72);
    final p2 = Offset(w * 0.62, h * 0.40);
    final p3 = Offset(w * 0.96, h * 0.12);

    final linePath = Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(w * 0.12, h * 0.84, w * 0.18, h * 0.78, p1.dx, p1.dy)
      ..cubicTo(w * 0.40, h * 0.60, w * 0.50, h * 0.48, p2.dx, p2.dy)
      ..cubicTo(w * 0.75, h * 0.30, w * 0.86, h * 0.18, p3.dx, p3.dy);

    // Gradient fill below the line
    final fillPath = Path.from(linePath)
      ..lineTo(p3.dx, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x600F5238),
          Color(0x050F5238),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Main Stroke line
    final linePaint = Paint()
      ..color = const Color(0xFF0F5238)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(linePath, linePaint);

    // Draw Waypoint Markers
    _drawMarker(canvas, p0, Colors.white, const Color(0xFF0F5238), 4.5);
    _drawMarker(canvas, p1, const Color(0xFF0288D1), Colors.white, 4.0);
    _drawMarker(canvas, p2, const Color(0xFF0F5238), Colors.white, 4.5);
    _drawMarker(canvas, p3, const Color(0xFFBA1A1A), Colors.white, 5.5);
  }

  void _drawMarker(Canvas canvas, Offset center, Color fillColor, Color strokeColor, double radius) {
    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = strokeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, stroke);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double currentX = start.dx;
    while (currentX < end.dx) {
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset((currentX + dashWidth).clamp(0, end.dx), start.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
