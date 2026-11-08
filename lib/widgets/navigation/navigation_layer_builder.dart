import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mendaki/core/services/gpx_parser_service.dart';
import 'package:mendaki/models/waypoint.dart';
import 'package:mendaki/widgets/map/map_marker.dart';

/// Helper penyusun polyline & marker untuk Navigation Map
class NavigationLayerBuilder {
  NavigationLayerBuilder._();

  /// Menyusun polylines dari data GPX rute pendakian
  static List<Polyline> buildGpxPolylines(GpxData gpxData) {
    final polylines = <Polyline>[];
    const polylineColor = Color(0xFF0F5238);

    for (final track in gpxData.tracks) {
      final points = track.trackPoints
          .map((pt) => LatLng(pt.latitude, pt.longitude))
          .toList();

      if (points.isNotEmpty) {
        // 1. Background polyline (border putih kontras tinggi)
        polylines.add(
          Polyline(
            points: points,
            strokeWidth: 5.5,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        );

        // 2. Foreground polyline (warna seragam hijau rute)
        polylines.add(
          Polyline(points: points, strokeWidth: 3.5, color: polylineColor),
        );
      }
    }
    return polylines;
  }

  /// Menyusun polylines jejak langkah pengguna (breadcrumb path)
  static List<Polyline> buildBreadcrumbPolylines(List<LatLng> breadcrumbPath) {
    if (breadcrumbPath.length < 2) return const [];

    return [
      // 1. Background casing putih untuk trace path
      Polyline(
        points: List<LatLng>.from(breadcrumbPath),
        strokeWidth: 6.0,
        color: Colors.white.withValues(alpha: 0.9),
      ),
      // 2. Foreground trace path warna secondary
      Polyline(
        points: List<LatLng>.from(breadcrumbPath),
        strokeWidth: 4.0,
        color: const Color(0xFFA33D23),
      ),
    ];
  }

  /// Menyusun list markers navigasi (pos, camp, summit, basecamp, selected, dan pin GPS pengguna)
  static List<Marker> buildNavigationMarkers({
    required GpxData? gpxData,
    required Waypoint? selectedWaypoint,
    required bool hasUserPosition,
    required LatLng currentPosition,
    required Animation<double> pulseAnimation,
    required double? userHeading,
    void Function(Waypoint wpt)? onWaypointTap,
  }) {
    final regularMarkers = <Marker>[];
    final campMarkers = <Marker>[];
    final summitMarkers = <Marker>[];
    final basecampMarkers = <Marker>[];
    Marker? selectedMarker;

    if (gpxData != null) {
      for (final wpt in gpxData.waypoints) {
        final isSelected = selectedWaypoint == wpt;
        final isSummit = wpt.isSummit;
        final isBasecamp = !isSummit && wpt.isBasecamp;
        final isCamp = !isSummit && !isBasecamp && wpt.isCamp;

        final marker = buildWaypointMapMarker(
          waypoint: wpt,
          isSelected: isSelected,
          isSummit: isSummit,
          isBasecamp: isBasecamp,
          isCamp: isCamp,
          showCampLabel: true,
          rotate: true,
          onTap: onWaypointTap != null ? () => onWaypointTap(wpt) : null,
        );

        if (isSelected) {
          selectedMarker = marker;
        } else if (isBasecamp) {
          basecampMarkers.add(marker);
        } else if (isSummit) {
          summitMarkers.add(marker);
        } else if (isCamp) {
          campMarkers.add(marker);
        } else {
          regularMarkers.add(marker);
        }
      }
    }

    final markers = <Marker>[
      ...regularMarkers,
      ...campMarkers,
      ...summitMarkers,
      ...basecampMarkers,
    ];

    if (selectedMarker != null) {
      markers.add(selectedMarker);
    }

    // Pin Posisi GPS Pendaki (Live radar pulse) jika posisi tersedia
    if (hasUserPosition) {
      markers.add(
        Marker(
          point: currentPosition,
          width: 52,
          height: 52,
          rotate: false,
          child: NavigationUserMarker(
            pulseAnimation: pulseAnimation,
            heading: userHeading,
          ),
        ),
      );
    }

    return markers;
  }
}

