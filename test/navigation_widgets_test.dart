import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/widgets/navigation/navigation_far_notice.dart';
import 'package:mendaki/widgets/navigation/navigation_floating_button.dart';
import 'package:mendaki/widgets/navigation/navigation_floating_controls.dart';
import 'package:mendaki/widgets/navigation/navigation_markers.dart';

void main() {
  group('Navigation Modular Widgets Tests', () {
    testWidgets('NavigationFloatingButton renders and fires onTap', (tester) async {
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

    testWidgets('NavigationFarNotice renders correct distance text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NavigationFarNotice(distanceKm: 42.5),
          ),
        ),
      );

      expect(find.text('Lokasi Anda terlalu jauh (42.5 km)'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('NavigationFarNotice formats >= 100 km cleanly without decimals', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NavigationFarNotice(distanceKm: 150.8),
          ),
        ),
      );

      expect(find.text('Lokasi Anda terlalu jauh (151 km)'), findsOneWidget);
    });

    testWidgets('NavigationFloatingControls renders CompassNeedle and Find Me button', (tester) async {
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
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);

      await tester.tap(find.byType(NavigationFloatingButton).first);
      expect(compassTapped, isTrue);

      await tester.tap(find.byIcon(Icons.my_location_rounded));
      expect(findMeTapped, isTrue);
    });
  });
}
