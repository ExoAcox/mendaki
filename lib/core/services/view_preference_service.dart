import 'package:shared_preferences/shared_preferences.dart';

class ViewPreferenceService {
  static const String viewModeDetail = 'detail';
  static const String viewModeCompact = 'compact';

  static const String _keyHomeViewMode = 'home_view_mode';
  static const String _keyLibraryViewMode = 'library_view_mode';

  static String? _cachedHomeViewMode;
  static String? _cachedLibraryViewMode;

  /// Cache in-memory untuk mode tampilan Home (sinkron, instan)
  static String get homeViewModeCached =>
      _cachedHomeViewMode ?? viewModeDetail;

  /// Cache in-memory untuk mode tampilan Library (sinkron, instan)
  static String get libraryViewModeCached =>
      _cachedLibraryViewMode ?? viewModeDetail;

  /// Mengambil mode tampilan Home dari SharedPreferences
  static Future<String> getHomeViewMode() async {
    if (_cachedHomeViewMode != null) return _cachedHomeViewMode!;
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_keyHomeViewMode);
    _cachedHomeViewMode = (mode == viewModeCompact) ? viewModeCompact : viewModeDetail;
    return _cachedHomeViewMode!;
  }

  /// Menyimpan mode tampilan Home ke SharedPreferences
  static Future<void> setHomeViewMode(String mode) async {
    final validMode = (mode == viewModeCompact) ? viewModeCompact : viewModeDetail;
    _cachedHomeViewMode = validMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHomeViewMode, validMode);
  }

  /// Mengambil mode tampilan Library dari SharedPreferences
  static Future<String> getLibraryViewMode() async {
    if (_cachedLibraryViewMode != null) return _cachedLibraryViewMode!;
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_keyLibraryViewMode);
    _cachedLibraryViewMode = (mode == viewModeCompact) ? viewModeCompact : viewModeDetail;
    return _cachedLibraryViewMode!;
  }

  /// Menyimpan mode tampilan Library ke SharedPreferences
  static Future<void> setLibraryViewMode(String mode) async {
    final validMode = (mode == viewModeCompact) ? viewModeCompact : viewModeDetail;
    _cachedLibraryViewMode = validMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLibraryViewMode, validMode);
  }

  /// Inisialisasi awal saat startup aplikasi agar kedua cache siap
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final homeMode = prefs.getString(_keyHomeViewMode);
      final libMode = prefs.getString(_keyLibraryViewMode);
      _cachedHomeViewMode = (homeMode == viewModeCompact) ? viewModeCompact : viewModeDetail;
      _cachedLibraryViewMode = (libMode == viewModeCompact) ? viewModeCompact : viewModeDetail;
    } catch (_) {
      _cachedHomeViewMode = viewModeDetail;
      _cachedLibraryViewMode = viewModeDetail;
    }
  }

  /// Untuk keperluan testing
  static void setMockCache({String? home, String? library}) {
    _cachedHomeViewMode = home;
    _cachedLibraryViewMode = library;
  }
}
