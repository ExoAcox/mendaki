import 'dart:io';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/foundation.dart';

/// Layanan untuk mengecek sisa kapasitas ruang penyimpanan perangkat (available disk space)
class StorageInfoService {
  static Future<int?> getAvailableDiskSpaceBytes() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return 10 * 1024 * 1024 * 1024; // Mock 10 GB untuk lingkungan test
    }
    try {
      final diskSpace = DiskSpacePlus();
      final freeMb = await diskSpace.getFreeDiskSpace;
      if (freeMb != null && freeMb >= 0) {
        return (freeMb * 1024 * 1024).round();
      }
    } catch (e) {
      debugPrint('Error getting available disk space: $e');
    }
    return null;
  }
}

