import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/services/image_cache_manager.dart';
import 'package:mendaki/core/services/network_service.dart';
import 'package:mendaki/core/services/supabase_service.dart';
import 'package:mendaki/screens/home_screen.dart';

void main() {
  group('MountainImageCacheManager Tests', () {
    test('resetStaleTime completes without error', () async {
      await expectLater(MountainImageCacheManager.resetStaleTime(), completes);
    });

    test('revalidateImages returns false when list is empty', () async {
      final updated = await MountainImageCacheManager.revalidateImages([]);
      expect(updated, isFalse);
    });

    test('revalidateImages returns false for empty or invalid strings', () async {
      final updated = await MountainImageCacheManager.revalidateImages(['', 'invalid_url']);
      expect(updated, isFalse);
    });

    test('revalidateAll handles empty list gracefully in test environment', () async {
      final updated = await MountainImageCacheManager.revalidateAll();
      expect(updated, isFalse);
    });
  });

  group('SupabaseService getAllImageUrls Tests', () {
    test('getAllImageUrls returns empty list when Supabase is not ready', () async {
      final urls = await SupabaseService.getAllImageUrls();
      expect(urls, isEmpty);
    });
  });

  group('HomeScreen Refresh Tests', () {
    tearDown(() {
      NetworkService.mockIsOnline = null;
    });

    testWidgets('HomeScreen has RefreshIndicator configured with onRefresh', (
      WidgetTester tester,
    ) async {
      NetworkService.mockIsOnline = false;

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final refreshIndicatorFinder = find.byType(RefreshIndicator);
      expect(refreshIndicatorFinder, findsOneWidget);

      final refreshWidget = tester.widget<RefreshIndicator>(refreshIndicatorFinder);
      expect(refreshWidget.onRefresh, isNotNull);
    });
  });
}
