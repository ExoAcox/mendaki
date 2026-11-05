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

  group('NavigationScreen Gatekeeper & UI Tests', () {
    testWidgets(
      'Displays dedicated Far From Mountain screen when user is > 15 km away',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: NavigationScreen(
              mountain: testMountain,
              selectedRoute: testRoute,
              initialGpsStatus: NavigationGpsStatus.farFromMountain,
              mockDistanceKm: 42.5,
            ),
          ),
        );

        // Verify far from mountain screen elements
        expect(find.text('Verifikasi Area Pendakian'), findsOneWidget);
        expect(find.text('DI LUAR AREA PENDAKIAN'), findsOneWidget);
        expect(find.text('Lokasi Terlalu Jauh dari Gunung'), findsOneWidget);
        expect(
          find.textContaining('radius maksimal 15 km'),
          findsOneWidget,
        );
        expect(find.text('42.5 km'), findsOneWidget);
        expect(find.text('Maksimal 15.0 km'), findsOneWidget);

        // Verify retry and back buttons
        expect(find.text('Coba Cek Ulang GPS'), findsOneWidget);
        expect(find.text('Kembali ke Detail Gunung'), findsOneWidget);

        // Verify map is NOT loaded
        expect(find.text('Navigasi GPS'), findsNothing);
        expect(find.text('WAKTU BERJALAN'), findsNothing);
      },
    );

    testWidgets('Displays GPS Disabled screen with retry & back buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NavigationScreen(
            mountain: testMountain,
            selectedRoute: testRoute,
            initialGpsStatus: NavigationGpsStatus.gpsDisabled,
          ),
        ),
      );

      expect(find.text('GPS DINONAKTIFKAN'), findsOneWidget);
      expect(find.text('Aktifkan GPS Perangkat'), findsOneWidget);
      expect(find.text('Buka Pengaturan & Cek Ulang'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
    });

    testWidgets('Displays Permission Denied screen with request & back buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NavigationScreen(
            mountain: testMountain,
            selectedRoute: testRoute,
            initialGpsStatus: NavigationGpsStatus.permissionDenied,
          ),
        ),
      );

      expect(find.text('IZIN DIPERLUKAN'), findsOneWidget);
      expect(find.text('Izinkan Akses Lokasi'), findsOneWidget);
      expect(find.text('Beri Izin Lokasi & Cek Ulang'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
    });

    testWidgets(
      'Displays Offline Required screen when GPX or maps are not downloaded',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: NavigationScreen(
              mountain: testMountain,
              selectedRoute: testRoute,
              initialGpsStatus: NavigationGpsStatus.offlineRequired,
            ),
          ),
        );

        expect(find.text('Paket Navigasi Offline'), findsOneWidget);
        expect(find.text('DOWNLOAD OFFLINE DIPERLUKAN'), findsOneWidget);
        expect(find.text('Unduh GPX & Peta Offline'), findsOneWidget);
        expect(find.text('File Rute GPX'), findsOneWidget);
        expect(find.text('Paket Peta Offline'), findsOneWidget);
        expect(find.text('Unduh Paket Offline Sekarang'), findsOneWidget);
        expect(find.text('Kembali ke Detail Gunung'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders clean map without other UI when GPS status is ready',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: NavigationScreen(
              mountain: testMountain,
              selectedRoute: testRoute,
              bypassGpsCheckForTesting: true,
            ),
          ),
        );

        // Verify clean map is rendered with floating buttons
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
        expect(find.byType(CompassNeedle), findsOneWidget);
        expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

        // Verify other UIs are NOT present (clean map only)
        expect(find.text('Navigasi GPS'), findsNothing);
        expect(find.text('WAKTU BERJALAN'), findsNothing);
        expect(find.text('JARAK RUTE'), findsNothing);
        expect(find.text('ESTIMASI WAKTU'), findsNothing);
        expect(find.text('KETINGGIAN PUNCAK'), findsNothing);
        expect(find.text('Jeda Lacak'), findsNothing);
        expect(find.text('OFFLINE SIAP'), findsNothing);
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
