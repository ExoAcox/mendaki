import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/waypoint.dart';

class NavigationWaypointsSheet extends StatelessWidget {
  final List<Waypoint> waypoints;
  final void Function(LatLng target) onSelectWaypoint;

  const NavigationWaypointsSheet({
    super.key,
    required this.waypoints,
    required this.onSelectWaypoint,
  });

  static void show(
    BuildContext context, {
    required List<Waypoint> waypoints,
    required void Function(LatLng target) onSelectWaypoint,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => NavigationWaypointsSheet(
        waypoints: waypoints,
        onSelectWaypoint: (target) {
          Navigator.pop(ctx);
          onSelectWaypoint(target);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Pos & Waypoint',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${waypoints.length} Pos Terdata',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (waypoints.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Tidak ada data waypoint di rute ini.',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: waypoints.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (c, idx) {
                    final wpt = waypoints[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: wpt.hasWater
                            ? Colors.blue.withValues(alpha: 0.15)
                            : AppTheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          wpt.hasWater
                              ? Icons.water_drop_rounded
                              : (wpt.isCamp
                                  ? Icons.holiday_village_rounded
                                  : Icons.place_rounded),
                          size: 16,
                          color: wpt.hasWater
                              ? Colors.blueAccent
                              : AppTheme.primary,
                        ),
                      ),
                      title: Text(
                        wpt.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        wpt.elevation != null
                            ? 'Elevasi: ${wpt.elevation!.round()} mdpl'
                            : 'Lat: ${wpt.latitude.toStringAsFixed(4)}, Lng: ${wpt.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.location_searching_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        onPressed: () {
                          onSelectWaypoint(LatLng(wpt.latitude, wpt.longitude));
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

