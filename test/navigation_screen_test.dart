import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mendaki/core/services/navigation_session_service.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';
import 'package:mendaki/models/waypoint.dart';
import 'package:mendaki/screens/navigation_screen.dart';
import 'package:mendaki/widgets/map/map_marker.dart';
import 'package:mendaki/widgets/navigation/navigation_map_viewport.dart';

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
    tearDown(() async {
      await NavigationSessionService.clearActiveSession();
    });
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
      'buildWaypointMapMarker for camp and summit does not display label by default and displays when isSelected is true',
      (tester) async {
        const summitWpt = Waypoint(
          name: 'Puncak Sejati',
          latitude: -7.3842,
          longitude: 110.0700,
          type: 'summit',
        );
        const campWpt = Waypoint(
          name: 'Camp Plalangan',
          latitude: -7.3772,
          longitude: 110.0504,
          type: 'camp',
        );

        // 1. Default (unselected): labels should NOT show
        final defaultSummitMarker = buildWaypointMapMarker(
          waypoint: summitWpt,
          isSelected: false,
          isSummit: true,
          isBasecamp: false,
          isCamp: false,
        );
        final defaultCampMarker = buildWaypointMapMarker(
          waypoint: campWpt,
          isSelected: false,
          isSummit: false,
          isBasecamp: false,
          isCamp: true,
        );

        expect(defaultSummitMarker.width, 28.0);
        expect(defaultCampMarker.width, 28.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  defaultSummitMarker.child,
                  defaultCampMarker.child,
                ],
              ),
            ),
          ),
        );

        expect(find.text('Sejati'), findsNothing);
        expect(find.text('Puncak Sejati'), findsNothing);
        expect(find.text('Camp Plalangan'), findsNothing);

        // 2. Selected: labels SHOULD show
        final selectedSummitMarker = buildWaypointMapMarker(
          waypoint: summitWpt,
          isSelected: true,
          isSummit: true,
          isBasecamp: false,
          isCamp: false,
        );
        final selectedCampMarker = buildWaypointMapMarker(
          waypoint: campWpt,
          isSelected: true,
          isSummit: false,
          isBasecamp: false,
          isCamp: true,
        );

        expect(selectedSummitMarker.width, 280.0);
        expect(selectedCampMarker.width, 280.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  selectedSummitMarker.child,
                  selectedCampMarker.child,
                ],
              ),
            ),
          ),
        );

        expect(find.text('Puncak Sejati'), findsOneWidget);
        expect(find.text('Camp Plalangan'), findsOneWidget);
      },
    );

    testWidgets(
      'buildWaypointMapMarker for basecamp always displays label and cannot be hidden even when isSelected is true',
      (tester) async {
        const basecampWpt = Waypoint(
          name: 'BASECAMP GARUNG',
          latitude: -7.3533,
          longitude: 110.0315,
          type: 'basecamp',
        );

        // 1. Unselected: label MUST appear
        final defaultBcMarker = buildWaypointMapMarker(
          waypoint: basecampWpt,
          isSelected: false,
          isSummit: false,
          isBasecamp: true,
          isCamp: false,
        );
        expect(defaultBcMarker.width, 280.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: defaultBcMarker.child,
            ),
          ),
        );
        expect(find.text('BC GARUNG'), findsOneWidget);

        // 2. Selected (clicked): label MUST STILL appear (cannot be hidden)
        final selectedBcMarker = buildWaypointMapMarker(
          waypoint: basecampWpt,
          isSelected: true,
          isSummit: false,
          isBasecamp: true,
          isCamp: false,
        );
        expect(selectedBcMarker.width, 280.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: selectedBcMarker.child,
            ),
          ),
        );
        expect(find.text('BC GARUNG'), findsOneWidget);
      },
    );

    testWidgets(
      'buildWaypointMapMarker for danger displays skull or x icon with black pin, hide label by default and show on select',
      (tester) async {
        const dangerWpt = Waypoint(
          name: 'Jurang Terjal',
          latitude: -7.3600,
          longitude: 110.0400,
          comment: 'danger',
        );

        expect(dangerWpt.isDanger, isTrue);

        // 1. Default (unselected): compact size 16x16 like regular marker, label does NOT show
        final defaultDangerMarker = buildWaypointMapMarker(
          waypoint: dangerWpt,
          isSelected: false,
          isSummit: false,
          isBasecamp: false,
          isCamp: false,
          isDanger: true,
        );
        expect(defaultDangerMarker.width, 28.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: defaultDangerMarker.child,
            ),
          ),
        );
        expect(find.text('Jurang Terjal'), findsNothing);
        expect(find.byType(SkullIcon), findsOneWidget);

        // 2. Selected (clicked): expands to 24x24 pin with SkullIcon and label
        final selectedDangerMarker = buildWaypointMapMarker(
          waypoint: dangerWpt,
          isSelected: true,
          isSummit: false,
          isBasecamp: false,
          isCamp: false,
          isDanger: true,
        );
        expect(selectedDangerMarker.width, 280.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: selectedDangerMarker.child,
            ),
          ),
        );
        expect(find.text('Jurang Terjal'), findsOneWidget);
        expect(find.byType(SkullIcon), findsOneWidget);

        // 3. Optional X icon mode when selected
        final xDangerMarker = buildWaypointMapMarker(
          waypoint: dangerWpt,
          isSelected: true,
          isSummit: false,
          isBasecamp: false,
          isCamp: false,
          isDanger: true,
          useSkull: false,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: xDangerMarker.child,
            ),
          ),
        );
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping anywhere on map closes active selected waypoint label',
      (tester) async {
        Waypoint? selectedWpt;
        const testWpt = Waypoint(
          name: 'Puncak Merbabu',
          latitude: -7.4542,
          longitude: 110.4397,
          comment: 'summit',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Stack(
                    children: [
                      NavigationMapViewport(
                        mapController: MapController(),
                        initialCenter: const LatLng(-7.4542, 110.4397),
                        mountainId: 'merbabu',
                        polylines: const [],
                        markers: [
                          buildWaypointMapMarker(
                            waypoint: testWpt,
                            isSelected: selectedWpt == testWpt,
                            isSummit: true,
                            isBasecamp: false,
                            isCamp: false,
                            onTap: () {
                              setState(() {
                                selectedWpt = testWpt;
                              });
                            },
                          ),
                        ],
                        onTap: (tapPosition, point) {
                          if (selectedWpt != null) {
                            setState(() {
                              selectedWpt = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        // 1. Initial state: label is not shown
        expect(find.text('Puncak Merbabu'), findsNothing);

        // 2. Tap on the marker: label appears
        await tester.tap(find.byType(NavigationSummitMarkerWidget));
        await tester.pump();
        expect(find.text('Puncak Merbabu'), findsOneWidget);

        // 3. Click sembarang on the map: label closes
        await tester.tapAt(const Offset(20, 20));
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.text('Puncak Merbabu'), findsNothing);
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
