import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/widgets/navigation/navigation_floating_button.dart';
import 'package:mendaki/widgets/navigation/navigation_markers.dart';

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
      children: [
        // Floating Compass Button
        NavigationFloatingButton(
          customChild: CompassNeedle(rotationDegrees: currentRotation),
          onTap: onCompassTap,
        ),
        const SizedBox(height: 10),
        // Floating Find Me Button
        NavigationFloatingButton(
          icon: Icons.my_location_rounded,
          color: AppTheme.primary,
          onTap: onFindMeTap,
        ),
      ],
    );
  }
}

