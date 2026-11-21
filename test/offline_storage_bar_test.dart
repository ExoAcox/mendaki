import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/widgets/home/offline_storage_bar.dart';

void main() {
  group('OfflineStorageBar Widget Tests', () {
    testWidgets('renders empty state when totalBytes is 0',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineStorageBar(
              gpxBytes: 0,
              mapBytes: 0,
            ),
          ),
        ),
      );

      expect(find.text('Penyimpanan Offline'), findsOneWidget);
      expect(find.text('0 B'), findsOneWidget);
      expect(
        find.text('Belum ada data yang tersimpan secara offline.'),
        findsOneWidget,
      );
    });

    testWidgets('renders horizontal bar with GPX and Map percentages and sizes',
        (WidgetTester tester) async {
      // 500 KB GPX, 9.5 MB Map -> Total 10 MB
      const gpx = 500 * 1024;
      const map = 9500 * 1024;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineStorageBar(
              gpxBytes: gpx,
              mapBytes: map,
            ),
          ),
        ),
      );

      expect(find.text('Penyimpanan Offline'), findsOneWidget);
      // Total 10.0 MB (was 9500 + 500 = 10000 KB ~= 9.8 MB)
      expect(find.text(OfflineStorageBar.formatBytes(gpx + map)), findsOneWidget);

      // Verify legend contains GPX and Map with their sizes
      expect(find.textContaining('GPX:'), findsOneWidget);
      expect(find.textContaining('Map:'), findsOneWidget);
    });

    testWidgets('renders available storage in header and legend when provided',
        (WidgetTester tester) async {
      const gpx = 500 * 1024;
      const map = 9500 * 1024;
      const available = 50 * 1024 * 1024 * 1024; // 50 GB

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineStorageBar(
              gpxBytes: gpx,
              mapBytes: map,
              availableBytes: available,
            ),
          ),
        ),
      );

      expect(find.textContaining('Sisa 50.0 GB'), findsOneWidget);
      expect(find.textContaining('Tersedia: 50.0 GB'), findsOneWidget);

      // Verify that the progress bar contains 3 segments (Expanded widgets for GPX, Map, and Tersedia)
      final progressBarFinder = find.byType(OfflineStorageProgressBar);
      expect(progressBarFinder, findsOneWidget);
      final expandedWidgets = find.descendant(
        of: progressBarFinder,
        matching: find.byType(Expanded),
      );
      expect(expandedWidgets, findsNWidgets(3));
    });

    test('formatBytes formats different byte sizes correctly', () {
      expect(OfflineStorageBar.formatBytes(0), '0 B');
      expect(OfflineStorageBar.formatBytes(512), '512 B');
      expect(OfflineStorageBar.formatBytes(1024), '1.0 KB');
      expect(OfflineStorageBar.formatBytes(1536), '1.5 KB');
      expect(OfflineStorageBar.formatBytes(1024 * 1024), '1.0 MB');
      expect(OfflineStorageBar.formatBytes((15.5 * 1024 * 1024).round()), '15.5 MB');
      expect(OfflineStorageBar.formatBytes((1.2 * 1024 * 1024 * 1024).round()), '1.2 GB');
    });

    testWidgets('OfflineStorageNotice renders notice text and icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineStorageNotice(),
          ),
        ),
      );

      expect(find.byIcon(Icons.offline_pin_rounded), findsOneWidget);
      expect(
        find.textContaining('tersimpan offline di perangkat Anda'),
        findsOneWidget,
      );
    });

    testWidgets('split sub-widgets render properly in isolation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OfflineStorageHeader(totalFormatted: '25.0 MB'),
                OfflineStorageProgressBar(
                  gpxBytes: 5 * 1024 * 1024,
                  mapBytes: 20 * 1024 * 1024,
                  gpxPercentage: 20.0,
                  mapPercentage: 80.0,
                ),
                OfflineStorageLegend(
                  gpxBytes: 5 * 1024 * 1024,
                  mapBytes: 20 * 1024 * 1024,
                  gpxPercentage: 20.0,
                  mapPercentage: 80.0,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('25.0 MB'), findsOneWidget);
      expect(find.textContaining('GPX:'), findsOneWidget);
      expect(find.textContaining('Map:'), findsOneWidget);
    });
  });
}

