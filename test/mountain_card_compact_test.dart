import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/widgets/home/mountain_card_compact.dart';

void main() {
  const testMountain = Mountain(
    id: 'merbabu',
    name: 'Gunung Merbabu',
    elevation: 3145,
    location: 'Boyolali & Magelang',
    province: 'Jawa Tengah',
    difficulty: 3,
    estimatedTime: '6-8 Jam',
  );

  group('MountainCardCompact Tests', () {
    testWidgets('Renders compact mode card with chevron when GPX is ready', (
      tester,
    ) async {
      bool detailTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MountainCardCompact(
              mountain: testMountain.copyWith(isGpxReady: true),
              onDetailTap: () async {
                detailTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Gunung Merbabu'), findsOneWidget);
      expect(find.text('3145 mdpl'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.text('Gunung Merbabu'));
      await tester.pump();
      expect(detailTapped, isTrue);
    });

    testWidgets('Renders download icon button when GPX is not ready', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MountainCardCompact(
              mountain: testMountain.copyWith(isGpxReady: false),
              onDetailTap: () async {},
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets(
      'Renders delete icon button with background when onDeleteTap is provided',
      (tester) async {
        bool deleteTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MountainCardCompact(
                mountain: testMountain.copyWith(isGpxReady: true),
                onDetailTap: () async {},
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
  });
}

