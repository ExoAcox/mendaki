import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/services/mountain_sort_service.dart';
import 'package:mendaki/widgets/home/mountain_sort_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MountainSortButton & Simple Modal Widget Tests', () {
    testWidgets('renders sort button and opens simple modal on tap with all options',
        (WidgetTester tester) async {
      MountainSortOption selectedSort = MountainSortOption.elevationDesc;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MountainSortButton(
                  currentSort: selectedSort,
                  onSortChanged: (newSort) {
                    setState(() {
                      selectedSort = newSort;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify sort button exists
      expect(find.byKey(const Key('mountain_sort_button')), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);

      // Tap sort button to open modal
      await tester.tap(find.byKey(const Key('mountain_sort_button')));
      await tester.pumpAndSettle();

      // Verify modal content
      expect(find.text('Urutkan'), findsOneWidget);
      expect(find.text('Elevasi Tertinggi'), findsOneWidget);
      expect(find.text('Elevasi Terendah'), findsOneWidget);
      expect(find.text('Nama Gunung (A - Z)'), findsOneWidget);
      expect(find.text('Nama Gunung (Z - A)'), findsOneWidget);
      expect(find.text('Estimasi Waktu Tercepat'), findsOneWidget);
      expect(find.text('Estimasi Waktu Terlama'), findsOneWidget);

      // Verify keys
      expect(find.byKey(const Key('sort_option_alphabeticalAsc')), findsOneWidget);
      expect(find.byKey(const Key('sort_option_alphabeticalDesc')), findsOneWidget);
      expect(find.byKey(const Key('sort_option_elevationDesc')), findsOneWidget);
      expect(find.byKey(const Key('sort_option_elevationAsc')), findsOneWidget);
      expect(find.byKey(const Key('sort_option_timeAsc')), findsOneWidget);
      expect(find.byKey(const Key('sort_option_timeDesc')), findsOneWidget);

      // Select Nama Gunung (A - Z)
      await tester.tap(find.byKey(const Key('sort_option_alphabeticalAsc')));
      await tester.pumpAndSettle();

      // Modal should be closed and selected sort updated
      expect(selectedSort, MountainSortOption.alphabeticalAsc);

      // Open modal again to verify reset button appears for non-default sort
      await tester.tap(find.byKey(const Key('mountain_sort_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sort_reset_button')), findsOneWidget);

      // Tap Reset button
      await tester.tap(find.byKey(const Key('sort_reset_button')));
      await tester.pumpAndSettle();

      // Reset should restore default sort (elevationDesc)
      expect(selectedSort, MountainSortOption.elevationDesc);
    });
  });
}
