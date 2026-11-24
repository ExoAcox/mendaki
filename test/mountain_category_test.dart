import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/services/network_service.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/mountain_category.dart';
import 'package:mendaki/screens/home_screen.dart';
import 'package:mendaki/widgets/home/mountain_category_button.dart';
import 'package:mendaki/widgets/home/mountain_category_modal.dart';

void main() {
  group('MountainCategory Model Tests', () {
    test('contains all 5 expected categories', () {
      final titles = MountainCategory.values.map((c) => c.title).toList();
      expect(titles, contains('7 Summits of Indonesia'));
      expect(titles, contains('7 Summits of Java'));
      expect(titles, contains('7 Summits of Central Java'));
      expect(titles, contains('7 Summits of West Java'));
      expect(titles, contains('Triple S of Central Java'));
    });

    test('fromSlugOrTitle resolves correctly', () {
      expect(
        MountainCategory.fromSlugOrTitle('7s_indonesia')?.title,
        equals('7 Summits of Indonesia'),
      );
      expect(
        MountainCategory.fromSlugOrTitle('7 Summits of Indonesia')?.slug,
        equals('7s_indonesia'),
      );
      expect(
        MountainCategory.fromSlugOrTitle('3s_jateng')?.title,
        equals('Triple S of Central Java'),
      );
      expect(
        MountainCategory.fromSlugOrTitle('Triple S of Central Java')?.slug,
        equals('3s_jateng'),
      );
      expect(MountainCategory.fromSlugOrTitle('unknown_cat'), isNull);
      expect(MountainCategory.fromSlugOrTitle(null), isNull);
    });
  });

  group('Mountain Model with Category Tests', () {
    test('fromJson and toJson handles category array correctly', () {
      final json = {
        'id': 'slamet',
        'name': 'Gunung Slamet',
        'elevation': 3428,
        'location': 'Banyumas',
        'province': 'Jawa Tengah',
        'difficulty': 'Sedang',
        'estimatedTime': '8 - 10 Jam',
        'category': ['3s_jateng', '7s_jawa', '7s_jateng'],
      };

      final mountain = Mountain.fromJson(json);
      expect(mountain.categories, equals(['3s_jateng', '7s_jawa', '7s_jateng']));
      expect(mountain.category, equals(['3s_jateng', '7s_jawa', '7s_jateng']));

      final serialized = mountain.toJson();
      expect(serialized['category'], equals(['3s_jateng', '7s_jawa', '7s_jateng']));
    });

    test('copyWith updates categories properly', () {
      const mountain = Mountain(
        id: 'sumbing',
        name: 'Gunung Sumbing',
        elevation: 3371,
        location: 'Magelang',
        province: 'Jawa Tengah',
        difficulty: 3,
        estimatedTime: '7 - 9 Jam',
        categories: ['3s_jateng'],
      );

      final updated = mountain.copyWith(categories: ['3s_jateng', '7s_jawa']);
      expect(updated.categories, equals(['3s_jateng', '7s_jawa']));
    });
  });

  group('MountainCategoryModal Widget Tests', () {
    testWidgets('renders all category options and handles selection', (
      WidgetTester tester,
    ) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    MountainCategoryModal.show(
                      context,
                      selectedCategory: null,
                      onCategorySelected: (cat) => selected = cat,
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Kategori Gunung'), findsOneWidget);
      expect(find.text('Semua Kategori'), findsOneWidget);
      expect(find.text('7 Summits of Indonesia'), findsOneWidget);
      expect(find.text('7 Summits of Java'), findsOneWidget);
      expect(find.text('7 Summits of Central Java'), findsOneWidget);
      expect(find.text('7 Summits of West Java'), findsOneWidget);
      expect(find.text('Triple S of Central Java'), findsOneWidget);

      // Tap 7 Summits of Indonesia
      await tester.tap(find.text('7 Summits of Indonesia'));
      await tester.pumpAndSettle();

      expect(selected, equals('7 Summits of Indonesia'));
    });

    testWidgets('shows reset button when category is active', (
      WidgetTester tester,
    ) async {
      String? selected = '7 Summits of Java';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    MountainCategoryModal.show(
                      context,
                      selectedCategory: selected,
                      onCategorySelected: (cat) => selected = cat,
                    );
                  },
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      final resetButton = find.byKey(const Key('category_reset_button'));
      expect(resetButton, findsOneWidget);

      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });
  });

  group('MountainCategoryButton Widget Tests', () {
    testWidgets('renders unselected state correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MountainCategoryButton(
              selectedCategory: null,
              onCategoryChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Kategori'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down_rounded), findsOneWidget);
      expect(find.byKey(const Key('clear_category_button')), findsNothing);
    });

    testWidgets('renders selected state and triggers clear on close tap', (
      WidgetTester tester,
    ) async {
      String? category = '7 Summits of Indonesia';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MountainCategoryButton(
              selectedCategory: category,
              onCategoryChanged: (newCat) => category = newCat,
            ),
          ),
        ),
      );

      expect(find.text('7 Summits of Indonesia'), findsOneWidget);
      expect(find.byKey(const Key('clear_category_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('clear_category_button')));
      await tester.pump();

      expect(category, isNull);
    });
  });

  group('HomeScreen Category Button Placement Tests', () {
    tearDown(() {
      NetworkService.mockIsOnline = null;
    });

    testWidgets('HomeScreen renders MountainCategoryButton next to filter chips', (
      WidgetTester tester,
    ) async {
      NetworkService.mockIsOnline = false;

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final categoryButtonFinder = find.byKey(const Key('mountain_category_button'));
      expect(categoryButtonFinder, findsOneWidget);

      // Filter chip provinsi terlihat saat kategori tidak aktif
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Jawa Tengah'), findsOneWidget);

      // Verify tapping button opens modal
      await tester.tap(categoryButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Kategori Gunung'), findsOneWidget);
      expect(find.text('7 Summits of Indonesia'), findsOneWidget);

      // Tap 7 Summits of Indonesia
      await tester.tap(find.text('7 Summits of Indonesia'));
      await tester.pumpAndSettle();

      // Ketika kategori aktif, filter chip provinsi hidden
      expect(find.text('Jawa Tengah'), findsNothing);
      expect(find.text('Jawa Barat'), findsNothing);
      expect(find.text('7 Summits of Indonesia'), findsOneWidget);

      // Klik tombol clear ✕ pada tombol kategori
      await tester.tap(find.byKey(const Key('clear_category_button')));
      await tester.pumpAndSettle();

      // Filter chip provinsi muncul kembali
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Jawa Tengah'), findsOneWidget);
    });
  });
}

