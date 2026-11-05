import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String _get(String key, {String defaultValue = ''}) {
    if (dotenv.isInitialized) {
      final val = dotenv.maybeGet(key);
      if (val != null && val.isNotEmpty) return val;
    }
    return defaultValue;
  }

  /// URL project Supabase (diambil dari flutter_dotenv / .env)
  static String get supabaseUrl => _get(
        'SUPABASE_URL',
        defaultValue: const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
      );

  /// Anon / Public Key project Supabase (diambil dari flutter_dotenv / .env)
  static String get supabaseAnonKey => _get(
        'SUPABASE_ANON_KEY',
        defaultValue: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
      );

  /// Bucket penyimpanan GPX
  static String get gpxBucket => _get(
        'GPX_BUCKET',
        defaultValue: const String.fromEnvironment('GPX_BUCKET', defaultValue: 'gpx_file'),
      );

  /// Cek apakah kredensial sudah dikonfigurasi
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
}

