import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mendaki/core/services/gpx_parser_service.dart';
import 'package:mendaki/models/waypoint.dart';

/// Kumpulan fungsi kalkulasi matematika geodesi & arah kamera navigasi
class NavigationGeoUtils {
  NavigationGeoUtils._();

  /// Menghitung bearing (sudut kompas dalam derajat 0..360) dari titik [from] ke titik [to]
  static double calculateBearing(LatLng from, LatLng to) {
    final double lat1 = from.latitude * (math.pi / 180.0);
    final double lon1 = from.longitude * (math.pi / 180.0);
    final double lat2 = to.latitude * (math.pi / 180.0);
    final double lon2 = to.longitude * (math.pi / 180.0);

    final double dLon = lon2 - lon1;

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final double bearingRad = math.atan2(y, x);
    final double bearingDeg = (bearingRad * (180.0 / math.pi) + 360.0) % 360.0;
    return bearingDeg;
  }

  /// Menghitung rotasi kamera peta agar posisi puncak selalu menghadap ke atas (summit-up)
  static double calculateSummitUpRotation(LatLng currentPos, LatLng summitCoord) {
    final bearing = calculateBearing(currentPos, summitCoord);
    return (360.0 - bearing) % 360.0;
  }

  /// Mencari koordinat titik puncak dari [GpxData] (berdasarkan waypoint summit atau elevasi tertinggi)
  static LatLng findSummitCoordinate(GpxData? gpxData, LatLng fallback) {
    if (gpxData != null) {
      for (final wpt in gpxData.waypoints) {
        if (wpt.isSummit) {
          return LatLng(wpt.latitude, wpt.longitude);
        }
      }
      Waypoint? highest;
      for (final wpt in gpxData.waypoints) {
        if (wpt.elevation != null) {
          if (highest == null || wpt.elevation! > (highest.elevation ?? 0)) {
            highest = wpt;
          }
        }
      }
      if (highest != null) {
        return LatLng(highest.latitude, highest.longitude);
      }
    }
    return fallback;
  }

  /// Menghitung total jarak yang telah ditempuh (km) dari daftar koordinat rekam jejak langkah
  static double calculatePathDistanceKm(List<LatLng> path) {
    if (path.length < 2) return 0.0;
    double totalMeters = 0.0;
    for (int i = 0; i < path.length - 1; i++) {
      totalMeters += Geolocator.distanceBetween(
        path[i].latitude,
        path[i].longitude,
        path[i + 1].latitude,
        path[i + 1].longitude,
      );
    }
    return totalMeters / 1000.0;
  }
}

