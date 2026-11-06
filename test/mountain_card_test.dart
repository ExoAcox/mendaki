import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/widgets/home/mountain_card.dart';

void main() {
  const testMountain = Mountain(
    id: 'merbabu',
    name: 'Gunung Merbabu',
    elevation: 3145,
    location: 'Boyolali & Magelang',
    province: 'Jawa Tengah',
    difficulty: 'Sedang',
    estimatedTime: '6-8 Jam',
  );

  group('MountainCard Badge Tests', () {
    testWidgets(
      'Renders both GPX Tersimpan and Peta Tersimpan badges when both ready',
      (tester) async {
        final mountain = testMountain.copyWith(
          isGpxReady: true,
          isMapReady: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MountainCard(mountain: mountain, onDetailTap: () {}),
            ),
          ),
        );

        await tester.pump();

        expect(find.text('GPX'), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
        expect(find.byIcon(Icons.offline_pin_rounded), findsOneWidget);
        expect(find.byIcon(Icons.map_rounded), findsOneWidget);
      },
    );

    testWidgets('Renders only GPX Tersimpan badge when only GPX ready', (
      tester,
    ) async {
      final mountain = testMountain.copyWith(
        isGpxReady: true,
        isMapReady: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MountainCard(mountain: mountain, onDetailTap: () {}),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('GPX'), findsOneWidget);
      expect(find.text('Map'), findsNothing);
    });

    testWidgets('Renders only Peta Tersimpan badge when only map ready', (
      tester,
    ) async {
      final mountain = testMountain.copyWith(
        isGpxReady: false,
        isMapReady: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MountainCard(mountain: mountain, onDetailTap: () {}),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('GPX'), findsNothing);
      expect(find.text('Map'), findsOneWidget);
    });

    testWidgets(
      'Does not render floating delete button when onDeleteTap is null (Home Page)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MountainCard(mountain: testMountain, onDetailTap: () {}),
            ),
          ),
        );

        await tester.pump();
        expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      },
    );

    testWidgets(
      'Renders floating delete button when onDeleteTap is provided (Library Page) and triggers callback',
      (tester) async {
        bool deleteTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MountainCard(
                mountain: testMountain,
                onDetailTap: () {},
                onDeleteTap: () {
                  deleteTapped = true;
                },
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        expect(deleteTapped, isTrue);
      },
    );
    testWidgets('Tapping detail button invokes onDetailTap callback', (
      tester,
    ) async {
      bool detailTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MountainCard(
              mountain: testMountain.copyWith(isGpxReady: true),
              onDetailTap: () async {
                detailTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Lihat Jalur Pendakian'), findsOneWidget);

      await tester.tap(find.text('Lihat Jalur Pendakian'));
      await tester.pump();

      expect(detailTapped, isTrue);
    });
  });
}
