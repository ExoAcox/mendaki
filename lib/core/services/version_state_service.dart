import 'package:shared_preferences/shared_preferences.dart';

class VersionStateService {
  static const String _keyDismissedAt = 'version_dismissed_at';
  static const String _keyDismissedVersion = 'version_dismissed_id';
  static const Duration expirationDuration = Duration(days: 7);

  /// Cek apakah dialog update perlu ditampilkan.
  /// Mengembalikan `true` jika dialog harus ditampilkan.
  /// Mengembalikan `false` jika masih dalam masa tunda 7 hari sejak dialog ditutup.
  static Future<bool> shouldShowUpdateDialog(
    String versionId, {
    bool forceUpdate = false,
  }) async {
    // Jika update bersifat wajib (force update), jangan pernah disembunyikan
    if (forceUpdate) return true;

    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getString(_keyDismissedVersion);
    final dismissedAtMillis = prefs.getInt(_keyDismissedAt);

    // Belum pernah ditutup atau versi yang ditutup berbeda dengan versi baru
    if (savedVersion != versionId || dismissedAtMillis == null) {
      return true;
    }

    final dismissedAt = DateTime.fromMillisecondsSinceEpoch(dismissedAtMillis);
    final now = DateTime.now();
    final difference = now.difference(dismissedAt);

    // Jika sudah lewat 7 hari (seminggu), reset state dan munculkan kembali
    if (difference >= expirationDuration) {
      await resetDismissState();
      return true;
    }

    // Masih dalam masa 7 hari sejak ditutup -> jangan munculkan dialog
    return false;
  }

  /// Menyimpan state saat dialog ditutup oleh user
  static Future<void> saveDismissState(String versionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDismissedVersion, versionId);
    await prefs.setInt(_keyDismissedAt, DateTime.now().millisecondsSinceEpoch);
  }

  /// Reset state tunda pembaruan
  static Future<void> resetDismissState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDismissedVersion);
    await prefs.remove(_keyDismissedAt);
  }
}

