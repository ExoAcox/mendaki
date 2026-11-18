import 'dart:math' as math;
import 'package:mendaki/core/config/app_config.dart';

class AppVersion {
  final String id;
  final String title;
  final String desc;
  final String? updateLink;
  final String? forceUpdateVersion;
  final bool? _manualForceUpdate;
  final DateTime? createdAt;

  const AppVersion({
    required this.id,
    required this.title,
    required this.desc,
    this.updateLink,
    this.forceUpdateVersion,
    bool? forceUpdate,
    this.createdAt,
  }) : _manualForceUpdate = forceUpdate;

  /// Mengecek apakah versi saat ini ([currentVersion]) berada di bawah [forceUpdateVersion].
  /// Jika ya, maka menjadi force update (wajib diperbarui).
  bool isForceUpdate([String? currentVersion]) {
    final current = currentVersion ?? AppConfig.currentVersion;
    if (forceUpdateVersion != null && forceUpdateVersion!.trim().isNotEmpty) {
      return isVersionBelow(current, forceUpdateVersion!);
    }
    return _manualForceUpdate ?? false;
  }

  /// Getter ketersediaan force update berdasarkan versi aplikasi saat ini (`AppConfig.currentVersion`).
  bool get forceUpdate => isForceUpdate(AppConfig.currentVersion);

  /// Membandingkan dua string versi secara semantik/numerik (misal: "1.0", "1.1", "1.10", "1.0.1").
  /// Mengembalikan nilai negatif jika v1 < v2, 0 jika v1 == v2, dan positif jika v1 > v2.
  static int compareVersions(String v1, String v2) {
    final cleanV1 = v1.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final cleanV2 = v2.trim().replaceFirst(RegExp(r'^[vV]'), '');

    final parts1 = cleanV1
        .split('.')
        .map((p) => int.tryParse(p.split(RegExp(r'[^0-9]'))[0]) ?? 0)
        .toList();
    final parts2 = cleanV2
        .split('.')
        .map((p) => int.tryParse(p.split(RegExp(r'[^0-9]'))[0]) ?? 0)
        .toList();

    final maxLen = math.max(parts1.length, parts2.length);
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) {
        return p1.compareTo(p2);
      }
    }
    return 0;
  }

  /// Mengembalikan `true` jika [v1] secara numerik berada di bawah [v2].
  static bool isVersionBelow(String v1, String v2) {
    return compareVersions(v1, v2) < 0;
  }

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Update Tersedia',
      desc: json['desc']?.toString() ?? '',
      updateLink: json['update_link'] as String?,
      forceUpdateVersion: json['force_update_version']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'desc': desc,
      'update_link': updateLink,
      'force_update_version': forceUpdateVersion,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
