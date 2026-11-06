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

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        initialRotation: initialRotation,
        minZoom: 10.0,
        maxZoom: 18.0,
        onTap: onTap,
        onPositionChanged: onPositionChanged,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
          tileProvider: offlineBasePath != null
              ? OfflineFirstTileProvider(
                  mountainId: mountainId,
                  offlineBasePath: offlineBasePath!,
                )
              : null,
          userAgentPackageName: 'ayo.mendaki.bersama',
          maxNativeZoom: 16,
          maxZoom: 18,
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        if (markers.isNotEmpty) MarkerLayer(rotate: true, markers: markers),
      ],
    );
  }
}

