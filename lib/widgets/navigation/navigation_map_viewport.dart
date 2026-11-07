import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mendaki/core/services/offline_map_service.dart';

class NavigationMapViewport extends StatelessWidget {
  final MapController mapController;
  final LatLng initialCenter;
  final double initialZoom;
  final double initialRotation;
  final String? offlineBasePath;
  final String mountainId;
  final List<Polyline> polylines;
  final List<Marker> markers;
  final void Function(TapPosition, LatLng)? onTap;
  final void Function(MapCamera, bool)? onPositionChanged;

  const NavigationMapViewport({
    super.key,
    required this.mapController,
    required this.initialCenter,
    this.initialZoom = 14.0,
    this.initialRotation = 0.0,
    this.offlineBasePath,
    required this.mountainId,
    required this.polylines,
    required this.markers,
    this.onTap,
    this.onPositionChanged,
  });

  LatLngBounds _calculateBounds() {
    // 15 km buffer ≈ 0.135 derajat
    const buffer = 0.135;
    double minLat = initialCenter.latitude;
    double maxLat = initialCenter.latitude;
    double minLng = initialCenter.longitude;
    double maxLng = initialCenter.longitude;

    for (final poly in polylines) {
      for (final pt in poly.points) {
        if (pt.latitude < minLat) minLat = pt.latitude;
        if (pt.latitude > maxLat) maxLat = pt.latitude;
        if (pt.longitude < minLng) minLng = pt.longitude;
        if (pt.longitude > maxLng) maxLng = pt.longitude;
      }
    }

    return LatLngBounds(
      LatLng(minLat - buffer, minLng - buffer),
      LatLng(maxLat + buffer, maxLng + buffer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        initialRotation: initialRotation,
        minZoom: 12.0,
        maxZoom: 16.5,
        cameraConstraint: CameraConstraint.containCenter(
          bounds: _calculateBounds(),
        ),
        onTap: onTap,
        onPositionChanged: onPositionChanged,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          tileProvider: offlineBasePath != null
              ? OfflineFirstTileProvider(
                  mountainId: mountainId,
                  offlineBasePath: offlineBasePath!,
                )
              : null,
          userAgentPackageName: 'ayo.mendaki.bersama',
          maxNativeZoom: 17,
          maxZoom: 18,
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        if (markers.isNotEmpty) MarkerLayer(rotate: true, markers: markers),
      ],
    );
  }
}
