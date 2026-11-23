import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/widgets/home/mountain_card.dart';
import 'package:mendaki/widgets/home/responsive_mountain_sliver.dart';

void main() {
  group('ResponsiveMountainSliver Tests', () {
    test('getCrossAxisCount returns correct column counts across breakpoints', () {
      expect(ResponsiveMountainSliver.getCrossAxisCount(360), 1);
      expect(ResponsiveMountainSliver.getCrossAxisCount(412), 1);
      expect(ResponsiveMountainSliver.getCrossAxisCount(599), 1);
      expect(ResponsiveMountainSliver.getCrossAxisCount(600), 2);
      expect(ResponsiveMountainSliver.getCrossAxisCount(768), 2);
      expect(ResponsiveMountainSliver.getCrossAxisCount(1023), 2);
      expect(ResponsiveMountainSliver.getCrossAxisCount(1024), 3);
      expect(ResponsiveMountainSliver.getCrossAxisCount(1440), 3);
    });

    testWidgets('Renders 1 column list on phone screen (< 600 dp)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                ResponsiveMountainSliver(
                  itemCount: 4,
                  itemBuilder: (context, index) => Container(
                    key: ValueKey('item_$index'),
                    height: 100,
                    color: Colors.blue,
                    child: Text('Item $index'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Row), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);

      final item0Size = tester.getSize(find.byKey(const ValueKey('item_0')));
      expect(item0Size.width, 400.0);
    });

    testWidgets('Renders 2 column grid on tablet screen (600 - 1023 dp)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                ResponsiveMountainSliver(
                  itemCount: 3,
                  itemBuilder: (context, index) => Container(
                    key: ValueKey('item_$index'),
                    height: 120,
                    color: Colors.green,
                    child: Text('Item $index'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // 3 items in 2-column grid = 2 rows
      expect(find.byType(Row), findsNWidgets(2));
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);

      final item0Size = tester.getSize(find.byKey(const ValueKey('item_0')));
      final item1Size = tester.getSize(find.byKey(const ValueKey('item_1')));
      final item2Size = tester.getSize(find.byKey(const ValueKey('item_2')));

      // Both columns in Row 1 and the lone column in Row 2 have equal width: (768 - 16) / 2 = 376
      expect(item0Size.width, (768 - 16) / 2);
      expect(item1Size.width, (768 - 16) / 2);
      expect(item2Size.width, (768 - 16) / 2);
    });

    testWidgets('Renders 3 column grid on wide / desktop screen (>= 1024 dp)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                ResponsiveMountainSliver(
                  itemCount: 5,
                  crossAxisSpacing: 16,
                  itemBuilder: (context, index) => Container(
                    key: ValueKey('item_$index'),
                    height: 100,
                    color: Colors.amber,
                    child: Text('Item $index'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // 5 items in 3-column grid = 2 rows
      expect(find.byType(Row), findsNWidgets(2));
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 4'), findsOneWidget);

      final item0Size = tester.getSize(find.byKey(const ValueKey('item_0')));
      // (1200 - 32) / 3 = 389.33
      expect(item0Size.width, closeTo((1200 - 32) / 3, 0.01));
    });

    testWidgets('Renders MountainCard with many routes cleanly on tablet width without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const lawu = Mountain(
        id: 'lawu',
        name: 'Gunung Lawu',
        elevation: 3265,
        location: 'Karanganyar & Magetan',
        province: 'Jawa Tengah',
        difficulty: 'Sedang',
        estimatedTime: '6-8 Jam',
        rawRoutes: [
          'Candi Cetho',
          'Cemoro Kandang',
          'Cemoro Sewu',
          'Singolangu',
          'Tambak',
          'Tahura',
          'Jogorogo',
          'Babar'
        ],
      );

      const merapi = Mountain(
        id: 'merapi',
        name: 'Gunung Merapi',
        elevation: 2930,
        location: 'Boyolali',
        province: 'Jawa Tengah',
        difficulty: 'Sedang',
        estimatedTime: '4-6 Jam',
        rawRoutes: ['New Selo'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                ResponsiveMountainSliver(
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    final m = index == 0 ? lawu : merapi;
                    return MountainCard(mountain: m, onDetailTap: () {});
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Gunung Lawu'), findsOneWidget);
      expect(find.text('Gunung Merapi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

