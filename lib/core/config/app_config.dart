/// Konfigurasi umum aplikasi Mendaki
class AppConfig {
  /// Versi aplikasi saat ini.
  /// Nilai ini akan dicocokkan dengan field `id` pada tabel `version` di Supabase.
  /// Jika nilainya berbeda (misalnya di DB bernilai '1.1' dan di sini '1.0'),
  /// modal pembaruan aplikasi akan otomatis muncul saat awal aplikasi dimuat.
  static const String currentVersion = '1.1';
}
