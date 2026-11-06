import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/widgets/navigation/navigation_floating_button.dart';
import 'package:mendaki/widgets/navigation/navigation_markers.dart';

class NavigationMetricChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const NavigationMetricChip({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationFloatingControls extends StatelessWidget {
  final double currentRotation;
  final VoidCallback onCompassTap;
  final VoidCallback onFindMeTap;
  final Duration? elapsedDuration;
  final double? altitude;

  const NavigationFloatingControls({
    super.key,
    required this.currentRotation,
    required this.onCompassTap,
    required this.onFindMeTap,
    this.elapsedDuration,
    this.altitude,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 1. Floating Find Me Button (Paling Atas)
        NavigationFloatingButton(
          icon: Icons.my_location_rounded,
          color: AppTheme.primary,
          onTap: onFindMeTap,
        ),
        const SizedBox(height: 10),

        // 2. Floating Compass Button
        NavigationFloatingButton(
          customChild: CompassNeedle(rotationDegrees: currentRotation),
          onTap: onCompassTap,
        ),

        // 3. Altitude Chip (Chip Terpisah)
        if (elapsedDuration != null || altitude != null) ...[
          const SizedBox(height: 10),
          NavigationMetricChip(
            icon: Icons.landscape_rounded,
            text: altitude != null ? '${altitude!.round()} mdpl' : '-- mdpl',
          ),
        ],

        // 4. Elapsed Duration Chip (Paling Bawah)
        if (elapsedDuration != null) ...[
          const SizedBox(height: 10),
          NavigationMetricChip(
            icon: Icons.timer_outlined,
            text: _formatDuration(elapsedDuration!),
          ),
        ],
      ],
    );
  }
}
