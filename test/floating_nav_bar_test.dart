import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/widgets/home/floating_nav_bar.dart';

void main() {
  group('FloatingNavBar Widget Tests', () {
    testWidgets('renders all 3 menu items: Home, Library, More', (
      WidgetTester tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      // Verify labels are displayed
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Verify icons
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.collections_bookmark_outlined), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('tapping menu item triggers onTap callback', (
      WidgetTester tester,
    ) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 0,
              onTap: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Tap Library
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(tappedIndex, 1);

      // Tap More
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(tappedIndex, 2);

      // Tap Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(tappedIndex, 0);
    });

    testWidgets('updates active icon when currentIndex changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 1, // Library active
              onTap: _dummyOnTap,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.collections_bookmark_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('navbar fits content/icons and does not stretch full width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FloatingNavBar(currentIndex: 0, onTap: _dummyOnTap),
                ),
              ],
            ),
          ),
        ),
      );

      final clipRRect = tester.renderObject<RenderBox>(find.byType(ClipRRect));
      // The pill fits the icons (around 220-280px), much less than 800px screen width
      expect(clipRRect.size.width, lessThan(400.0));
      expect(clipRRect.size.width, greaterThan(150.0));
    });

    testWidgets('renders separate floating search button and handles tap', (
      WidgetTester tester,
    ) async {
      bool searchTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavBar(
              currentIndex: 0,
              onTap: _dummyOnTap,
              onSearchTap: () {
                searchTapped = true;
              },
            ),
          ),
        ),
      );

      final searchButton = find.byKey(const Key('nav_search_button'));
      expect(searchButton, findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      await tester.tap(searchButton);
      await tester.pumpAndSettle();

      expect(searchTapped, isTrue);
    });
  });
}

void _dummyOnTap(int index) {}
