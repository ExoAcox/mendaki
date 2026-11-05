import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:mendaki/models/waypoint.dart';

class NavigationSummitMarkerWidget extends StatelessWidget {
  static const double markerWidth = 140.0;
  static const double markerHeight = 60.0;
  static final Alignment markerAlignment = Marker.computePixelAlignment(
    width: markerWidth,
    height: markerHeight,
    left: 70.0,
    top: 44.0,
  );

  final Waypoint waypoint;
  final bool isSelected;

  const NavigationSummitMarkerWidget({
    super.key,
    required this.waypoint,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleanName = waypoint.name
        .replaceAll('PUNCAK', '')
        .replaceAll('Puncak', '')
        .trim();
    final label = cleanName.isNotEmpty ? cleanName : waypoint.name;
    const summitColor = Color(0xFFBA1A1A);

    return SizedBox(
      width: markerWidth,
      height: markerHeight,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: summitColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: summitColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.flag_rounded, color: Colors.white, size: 13),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class NavigationBasecampMarkerWidget extends StatelessWidget {
  static const double markerWidth = 140.0;
  static const double markerHeight = 60.0;
  static final Alignment markerAlignment = Marker.computePixelAlignment(
    width: markerWidth,
    height: markerHeight,
    left: 70.0,
    top: 44.0,
  );

  final Waypoint waypoint;
  final bool isSelected;

  const NavigationBasecampMarkerWidget({
    super.key,
    required this.waypoint,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleanName = waypoint.name
        .replaceAll('BASECAMP', 'BC')
        .replaceAll('Basecamp', 'BC')
        .trim();
    final label = cleanName.isNotEmpty ? cleanName : waypoint.name;
    const basecampColor = Color(0xFF1565C0);

    return SizedBox(
      width: markerWidth,
      height: markerHeight,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: basecampColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: basecampColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.cottage_rounded, color: Colors.white, size: 13),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class TentIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TentIcon({super.key, this.size = 14, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TentPainter(color: color),
    );
  }
}

class _TentPainter extends CustomPainter {
  final Color color;

  const _TentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wallPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadePaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final doorShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;

    // Peak and corners (isometric camping ridge tent)
    final peak = Offset(w * 0.40, h * 0.12);
    final frontLeft = Offset(w * 0.08, h * 0.88);
    final frontRight = Offset(w * 0.58, h * 0.88);
    final backPeak = Offset(w * 0.76, h * 0.20);
    final backRight = Offset(w * 0.92, h * 0.76);

    // Side roof / slope
    final sidePath = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(backPeak.dx, backPeak.dy)
      ..lineTo(backRight.dx, backRight.dy)
      ..lineTo(frontRight.dx, frontRight.dy)
      ..close();
    canvas.drawPath(sidePath, shadePaint);

    // Front door opening shadow (triangle door)
    final doorApex = Offset(w * 0.40, h * 0.44);
    final doorLeft = Offset(w * 0.24, h * 0.88);
    final doorRight = Offset(w * 0.56, h * 0.88);
    final doorPath = Path()
      ..moveTo(doorApex.dx, doorApex.dy)
      ..lineTo(doorLeft.dx, doorLeft.dy)
      ..lineTo(doorRight.dx, doorRight.dy)
      ..close();
    canvas.drawPath(doorPath, doorShadowPaint);

    // Front left wall flap
    final leftFlap = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(frontLeft.dx, frontLeft.dy)
      ..lineTo(doorLeft.dx, doorLeft.dy)
      ..lineTo(doorApex.dx, doorApex.dy)
      ..close();
    canvas.drawPath(leftFlap, wallPaint);

    // Front right wall flap
    final rightFlap = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(doorApex.dx, doorApex.dy)
      ..lineTo(doorRight.dx, doorRight.dy)
      ..lineTo(frontRight.dx, frontRight.dy)
      ..close();
    canvas.drawPath(rightFlap, wallPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NavigationCampMarkerWidget extends StatelessWidget {
  static const double labeledWidth = 140.0;
  static const double labeledHeight = 60.0;
  static final Alignment labeledAlignment = Marker.computePixelAlignment(
    width: labeledWidth,
    height: labeledHeight,
    left: 70.0,
    top: 44.0,
  );

  static const double unselectedSize = 28.0;
  static const Alignment unselectedAlignment = Alignment.center;

  final Waypoint waypoint;
  final bool isSelected;
  final bool showLabel;

  const NavigationCampMarkerWidget({
    super.key,
    required this.waypoint,
    this.isSelected = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    const campColor = Color(0xFF2E7D32);

    final pinWidget = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: campColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(child: TentIcon(size: 13, color: Colors.white)),
    );

    if (!showLabel) {
      if (isSelected) {
        return SizedBox(
          width: labeledWidth,
          height: labeledHeight,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: campColor.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  waypoint.name.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.noScaling,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              pinWidget,
              const SizedBox(height: 4),
            ],
          ),
        );
      }
      return Center(child: pinWidget);
    }

    final label = waypoint.name.trim();

    return SizedBox(
      width: labeledWidth,
      height: labeledHeight,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: campColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          pinWidget,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class NavigationRegularWaypointMarkerWidget extends StatelessWidget {
  static const double unselectedSize = 28.0;
  static const Alignment unselectedAlignment = Alignment.center;

  static const double labeledWidth = 140.0;
  static const double labeledHeight = 60.0;
  static final Alignment labeledAlignment = Marker.computePixelAlignment(
    width: labeledWidth,
    height: labeledHeight,
    left: 70.0,
    top: 44.0,
  );

  final Waypoint waypoint;
  final bool isSelected;

  const NavigationRegularWaypointMarkerWidget({
    super.key,
    required this.waypoint,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    const regularColor = Color(0xFF0F5238);

    if (isSelected) {
      return SizedBox(
        width: labeledWidth,
        height: labeledHeight,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: regularColor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                waypoint.name.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: regularColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      );
    }

    return Center(
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: regularColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to build a [Marker] for any waypoint with pixel-perfect alignment.
///
/// Ensures the pin/dot icon's center is precisely placed on [waypoint.latitude, waypoint.longitude],
/// both with and without labels, avoiding jumpy displacement or anchor drift.
Marker buildWaypointMapMarker({
  required Waypoint waypoint,
  required bool isSelected,
  required bool isSummit,
  required bool isBasecamp,
  required bool isCamp,
  bool showCampLabel = false,
  bool rotate = false,
  VoidCallback? onTap,
}) {
  final double width;
  final double height;
  final Alignment alignment;
  final Widget child;

  if (isSummit) {
    width = NavigationSummitMarkerWidget.markerWidth;
    height = NavigationSummitMarkerWidget.markerHeight;
    alignment = NavigationSummitMarkerWidget.markerAlignment;
    child = NavigationSummitMarkerWidget(
      waypoint: waypoint,
      isSelected: isSelected,
    );
  } else if (isBasecamp) {
    width = NavigationBasecampMarkerWidget.markerWidth;
    height = NavigationBasecampMarkerWidget.markerHeight;
    alignment = NavigationBasecampMarkerWidget.markerAlignment;
    child = NavigationBasecampMarkerWidget(
      waypoint: waypoint,
      isSelected: isSelected,
    );
  } else if (isCamp) {
    if (showCampLabel || isSelected) {
      width = NavigationCampMarkerWidget.labeledWidth;
      height = NavigationCampMarkerWidget.labeledHeight;
      alignment = NavigationCampMarkerWidget.labeledAlignment;
      child = NavigationCampMarkerWidget(
        waypoint: waypoint,
        isSelected: isSelected,
        showLabel: showCampLabel,
      );
    } else {
      width = NavigationCampMarkerWidget.unselectedSize;
      height = NavigationCampMarkerWidget.unselectedSize;
      alignment = NavigationCampMarkerWidget.unselectedAlignment;
      child = NavigationCampMarkerWidget(
        waypoint: waypoint,
        isSelected: false,
        showLabel: false,
      );
    }
  } else {
    if (isSelected) {
      width = NavigationRegularWaypointMarkerWidget.labeledWidth;
      height = NavigationRegularWaypointMarkerWidget.labeledHeight;
      alignment = NavigationRegularWaypointMarkerWidget.labeledAlignment;
    } else {
      width = NavigationRegularWaypointMarkerWidget.unselectedSize;
      height = NavigationRegularWaypointMarkerWidget.unselectedSize;
      alignment = NavigationRegularWaypointMarkerWidget.unselectedAlignment;
    }
    child = NavigationRegularWaypointMarkerWidget(
      waypoint: waypoint,
      isSelected: isSelected,
    );
  }

  return Marker(
    key: ValueKey(
      'wpt_${waypoint.latitude}_${waypoint.longitude}_${waypoint.name}',
    ),
    point: LatLng(waypoint.latitude, waypoint.longitude),
    width: width,
    height: height,
    alignment: alignment,
    rotate: rotate,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    ),
  );
}

class NavigationCalloutBubbleWidget extends StatelessWidget {
  final String text;

  const NavigationCalloutBubbleWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF111C2D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF89EDBA), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              height: 1.1,
            ),
          ),
        ),
        const Icon(Icons.arrow_drop_down, color: Color(0xFF111C2D), size: 10),
      ],
    );
  }
}

class NavigationUserMarker extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final double? heading;

  const NavigationUserMarker({
    super.key,
    required this.pulseAnimation,
    this.heading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 24 * pulseAnimation.value,
              height: 24 * pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF8162).withValues(
                  alpha: (1.8 - pulseAnimation.value).clamp(0.0, 0.45),
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            Transform.rotate(
              angle: heading != null ? (heading! * math.pi / 180) : 0.0,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFA33D23),
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CompassNeedle extends StatelessWidget {
  final double rotationDegrees;

  const CompassNeedle({super.key, required this.rotationDegrees});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationDegrees * (math.pi / 180.0),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(
              top: 0,
              child: Text(
                'N',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFBA1A1A),
                  height: 1.0,
                ),
              ),
            ),
            CustomPaint(
              size: const Size(12, 20),
              painter: _CompassNeedlePainter(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double midX = size.width / 2;
    final double midY = size.height / 2;

    // North Needle (Red)
    final northPaint = Paint()
      ..color = const Color(0xFFBA1A1A)
      ..style = PaintingStyle.fill;
    final northPath = Path()
      ..moveTo(midX, 3.5)
      ..lineTo(midX + 4.5, midY)
      ..lineTo(midX, midY - 1)
      ..close();
    canvas.drawPath(northPath, northPaint);

    final northLightPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.fill;
    final northPathLeft = Path()
      ..moveTo(midX, 3.5)
      ..lineTo(midX - 4.5, midY)
      ..lineTo(midX, midY - 1)
      ..close();
    canvas.drawPath(northPathLeft, northLightPaint);

    // South Needle (Grey / Silver)
    final southPaint = Paint()
      ..color = const Color(0xFF757575)
      ..style = PaintingStyle.fill;
    final southPath = Path()
      ..moveTo(midX, size.height - 1)
      ..lineTo(midX + 4.5, midY)
      ..lineTo(midX, midY + 1)
      ..close();
    canvas.drawPath(southPath, southPaint);

    final southLightPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.fill;
    final southPathLeft = Path()
      ..moveTo(midX, size.height - 1)
      ..lineTo(midX - 4.5, midY)
      ..lineTo(midX, midY + 1)
      ..close();
    canvas.drawPath(southPathLeft, southLightPaint);

    // Center pivot
    final pivotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(midX, midY), 2.2, pivotPaint);

    final pivotBorder = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(midX, midY), 2.2, pivotBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
