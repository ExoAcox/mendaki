import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';
import 'package:mendaki/screens/detail_screen.dart';
import 'package:mendaki/widgets/detail/detail_bottom_bar.dart';

void main() {
  testWidgets(
    'DetailScreen displays mountain, route, and offline download CTA',
    (tester) async {
      const testMountain = Mountain(
        id: 'merbabu',
        name: 'Gunung Merbabu',
        elevation: 3145,
        location: 'Boyolali & Magelang',
        province: 'Jawa Tengah',
        difficulty: 'Sedang',
        estimatedTime: '2D1N',
        routes: [
          HikingRoute(
            id: 'merbabu_selo',
            name: 'Selo',
            basecampName: 'Basecamp Selo',
            distanceKm: 9.0,
            estimatedDuration: '6-7 Jam',
            elevationGainMeters: 1800,
            difficulty: 'Sedang',
            hasWater: false,
          ),
          HikingRoute(
            id: 'merbabu_suwanting',
            name: 'Suwanting',
            basecampName: 'Basecamp Suwanting',
            distanceKm: 11.0,
            estimatedDuration: '8-9 Jam',
            elevationGainMeters: 2100,
            difficulty: 'Sulit',
            hasWater: true,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(home: DetailScreen(mountain: testMountain)),
      );

      expect(find.text('Gunung Merbabu'), findsWidgets);
      expect(find.text('3145'), findsOneWidget);
      expect(find.textContaining('Selo'), findsWidgets);
      // Belum terunduh offline -> Menampilkan tombol Download Peta Offline
      expect(find.text('Download Peta Offline'), findsOneWidget);
    },
  );

  testWidgets(
    'DetailBottomBar displays navigation button when offline is ready',
    (tester) async {
      bool navigationTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: DetailBottomBar(
              onStartNavigation: () {
                navigationTriggered = true;
              },
              onDownloadGpx: () {},
              isOfflineReady: true,
            ),
          ),
        ),
      );

      expect(find.text('Mulai Mendaki'), findsOneWidget);

      await tester.tap(find.text('Mulai Mendaki'));
      expect(navigationTriggered, isTrue);
    },
  );

  test('formatRouteName formats hyphenated route strings into title case', () {
    expect(
      Mountain.formatRouteName('merbabu-selo', mountainId: 'merbabu'),
      'Selo',
    );
    expect(
      Mountain.formatRouteName('merbabu-suwanting', mountainId: 'merbabu'),
      'Suwanting',
    );
    expect(
      Mountain.formatRouteName('merbabu-wekas', mountainId: 'merbabu'),
      'Wekas',
    );
    expect(
      Mountain.formatRouteName('merbabu-thekelan', mountainId: 'merbabu'),
      'Thekelan',
    );
    expect(
      Mountain.formatRouteName('merbabu-cuntel', mountainId: 'merbabu'),
      'Cuntel',
    );
    expect(Mountain.formatRouteName('selo-timur'), 'Selo Timur');
    expect(Mountain.formatRouteName('selo'), 'Selo');
  });
}
