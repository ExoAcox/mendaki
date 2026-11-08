import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';
import 'package:mendaki/models/waypoint.dart';
import 'package:mendaki/screens/navigation_screen.dart';
import 'package:mendaki/widgets/map/map_marker.dart';

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

        // Verify back button is removed, and time info & finish button are rendered
        expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
        expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
        expect(find.text('00:00:00'), findsOneWidget);
        expect(find.text('Finish'), findsOneWidget);
        expect(find.byKey(const Key('finish_button')), findsOneWidget);
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

        // Verify back button is removed, and time info & finish button are rendered
        expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
        expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
        expect(find.text('00:00:00'), findsOneWidget);
        expect(find.text('Finish'), findsOneWidget);
        expect(find.byKey(const Key('finish_button')), findsOneWidget);
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
              body: NavigationCampMarkerWidget(waypoint: campWaypoint),
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

    testWidgets(
      'Tapping finish button displays confirmation dialog, Batal keeps on page, Selesai pops',
      (tester) async {
        bool popped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NavigationScreen(
                          mountain: testMountain,
                          selectedRoute: testRoute,
                          mockDistanceKm: 2.0,
                        ),
                      ),
                    );
                    popped = true;
                  },
                  child: const Text('Go Nav'),
                );
              },
            ),
          ),
        );

        // Navigate to NavigationScreen
        await tester.tap(find.text('Go Nav'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(NavigationScreen), findsOneWidget);
        expect(find.byKey(const Key('finish_button')), findsOneWidget);

        // Tap Finish button -> modal konfirmasi should appear
        await tester.tap(find.byKey(const Key('finish_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Selesaikan Navigasi?'), findsOneWidget);
        expect(
          find.text(
            'Apakah Anda yakin ingin menyelesaikan sesi navigasi di Gunung Merbabu?',
          ),
          findsOneWidget,
        );
        expect(find.text('Batal'), findsOneWidget);
        expect(find.text('Selesai'), findsOneWidget);

        // Tap Batal -> Dialog should close, but user stays on NavigationScreen
        await tester.tap(find.text('Batal'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Selesaikan Navigasi?'), findsNothing);
        expect(find.byType(NavigationScreen), findsOneWidget);
        expect(popped, isFalse);

        // Tap Finish button again and confirm with Selesai
        await tester.tap(find.byKey(const Key('finish_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.tap(find.text('Selesai'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // User should now have exited NavigationScreen
        expect(find.byType(NavigationScreen), findsNothing);
        expect(popped, isTrue);
      },
    );

    testWidgets(
      'PopScope intercepts system back and triggers finish confirmation modal',
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
        await tester.pump();

        // Simulate system back button / gesture
        final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
        await widgetsAppState.didPopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verify confirmation dialog appears instead of instantly popping
        expect(find.text('Selesaikan Navigasi?'), findsOneWidget);
        expect(find.byType(NavigationScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Renders altitude meter when hardware GPS altitude is available',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: NavigationScreen(
              mountain: testMountain,
              selectedRoute: testRoute,
              mockDistanceKm: 2.0,
              mockAltitude: 2840.0,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('2840 mdpl'), findsOneWidget);
        expect(find.byIcon(Icons.landscape_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Renders trace path polyline with secondary color Color(0xFFA33D23)',
      (tester) async {
        final mockPath = [
          const LatLng(-7.4542, 110.4397),
          const LatLng(-7.4530, 110.4405),
          const LatLng(-7.4520, 110.4415),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: NavigationScreen(
              mountain: testMountain,
              selectedRoute: testRoute,
              mockDistanceKm: 2.0,
              mockTraveledPath: mockPath,
            ),
          ),
        );
        await tester.pump();

        final polylineLayerFinder = find.byType(PolylineLayer);
        expect(polylineLayerFinder, findsOneWidget);

        final PolylineLayer polylineLayer = tester.widget(polylineLayerFinder);
        final tracePolylines = polylineLayer.polylines
            .where((p) => p.color == const Color(0xFFA33D23))
            .toList();

        expect(tracePolylines, hasLength(1));
        expect(tracePolylines.first.points, equals(mockPath));
      },
    );
  });
}
