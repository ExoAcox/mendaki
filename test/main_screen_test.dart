import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/services/navigation_session_service.dart';
import 'package:mendaki/screens/home_screen.dart';
import 'package:mendaki/screens/library_screen.dart';
import 'package:mendaki/screens/main_screen.dart';
import 'package:mendaki/screens/more_screen.dart';
import 'package:mendaki/widgets/home/floating_nav_bar.dart';

void main() {
  group('MainScreen Widget Tests', () {
    setUp(() async {
      await NavigationSessionService.clearActiveSession();
    });

    tearDown(() async {
      await NavigationSessionService.clearActiveSession();
    });
    testWidgets('renders FloatingNavBar and defaults to HomeScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));

      // FloatingNavBar is present
      expect(find.byType(FloatingNavBar), findsOneWidget);

      // HomeScreen is active and visible
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Mendaki'), findsWidgets);

      await tester.pump();
    });

    testWidgets('switches to Library and More tabs correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pump();

      // Tap Library tab
      await tester.tap(find.text('Library'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(LibraryScreen), findsOneWidget);

      // Tap More tab
      await tester.tap(find.text('More'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(MoreScreen), findsOneWidget);
      expect(find.text('GitHub Repository'), findsOneWidget);

      // Tap back to Home tab
      await tester.tap(find.text('Home'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('tapping search button focuses search bar on HomeScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));
      await tester.pump();

      await tester.tap(find.byKey(const Key('nav_search_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final searchTextFieldFinder = find.byType(TextField);
      expect(searchTextFieldFinder, findsOneWidget);
      final searchTextField = tester.widget<TextField>(searchTextFieldFinder);
      expect(searchTextField.focusNode?.hasFocus, isTrue);
    });
  });
}
