import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';
import 'package:path_provider/path_provider.dart';

class ActiveNavigationSession {
  final Mountain mountain;
  final HikingRoute? selectedRoute;
  final DateTime startTime;
  final List<LatLng> traveledPath;

  const ActiveNavigationSession({
    required this.mountain,
    this.selectedRoute,
    required this.startTime,
    this.traveledPath = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'mountain': mountain.toJson(),
      'selectedRoute': selectedRoute?.toJson(),
      'startTime': startTime.toIso8601String(),
      'traveledPath': traveledPath
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
    };
  }

  factory ActiveNavigationSession.fromJson(Map<String, dynamic> json) {
    return ActiveNavigationSession(
      mountain: Mountain.fromJson(json['mountain'] as Map<String, dynamic>),
      selectedRoute: json['selectedRoute'] != null
          ? HikingRoute.fromJson(json['selectedRoute'] as Map<String, dynamic>)
          : null,
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ??
          DateTime.now(),
      traveledPath: (json['traveledPath'] as List<dynamic>?)
              ?.map((item) {
                final map = item as Map<String, dynamic>;
                return LatLng(
                  (map['lat'] as num).toDouble(),
                  (map['lng'] as num).toDouble(),
                );
              })
              .toList() ??
          [],
    );
  }
}

class NavigationSessionService {
  @visibleForTesting
  static String? customSessionDirectoryPath;

  static Future<String> getSessionFilePath() async {
    if (customSessionDirectoryPath != null) {
      return '$customSessionDirectoryPath/active_navigation_session.json';
    }
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return '${Directory.systemTemp.path}/active_navigation_session.json';
    }
    Directory targetDir;
    try {
      targetDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      targetDir = Directory.systemTemp;
    }
    return '${targetDir.path}/active_navigation_session.json';
  }

  /// Menyimpan atau memperbarui sesi navigasi aktif yang sedang berjalan
  static Future<void> saveActiveSession(ActiveNavigationSession session) async {
    try {
      final filePath = await getSessionFilePath();
      final file = File(filePath);
      file.writeAsStringSync(jsonEncode(session.toJson()), flush: true);
    } catch (e) {
      debugPrint('Error saving active navigation session: $e');
    }
  }

  /// Mengambil sesi navigasi aktif jika belum di-finish
  static Future<ActiveNavigationSession?> getActiveSession() async {
    try {
      final filePath = await getSessionFilePath();
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return null;

      final json = jsonDecode(content) as Map<String, dynamic>;
      return ActiveNavigationSession.fromJson(json);
    } catch (e) {
      debugPrint('Error reading active navigation session: $e');
      return null;
    }
  }

  /// Menghapus sesi navigasi aktif saat user menekan Finish
  static Future<void> clearActiveSession() async {
    try {
      final filePath = await getSessionFilePath();
      final file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint('Error clearing active navigation session: $e');
    }
  }
}

