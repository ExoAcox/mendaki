import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mendaki/core/services/navigation_session_service.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';
import 'package:mendaki/screens/navigation_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('nav_test_');
    NavigationSessionService.customSessionDirectoryPath = tempDir.path;
    await NavigationSessionService.clearActiveSession();
  });

  tearDown(() async {
    await NavigationSessionService.clearActiveSession();
    NavigationSessionService.customSessionDirectoryPath = null;
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('NavigationSessionService CRUD Tests', () {
    test('saveActiveSession, getActiveSession, and clearActiveSession flow', () async {
      final startTime = DateTime.now().subtract(const Duration(minutes: 15));
      final path = [
        const LatLng(-7.4542, 110.4397),
        const LatLng(-7.4530, 110.4405),
      ];

      // Initially null
      expect(await NavigationSessionService.getActiveSession(), isNull);

      // Save active session
      await NavigationSessionService.saveActiveSession(
        ActiveNavigationSession(
          mountain: testMountain,
          selectedRoute: testRoute,
          startTime: startTime,
          traveledPath: path,
        ),
      );

      // Retrieve session
      final session = await NavigationSessionService.getActiveSession();
      expect(session, isNotNull);
      expect(session!.mountain.id, equals('merbabu'));
      expect(session.selectedRoute?.id, equals('merbabu_selo'));
      expect(session.traveledPath, hasLength(2));
      expect(session.traveledPath.first.latitude, equals(-7.4542));

      // Clear session
      await NavigationSessionService.clearActiveSession();
      expect(await NavigationSessionService.getActiveSession(), isNull);
    });
  });

  group('NavigationScreen Session Persistence Tests', () {
    testWidgets('NavigationScreen restores initialStartTime and initialTraveledPath', (tester) async {
      final startTime = DateTime.now().subtract(const Duration(minutes: 25));
      final path = [
        const LatLng(-7.4542, 110.4397),
        const LatLng(-7.4530, 110.4405),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NavigationScreen(
                        mountain: testMountain,
                        selectedRoute: testRoute,
                        mockDistanceKm: 2.0,
                        initialStartTime: startTime,
                        initialTraveledPath: path,
                      ),
                    ),
                  );
                },
                child: const Text('Go Nav'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Go Nav'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify active session was saved to storage
      final session = await NavigationSessionService.getActiveSession();
      expect(session, isNotNull);
      expect(session!.mountain.id, equals('merbabu'));
      expect(session.traveledPath, hasLength(2));

      // Duration should be at least 25 minutes (e.g. 00:25:00)
      expect(find.textContaining('00:25:'), findsOneWidget);

      // Verify finish clears active session
      await tester.tap(find.byKey(const Key('finish_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Selesai
      await tester.tap(find.text('Selesai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Active session should now be cleared
      expect(await NavigationSessionService.getActiveSession(), isNull);
    });
  });
}

