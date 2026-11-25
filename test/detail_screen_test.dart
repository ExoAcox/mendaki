import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';
import 'package:mendaki/screens/detail_screen.dart';
import 'package:mendaki/widgets/detail/detail_bottom_bar.dart';
import 'package:mendaki/widgets/detail/detail_route_item.dart';

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
        difficulty: 3,
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
      expect(find.text('Estimasi Waktu'), findsWidgets);
      expect(find.text('Tingkat Kesulitan'), findsWidgets);
      expect(find.text('Sedang'), findsWidgets);
      expect(find.text('Sulit'), findsWidgets);
      expect(find.text('6-7 Jam'), findsOneWidget);
      // Belum terunduh offline -> Menampilkan tombol Download Map Offline
      expect(find.text('Download Map Offline'), findsOneWidget);
      // Feedback prompt di bawah card rute
      expect(find.text('Jalur belum tersedia?'), findsOneWidget);
      expect(find.text('Request di sini'), findsOneWidget);
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

  test('formatRouteName formats dot-separated route strings into title case', () {
    expect(
      Mountain.formatRouteName('merbabu.selo', mountainId: 'merbabu'),
      'Selo',
    );
    expect(
      Mountain.formatRouteName('sindoro.kledung', mountainId: 'sindoro'),
      'Kledung',
    );
    expect(
      Mountain.formatRouteName('sindoro.alang-alang_sewu', mountainId: 'sindoro'),
      'Alang-alang Sewu',
    );
    expect(
      Mountain.formatRouteName('merbabu.suwanting', mountainId: 'merbabu'),
      'Suwanting',
    );
    expect(Mountain.formatRouteName('selo_timur'), 'Selo Timur');
    expect(Mountain.formatRouteName('selo'), 'Selo');
    expect(
      Mountain.formatRouteName('baderan_-_bremi', mountainId: 'argopuro'),
      'Baderan - Bremi',
    );
    expect(
      Mountain.formatRouteName('argopuro.baderan_-_bremi', mountainId: 'argopuro'),
      'Baderan - Bremi',
    );
  });

  testWidgets('DetailRouteItem displays Instagram basecamp handles when present', (
    tester,
  ) async {
    const routes = [
      HikingRoute(
        id: 'slamet.bambangan',
        name: 'Bambangan',
        basecampName: 'Basecamp Bambangan',
        distanceKm: 10.5,
        estimatedDuration: '7 - 9 Jam',
        elevationGainMeters: 1500,
        difficulty: '4',
        igLinks: ['slametviabambangan', 'slametviabambangan_official'],
      ),
      HikingRoute(
        id: 'slamet.kaliwadas',
        name: 'Kaliwadas',
        basecampName: 'Basecamp Kaliwadas',
        distanceKm: 14.0,
        estimatedDuration: '9 - 11 Jam',
        elevationGainMeters: 1200,
        difficulty: '4',
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DetailRouteItem(routes: routes, peakElevation: 3428),
          ),
        ),
      ),
    );

    expect(find.text('@slametviabambangan'), findsOneWidget);
    expect(find.text('@slametviabambangan_official'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
  });

  test('HikingRoute serializes and deserializes igLinks cleanly', () {
    final fromSupabase = HikingRoute.fromJson({
      'id': 'prau.patakbanteng',
      'name': 'Patakbanteng',
      'basecampName': 'Basecamp Patakbanteng',
      'distanceKm': 4.5,
      'estimatedDuration': '3 - 4 Jam',
      'elevationGainMeters': 1800,
      'difficulty': '2',
      'ig_link': ['basecamppatakbanteng', 'patakbanteng'],
    });

    expect(fromSupabase.igLinks, ['basecamppatakbanteng', 'patakbanteng']);

    final roundTrip = HikingRoute.fromJson(fromSupabase.toJson());
    expect(roundTrip.igLinks, ['basecamppatakbanteng', 'patakbanteng']);
  });
}
