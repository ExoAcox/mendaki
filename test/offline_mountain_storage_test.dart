import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';
import 'package:mendaki/models/waypoint.dart';
import 'package:mendaki/widgets/home/home_app_bar.dart';

void main() {
  const testRoute = HikingRoute(
    id: 'prau-patakbanteng',
    name: 'Patakbanteng',
    basecampName: 'Basecamp Patakbanteng',
    distanceKm: 4.0,
    estimatedDuration: '2 - 3 Jam',
    elevationGainMeters: 2090,
    difficulty: 'Mudah',
    hasWater: true,
    city: 'Wonosobo',
    waypoints: [
      Waypoint(
        name: 'POS 1',
        latitude: -7.2096,
        longitude: 109.9293,
        type: 'pos',
      ),
      Waypoint(
        name: 'Sunrise Camp',
        latitude: -7.2015,
        longitude: 109.9354,
        type: 'camp',
        comment: 'camp',
      ),
    ],
  );

  const testMountain = Mountain(
    id: 'prau',
    name: 'Gunung Prau',
    elevation: 2590,
    location: 'Dataran Tinggi Dieng',
    province: 'Jawa Tengah',
    difficulty: 'Mudah',
    estimatedTime: '3 - 5 Jam',
    latitude: -7.197283,
    longitude: 109.932226,
    cities: ['Wonosobo', 'Batang'],
    routes: [testRoute],
  );

  group('Offline Mountain & Route Serialization Tests', () {
    test('Mountain and HikingRoute serialize and deserialize cleanly', () {
      final json = testMountain.toJson();
      expect(json['id'], 'prau');
      expect(json['name'], 'Gunung Prau');
      expect(json['routes'], isNotEmpty);

      final decoded = Mountain.fromJson(json);
      expect(decoded.id, 'prau');
      expect(decoded.name, 'Gunung Prau');
      expect(decoded.routes.length, 1);

      final decodedRoute = decoded.routes.first;
      expect(decodedRoute.id, 'prau-patakbanteng');
      expect(decodedRoute.name, 'Patakbanteng');
      expect(decodedRoute.hasWater, isTrue);
      expect(decodedRoute.waypoints.length, 2);
      expect(decodedRoute.waypoints.last.isCamp, isTrue);
    });

    test('Mountain.routes automatically sorts routes matching rawRoutes array order from API', () {
      const routeA = HikingRoute(
        id: 'prau-patakbanteng',
        name: 'Patakbanteng',
        basecampName: 'BC Patakbanteng',
        distanceKm: 4.0,
        estimatedDuration: '2-3 Jam',
        elevationGainMeters: 2090,
        difficulty: 'Mudah',
      );
      const routeB = HikingRoute(
        id: 'prau-dieng',
        name: 'Dieng',
        basecampName: 'BC Dieng',
        distanceKm: 4.0,
        estimatedDuration: '3-4 Jam',
        elevationGainMeters: 2128,
        difficulty: 'Mudah',
      );
      const routeC = HikingRoute(
        id: 'prau-wates',
        name: 'Wates',
        basecampName: 'BC Wates',
        distanceKm: 5.0,
        estimatedDuration: '3-4 Jam',
        elevationGainMeters: 1850,
        difficulty: 'Mudah',
      );

      // Sediakan routes dalam urutan terbalik: C, B, A
      // Namun rawRoutes (dari API) adalah: A, B, C
      const mountain = Mountain(
        id: 'prau',
        name: 'Gunung Prau',
        elevation: 2590,
        location: 'Dieng',
        province: 'Jawa Tengah',
        difficulty: 'Mudah',
        estimatedTime: '3-5 Jam',
        routes: [routeC, routeB, routeA],
        rawRoutes: ['prau-patakbanteng', 'prau-dieng', 'prau-wates'],
      );

      // Verify mountain.routes is sorted: A, B, C
      expect(mountain.routes.map((r) => r.id).toList(), [
        'prau-patakbanteng',
        'prau-dieng',
        'prau-wates',
      ]);
    });

    testWidgets('HomeAppBar renders downloaded icon and count badge', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: HomeAppBar(
              isShowingDownloaded: true,
              downloadedCount: 3,
              onDownloadedTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Verify offline icon is present
      expect(find.byIcon(Icons.offline_pin_rounded), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });
  });
}

