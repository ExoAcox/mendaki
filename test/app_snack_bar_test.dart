import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/theme/app_snack_bar.dart';

void main() {
  group('AppSnackBar Liquid Glass Top Capsule Tests', () {
    testWidgets('shows success capsule at top with message and check icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppSnackBar.showSuccess(context, 'Berhasil disimpan!');
                  },
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 350)); // Animate in

      expect(find.text('Berhasil disimpan!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('shows error capsule at top with message and error icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppSnackBar.showError(context, 'Gagal mengunduh data');
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Gagal mengunduh data'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('shows info capsule at top with message and info icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppSnackBar.showInfo(context, 'Informasi lokasi');
                  },
                  child: const Text('Show Info'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Informasi lokasi'), findsOneWidget);
      expect(find.byIcon(Icons.info_rounded), findsOneWidget);
    });

    testWidgets('can be dismissed by swiping up', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppSnackBar.showInfo(context, 'Swipe me up');
                  },
                  child: const Text('Show Dismissible'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dismissible'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Swipe me up'), findsOneWidget);

      // Swipe up to dismiss
      await tester.drag(
        find.byKey(const Key('liquid_glass_capsule_dismissible')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(find.text('Swipe me up'), findsNothing);
    });
  });
}

