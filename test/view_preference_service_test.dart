import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/services/view_preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ViewPreferenceService.setMockCache(home: null, library: null);
  });

  group('ViewPreferenceService Tests', () {
    test('Default mode for both Home and Library is "detail"', () async {
      expect(ViewPreferenceService.homeViewModeCached, 'detail');
      expect(ViewPreferenceService.libraryViewModeCached, 'detail');

      expect(await ViewPreferenceService.getHomeViewMode(), 'detail');
      expect(await ViewPreferenceService.getLibraryViewMode(), 'detail');
    });

    test('Separates preferences between Home and Library', () async {
      await ViewPreferenceService.setHomeViewMode(ViewPreferenceService.viewModeCompact);
      expect(ViewPreferenceService.homeViewModeCached, 'compact');
      expect(ViewPreferenceService.libraryViewModeCached, 'detail');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('home_view_mode'), 'compact');
      expect(prefs.getString('library_view_mode'), isNull);

      await ViewPreferenceService.setLibraryViewMode(ViewPreferenceService.viewModeDetail);
      expect(prefs.getString('library_view_mode'), 'detail');
      expect(ViewPreferenceService.homeViewModeCached, 'compact');
      expect(ViewPreferenceService.libraryViewModeCached, 'detail');
    });

    test('Switching modes between "detail" and "compact" works as expected', () async {
      await ViewPreferenceService.setLibraryViewMode('compact');
      expect(ViewPreferenceService.libraryViewModeCached, 'compact');
      expect(await ViewPreferenceService.getLibraryViewMode(), 'compact');

      await ViewPreferenceService.setLibraryViewMode('detail');
      expect(ViewPreferenceService.libraryViewModeCached, 'detail');
      expect(await ViewPreferenceService.getLibraryViewMode(), 'detail');
    });

    test('init() reads persisted values into respective caches', () async {
      SharedPreferences.setMockInitialValues({
        'home_view_mode': 'compact',
        'library_view_mode': 'detail',
      });
      ViewPreferenceService.setMockCache(home: null, library: null);

      await ViewPreferenceService.init();
      expect(ViewPreferenceService.homeViewModeCached, 'compact');
      expect(ViewPreferenceService.libraryViewModeCached, 'detail');
    });
  });
}
