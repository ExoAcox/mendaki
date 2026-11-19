import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/screens/more_screen.dart';

void main() {
  group('MoreScreen Widget Tests', () {
    testWidgets('renders empty placeholder page with More title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MoreScreen(),
        ),
      );

      // Verify title and placeholder elements
      expect(find.text('More'), findsWidgets);
      expect(find.text('Halaman dalam pengembangan'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    });
  });
}

