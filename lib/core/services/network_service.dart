import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkService {
  /// Digunakan untuk automated test agar dapat mensimulasikan offline/online.
  @visibleForTesting
  static bool? mockIsOnline;

  /// Memeriksa apakah perangkat memiliki akses jaringan/sinyal internet aktif.
  static Future<bool> isOnline() async {
    if (mockIsOnline != null) {
      return mockIsOnline!;
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
