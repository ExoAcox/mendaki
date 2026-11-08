import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mendaki/core/services/gpx_parser_service.dart';
import 'package:mendaki/models/waypoint.dart';
import 'package:mendaki/widgets/navigation/navigation_geo_utils.dart';

void main() {
  group('NavigationGeoUtils Tests', () {
    test('calculateBearing returns correct angle', () {
      const from = LatLng(0, 0);
      const north = LatLng(1, 0);
      const east = LatLng(0, 1);

      expect(NavigationGeoUtils.calculateBearing(from, north), closeTo(0.0, 0.5));
      expect(NavigationGeoUtils.calculateBearing(from, east), closeTo(90.0, 0.5));
    });

    test('calculateSummitUpRotation rotates summit to facing upwards', () {
      const current = LatLng(0, 0);
      const summitNorth = LatLng(1, 0); // Bearing 0 -> rotation 0
      const summitEast = LatLng(0, 1);  // Bearing 90 -> rotation 270

      expect(
        NavigationGeoUtils.calculateSummitUpRotation(current, summitNorth),
        closeTo(0.0, 0.5),
      );
      expect(
        NavigationGeoUtils.calculateSummitUpRotation(current, summitEast),
        closeTo(270.0, 0.5),
      );
    });

    test('findSummitCoordinate finds summit waypoint or highest elevation', () {
      const fallback = LatLng(-7.0, 110.0);
      final gpx = GpxData(
        name: 'Test',
        waypoints: const [
          Waypoint(
            name: 'Pos 1',
            latitude: -7.1,
            longitude: 110.1,
            elevation: 1500,
          ),
          Waypoint(
            name: 'Puncak',
            latitude: -7.5,
            longitude: 110.5,
            elevation: 3000,
            comment: 'summit',
          ),
        ],
        tracks: const [],
        totalDistanceKm: 5,
        minElevation: 1500,
        maxElevation: 3000,
        totalElevationGain: 1500,
      );

      final summit = NavigationGeoUtils.findSummitCoordinate(gpx, fallback);
      expect(summit.latitude, equals(-7.5));
      expect(summit.longitude, equals(110.5));
    });

    test('calculatePathDistanceKm sums distances between points accurately', () {
      expect(NavigationGeoUtils.calculatePathDistanceKm([]), equals(0.0));
      expect(
        NavigationGeoUtils.calculatePathDistanceKm([const LatLng(0, 0)]),
        equals(0.0),
      );

      // ~111 km per degree latitude
      final path = [
        const LatLng(0, 0),
        const LatLng(1, 0),
      ];
      final dist = NavigationGeoUtils.calculatePathDistanceKm(path);
      expect(dist, closeTo(111.0, 1.0));
    });
  });
}

