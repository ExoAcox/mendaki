import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';

class NavigationFloatingControls extends StatelessWidget {
  final VoidCallback onLayerTap;
  final VoidCallback onCompassTap;
  final VoidCallback onWaypointsTap;
  final VoidCallback onRecenterTap;

  const NavigationFloatingControls({
    super.key,
    required this.onLayerTap,
    required this.onCompassTap,
    required this.onWaypointsTap,
    required this.onRecenterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 14,
      right: 14,
      child: Column(
        children: [
          _buildTacticalButton(
            icon: Icons.layers_outlined,
            color: AppTheme.onSurface,
            tooltip: 'Tipe Peta',
            onTap: onLayerTap,
          ),
          const SizedBox(height: 10),
          _buildTacticalButton(
            icon: Icons.explore_rounded,
            color: AppTheme.primary,
            tooltip: 'Arah Kompas / Reset Orientasi',
            onTap: onCompassTap,
          ),
          const SizedBox(height: 10),
          _buildTacticalButton(
            icon: Icons.alt_route_rounded,
            color: const Color(0xFFA33D23),
            tooltip: 'Daftar Pos & Waypoint',
            onTap: onWaypointsTap,
          ),
          const SizedBox(height: 10),
          _buildTacticalButton(
            icon: Icons.my_location_rounded,
            color: AppTheme.primary,
            tooltip: 'Pusatkan ke Lokasi Saya',
            onTap: onRecenterTap,
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

