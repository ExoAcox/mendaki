import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/services/network_service.dart';
import 'package:mendaki/screens/home_screen.dart';
import 'package:mendaki/widgets/home/home_search_bar.dart';

void main() {
  group('HomeScreen Search Filter Reset Tests', () {
    tearDown(() {
      NetworkService.mockIsOnline = null;
    });

    testWidgets(
      'submitting search resets province filter and category to default',
      (WidgetTester tester) async {
        NetworkService.mockIsOnline = false;

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // 1. Pilih filter provinsi 'Jawa Tengah'
        expect(find.text('Jawa Tengah'), findsOneWidget);
        await tester.tap(find.text('Jawa Tengah'));
        await tester.pumpAndSettle();

        // Verifikasi bahwa Jawa Tengah terpilih
        final homeState = tester.state<HomeScreenState>(find.byType(HomeScreen));
        expect(homeState.selectedFilter, equals('Jawa Tengah'));

        // 2. Pilih kategori '7 Summit Indonesia'
        final categoryButtonFinder = find.byKey(
          const Key('mountain_category_button'),
        );
        await tester.tap(categoryButtonFinder);
        await tester.pumpAndSettle();

        await tester.tap(find.text('7 Summit Indonesia'));
        await tester.pumpAndSettle();

        expect(homeState.selectedCategory, equals('7 Summit Indonesia'));

        // 3. Ketik di search bar lalu submit / tekan Enter
        final searchField = find.descendant(
          of: find.byType(HomeSearchBar),
          matching: find.byType(TextField),
        );
        expect(searchField, findsOneWidget);

        await tester.enterText(searchField, 'Merapi');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // 4. Verifikasi filter provinsi dan kategori telah di-reset
        expect(homeState.selectedFilter, equals('Semua'));
        expect(homeState.selectedCategory, isNull);

        // Chip provinsi terlihat kembali dan 'Semua' aktif
        expect(find.text('Semua'), findsOneWidget);
        expect(find.text('Jawa Tengah'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping province filter resets search input',
      (WidgetTester tester) async {
        NetworkService.mockIsOnline = false;

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final homeState = tester.state<HomeScreenState>(find.byType(HomeScreen));
        final searchField = find.descendant(
          of: find.byType(HomeSearchBar),
          matching: find.byType(TextField),
        );

        // Isi search bar dengan teks
        await tester.enterText(searchField, 'Slamet');
        await tester.pump();
        expect(homeState.searchController.text, equals('Slamet'));

        // Tap filter provinsi 'Jawa Barat'
        await tester.tap(find.text('Jawa Barat'));
        await tester.pumpAndSettle();

        // Verifikasi search input otomatis ter-reset
        expect(homeState.searchController.text, isEmpty);
        expect(homeState.selectedFilter, equals('Jawa Barat'));
      },
    );

    testWidgets(
      'selecting category resets search input',
      (WidgetTester tester) async {
        NetworkService.mockIsOnline = false;

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final homeState = tester.state<HomeScreenState>(find.byType(HomeScreen));
        final searchField = find.descendant(
          of: find.byType(HomeSearchBar),
          matching: find.byType(TextField),
        );

        // Isi search bar dengan teks
        await tester.enterText(searchField, 'Rinjani');
        await tester.pump();
        expect(homeState.searchController.text, equals('Rinjani'));

        // Buka modal kategori dan pilih '7 Summit Indonesia'
        final categoryButtonFinder = find.byKey(
          const Key('mountain_category_button'),
        );
        await tester.tap(categoryButtonFinder);
        await tester.pumpAndSettle();

        await tester.tap(find.text('7 Summit Indonesia'));
        await tester.pumpAndSettle();

        // Verifikasi search input otomatis ter-reset
        expect(homeState.searchController.text, isEmpty);
        expect(homeState.selectedCategory, equals('7 Summit Indonesia'));
      },
    );
  });
}
