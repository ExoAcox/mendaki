import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mendaki/core/services/version_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VersionStateService Tests', () {
    test('returns true when version has never been dismissed', () async {
      final shouldShow =
          await VersionStateService.shouldShowUpdateDialog('1.1');
      expect(shouldShow, isTrue);
    });

    test('returns false within 7 days after dismiss', () async {
      await VersionStateService.saveDismissState('1.1');

      final shouldShow =
          await VersionStateService.shouldShowUpdateDialog('1.1');
      expect(shouldShow, isFalse);
    });

    test('returns true for a different version even if previous version was dismissed',
        () async {
      await VersionStateService.saveDismissState('1.1');

      final shouldShow =
          await VersionStateService.shouldShowUpdateDialog('1.2');
      expect(shouldShow, isTrue);
    });

    test('always returns true if forceUpdate is true', () async {
      await VersionStateService.saveDismissState('1.1');

      final shouldShow = await VersionStateService.shouldShowUpdateDialog(
        '1.1',
        forceUpdate: true,
      );
      expect(shouldShow, isTrue);
    });

    test('resets state and returns true when dismissed more than 7 days ago',
        () async {
      final prefs = await SharedPreferences.getInstance();
      // Simulasikan 8 hari yang lalu
      final eightDaysAgo =
          DateTime.now().subtract(const Duration(days: 8)).millisecondsSinceEpoch;
      await prefs.setString('version_dismissed_id', '1.1');
      await prefs.setInt('version_dismissed_at', eightDaysAgo);

      final shouldShow =
          await VersionStateService.shouldShowUpdateDialog('1.1');
      expect(shouldShow, isTrue);

      // Verifikasi bahwa state lama sudah di-reset dari preferences
      expect(prefs.getString('version_dismissed_id'), isNull);
      expect(prefs.getInt('version_dismissed_at'), isNull);
    });
  });
}

