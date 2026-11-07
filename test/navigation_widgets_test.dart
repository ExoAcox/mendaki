import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';
import 'package:mendaki/widgets/navigation/navigation_finish_dialog.dart';
import 'package:mendaki/widgets/navigation/navigation_far_notice.dart';
import 'package:mendaki/widgets/navigation/navigation_finish_button.dart';
import 'package:mendaki/widgets/navigation/navigation_floating_button.dart';
import 'package:mendaki/widgets/navigation/navigation_floating_controls.dart';
import 'package:mendaki/widgets/navigation/navigation_markers.dart';
import 'package:mendaki/widgets/navigation/navigation_top_bar.dart';

void main() {
  group('Navigation Modular Widgets Tests', () {
    testWidgets('NavigationFloatingButton renders and fires onTap', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationFloatingButton(
              icon: Icons.arrow_back_rounded,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      await tester.tap(find.byType(NavigationFloatingButton));
      expect(tapped, isTrue);
    });

    testWidgets('NavigationFarNotice renders correct distance text', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: NavigationFarNotice(distanceKm: 42.5)),
        ),
      );

      expect(find.text('Lokasi Anda terlalu jauh (42.5 km)'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets(
      'NavigationFarNotice formats >= 100 km cleanly without decimals',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: NavigationFarNotice(distanceKm: 150.8)),
          ),
        );

        expect(find.text('Lokasi Anda terlalu jauh (151 km)'), findsOneWidget);
      },
    );

    testWidgets(
      'NavigationFloatingControls renders CompassNeedle and Find Me button',
      (tester) async {
        bool compassTapped = false;
        bool findMeTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NavigationFloatingControls(
                currentRotation: 45.0,
                onCompassTap: () {
                  compassTapped = true;
                },
                onFindMeTap: () {
                  findMeTapped = true;
                },
              ),
            ),
          ),
        );

        expect(find.byType(CompassNeedle), findsOneWidget);
        expect(find.text('N'), findsOneWidget);
        expect(find.text('S'), findsOneWidget);
        expect(find.text('W'), findsOneWidget);
        expect(find.text('E'), findsOneWidget);
        expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

        await tester.tap(find.byType(NavigationFloatingButton).at(0));
        expect(compassTapped, isTrue);

        await tester.tap(find.byIcon(Icons.my_location_rounded));
        expect(findMeTapped, isTrue);
      },
    );

    testWidgets('NavigationFinishButton renders and fires onTap', (
      tester,
    ) async {
      bool finishTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationFinishButton(
              onTap: () {
                finishTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Finish'), findsOneWidget);
      expect(find.byIcon(Icons.flag_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('finish_button')));
      expect(finishTapped, isTrue);
    });

    testWidgets(
      'NavigationMetricsChip renders Elapsed Duration, Altitude, and Distance walked',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: NavigationMetricsChip(
                elapsedDuration: Duration(hours: 1, minutes: 23, seconds: 45),
                altitude: 2150.4,
                distanceKm: 2.45,
              ),
            ),
          ),
        );

        expect(find.text('01:23:45'), findsOneWidget);
        expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
        expect(find.text('2150 mdpl'), findsOneWidget);
        expect(find.byIcon(Icons.landscape_rounded), findsOneWidget);
        expect(find.text('2.5 km'), findsOneWidget);
        expect(find.byIcon(Icons.directions_walk_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'NavigationTopBar renders formatted elapsed duration and fires finish callback',
      (tester) async {
        bool finishTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NavigationTopBar(
                elapsedDuration: const Duration(
                  hours: 1,
                  minutes: 23,
                  seconds: 45,
                ),
                altitude: 2150.4,
                onFinishTap: () {
                  finishTapped = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('01:23:45'), findsOneWidget);
        expect(find.text('2150 mdpl'), findsOneWidget);
        expect(find.byIcon(Icons.landscape_rounded), findsOneWidget);
        expect(find.text('Finish'), findsOneWidget);
        expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
        expect(find.byIcon(Icons.flag_rounded), findsOneWidget);

        await tester.tap(find.byKey(const Key('finish_button')));
        expect(finishTapped, isTrue);
      },
    );

    testWidgets('FinishHikeDialog displays confirmation details and actions', (
      tester,
    ) async {
      bool finishConfirmed = false;

      const testMountain = Mountain(
        id: 'merbabu',
        name: 'Gunung Merbabu',
        elevation: 3145,
        location: 'Boyolali',
        province: 'Jawa Tengah',
        difficulty: 'Sedang',
        estimatedTime: '2D1N',
      );

      const testRoute = HikingRoute(
        id: 'merbabu_selo',
        name: 'Selo',
        basecampName: 'Basecamp Selo',
        distanceKm: 6.2,
        estimatedDuration: '6 Jam',
        elevationGainMeters: 1800,
        difficulty: 'Sedang',
        hasWater: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FinishHikeDialog(
              mountain: testMountain,
              route: testRoute,
              elapsed: const Duration(hours: 2, minutes: 15, seconds: 30),
              onFinish: () {
                finishConfirmed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Selesaikan Navigasi?'), findsOneWidget);
      expect(find.textContaining('Gunung Merbabu'), findsOneWidget);
      expect(find.text('WAKTU DILALUI'), findsOneWidget);
      expect(find.text('02:15:30'), findsOneWidget);
      expect(find.text('JARAK DITEMPUH'), findsOneWidget);
      expect(find.text('6.2 km'), findsOneWidget);

      await tester.tap(find.text('Selesai'));
      expect(finishConfirmed, isTrue);
    });

    testWidgets('NavigationFinishDialog formats distance < 1 km as meters like floating controls', (
      tester,
    ) async {
      const testMountain = Mountain(
        id: 'merbabu',
        name: 'Gunung Merbabu',
        elevation: 3145,
        location: 'Boyolali',
        province: 'Jawa Tengah',
        difficulty: 'Sedang',
        estimatedTime: '2D1N',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NavigationFinishDialog(
              mountain: testMountain,
              elapsed: const Duration(minutes: 10),
              distanceTraveledKm: 0.45,
              onFinish: () {},
            ),
          ),
        ),
      );

      expect(find.text('JARAK DITEMPUH'), findsOneWidget);
      expect(find.text('450 m'), findsOneWidget);
    });
  });
}
