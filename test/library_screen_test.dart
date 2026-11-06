import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/screens/library_screen.dart';
import 'package:mendaki/widgets/home/home_search_bar.dart';

void main() {
  group('LibraryScreen UI Tests', () {
    testWidgets(
      'LibraryScreen renders App Bar with title Library, back button, search bar, and offline text',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: LibraryScreen(),
          ),
        );

        // Verify App Bar with title 'Library' and back button
        expect(find.text('Library'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

        // Verify search bar without province filter
        expect(find.byType(HomeSearchBar), findsOneWidget);
        expect(find.text('Semua'), findsNothing);
        expect(find.text('Jawa Tengah'), findsNothing);

        // Verify offline description text
        expect(
          find.textContaining('tersimpan offline di perangkat'),
          findsOneWidget,
        );

        // Allow initial build
        await tester.pump();
      },
    );
  });
}
