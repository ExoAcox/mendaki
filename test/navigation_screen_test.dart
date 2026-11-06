import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';
import 'package:mendaki/models/waypoint.dart';
import 'package:mendaki/screens/navigation_screen.dart';
import 'package:mendaki/widgets/navigation/navigation_markers.dart';

void main() {
  const testRoute = HikingRoute(
    id: 'merbabu_selo',
    name: 'Selo',
    basecampName: 'Basecamp Selo',
    distanceKm: 6.0,
    estimatedDuration: '5-7 Jam',
    elevationGainMeters: 1856,
    difficulty: 'Sedang',
    hasWater: true,
  );

  const testMountain = Mountain(
    id: 'merbabu',
    name: 'Gunung Merbabu',
    elevation: 3145,
    location: 'Boyolali & Magelang',
    province: 'Jawa Tengah',
    difficulty: 'Sedang',
    estimatedTime: '2D1N',
    latitude: -7.4542,
    longitude: 110.4397,
    routes: [testRoute],
  );

  group('NavigationScreen Map & Floating Message Tests', () {
    testWidgets(
      'Renders map directly and shows floating message when user is far from mountain',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: NavigationScreen(
              mountain: testMountain,
              selectedRoute: testRoute,
              mockDistanceKm: 42.5,
            ),
          ),
        );

        // Verify map is rendered immediately with floating controls
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
        expect(find.byType(CompassNeedle), findsOneWidget);
        expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

        // Verify floating message shows warning when far from mountain
        expect(find.textContaining('Lokasi Anda terlalu jauh'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

        // Verify old blocking gatekeeper screens are NOT rendered
        expect(find.text('Verifikasi Area Pendakian'), findsNothing);
        expect(find.text('DI LUAR AREA PENDAKIAN'), findsNothing);
        expect(find.text('Coba Cek Ulang GPS'), findsNothing);
      },
    );

    testWidgets(
      'Renders clean map without floating message when user is near mountain',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: NavigationScreen(
              mountain: testMountain,
              selectedRoute: testRoute,
              mockDistanceKm: 2.0,
            ),
          ),
        );

        // Verify map is rendered
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
        expect(find.byType(CompassNeedle), findsOneWidget);
        expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

        // Verify NO far-distance floating message
        expect(find.textContaining('Lokasi Anda terlalu jauh'), findsNothing);
      },
    );

    testWidgets(
      'Renders NavigationCampMarkerWidget and TentIcon for waypoint with camp comment',
      (tester) async {
        const campWaypoint = Waypoint(
          name: 'POS 3',
          latitude: -7.4540,
          longitude: 110.4390,
          comment: 'camp',
        );

        expect(campWaypoint.isCamp, isTrue);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: NavigationCampMarkerWidget(
                waypoint: campWaypoint,
              ),
            ),
          ),
        );

        expect(find.text('POS 3'), findsOneWidget);
        expect(find.byType(TentIcon), findsOneWidget);
      },
    );

    testWidgets(
      'NavigationCampMarkerWidget with showLabel: false renders only icon without label',
      (tester) async {
        const campWaypoint = Waypoint(
          name: 'POS 3',
          latitude: -7.4540,
          longitude: 110.4390,
          comment: 'camp',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: NavigationCampMarkerWidget(
                waypoint: campWaypoint,
                showLabel: false,
              ),
            ),
          ),
        );

        // No label displayed, only the tent icon
        expect(find.text('POS 3'), findsNothing);
        expect(find.byType(TentIcon), findsOneWidget);
      },
    );
  });
}
