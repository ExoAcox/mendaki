import 'package:flutter/material.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opsi pengurutan daftar gunung
enum MountainSortOption {
  // Elevasi
  elevationDesc(
    label: 'Elevasi Tertinggi',
    category: 'Elevasi',
    directionLabel: 'Tertinggi',
    icon: Icons.filter_hdr_rounded,
  ),
  elevationAsc(
    label: 'Elevasi Terendah',
    category: 'Elevasi',
    directionLabel: 'Terendah',
    icon: Icons.terrain_rounded,
  ),

  // Abjad
  alphabeticalAsc(
    label: 'Abjad (A - Z)',
    category: 'Abjad',
    directionLabel: 'A - Z',
    icon: Icons.sort_by_alpha_rounded,
  ),
  alphabeticalDesc(
    label: 'Abjad (Z - A)',
    category: 'Abjad',
    directionLabel: 'Z - A',
    icon: Icons.sort_by_alpha_rounded,
  ),

  // Tingkat Kesulitan
  difficultyAsc(
    label: 'Kesulitan: Mudah ke Sulit',
    category: 'Tingkat Kesulitan',
    directionLabel: 'Mudah',
    icon: Icons.fitness_center_rounded,
  ),
  difficultyDesc(
    label: 'Kesulitan: Sulit ke Mudah',
    category: 'Tingkat Kesulitan',
    directionLabel: 'Sulit',
    icon: Icons.fitness_center_rounded,
  ),

  // Estimasi Waktu
  timeAsc(
    label: 'Waktu: Tercepat',
    category: 'Estimasi Waktu',
    directionLabel: 'Tercepat',
    icon: Icons.timer_outlined,
  ),
  timeDesc(
    label: 'Waktu: Terlama',
    category: 'Estimasi Waktu',
    directionLabel: 'Terlama',
    icon: Icons.hourglass_bottom_rounded,
  );

  final String label;
  final String category;
  final String directionLabel;
  final IconData icon;

  const MountainSortOption({
    required this.label,
    required this.category,
    required this.directionLabel,
    required this.icon,
  });
}

/// Service untuk sorting dan persistensi preferensi pengurutan gunung (tersinkronisasi untuk Home & Library)
class MountainSortService {
  static const MountainSortOption defaultSort = MountainSortOption.elevationDesc;

  static const String _keySort = 'mountain_sort';
  static const String _keyLegacyHomeSort = 'home_mountain_sort';
  static const String _keyLegacyLibrarySort = 'library_mountain_sort';

  static MountainSortOption _cachedSort = defaultSort;

  /// Notifier agar perubahan sort di Home atau Library langsung sinkron secara reaktif
  static final ValueNotifier<MountainSortOption> sortNotifier =
      ValueNotifier<MountainSortOption>(defaultSort);

  static MountainSortOption get currentSort => _cachedSort;

  // Backward compatibility getters
  static MountainSortOption get homeSortCached => currentSort;
  static MountainSortOption get librarySortCached => currentSort;

  /// Membaca preferensi sort bersama dari cache / SharedPreferences
  static Future<MountainSortOption> getSort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_keySort) ??
          prefs.getString(_keyLegacyHomeSort) ??
          prefs.getString(_keyLegacyLibrarySort);
      _cachedSort = _parseOption(key);
      sortNotifier.value = _cachedSort;
    } catch (_) {
      _cachedSort = defaultSort;
      sortNotifier.value = defaultSort;
    }
    return _cachedSort;
  }

  /// Menyimpan preferensi sort bersama untuk Home dan Library
  static Future<void> setSort(MountainSortOption option) async {
    _cachedSort = option;
    sortNotifier.value = option;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySort, option.name);
    } catch (_) {}
  }

  // Backward compatibility methods
  static Future<MountainSortOption> getHomeSort() => getSort();
  static Future<void> setHomeSort(MountainSortOption option) => setSort(option);
  static Future<MountainSortOption> getLibrarySort() => getSort();
  static Future<void> setLibrarySort(MountainSortOption option) => setSort(option);

  static MountainSortOption _parseOption(String? name) {
    if (name == null || name.isEmpty) return defaultSort;
    for (final opt in MountainSortOption.values) {
      if (opt.name == name) return opt;
    }
    return defaultSort;
  }

  /// Mengonversi tingkat kesulitan ke ranking numerik:
  /// Mendukung int, `List<int>`, num, atau teks kesulitan
  static int getDifficultyRank(dynamic difficulty) {
    if (difficulty is int) return difficulty;
    if (difficulty is num) return difficulty.toInt();
    if (difficulty is List<int>) {
      if (difficulty.isEmpty) return 0;
      return difficulty.first;
    }
    if (difficulty is String) {
      final parsed = int.tryParse(difficulty);
      if (parsed != null) return parsed;
      final d = difficulty.toLowerCase().trim();
      if (d.contains('mudah') || d == 'easy') return 1;
      if (d.contains('sedang') || d == 'medium') return 2;
      if (d.contains('sangat sulit') ||
          d.contains('sangat_sulit') ||
          d.contains('very_hard') ||
          d.contains('very hard')) {
        return 4;
      }
      if (d.contains('sulit') || d == 'hard') return 3;
    }
    return 2;
  }

  /// Mengekstrak rata-rata jam estimasi waktu dari format "min - max Jam" atau "X Jam"
  static double parseEstimatedHours(String estimatedTime) {
    if (estimatedTime.trim().isEmpty) return 0.0;
    final matches = RegExp(r'(\d+(?:\.\d+)?)').allMatches(estimatedTime).toList();
    if (matches.isEmpty) return 0.0;
    if (matches.length >= 2) {
      final min = double.tryParse(matches[0].group(1)!) ?? 0.0;
      final max = double.tryParse(matches[1].group(1)!) ?? min;
      return (min + max) / 2.0;
    }
    return double.tryParse(matches[0].group(1)!) ?? 0.0;
  }

  /// Membersihkan nama gunung (menghilangkan awalan 'Gunung ') agar sort abjad akurat
  static String getCleanMountainName(String name) {
    var clean = name.trim().toLowerCase();
    if (clean.startsWith('gunung ')) {
      clean = clean.substring(7).trim();
    }
    return clean;
  }

  /// Mengurutkan list gunung sesuai opsi pengurutan yang dipilih
  static List<Mountain> sort(List<Mountain> mountains, MountainSortOption sortOption) {
    final list = List<Mountain>.from(mountains);
    list.sort((a, b) {
      switch (sortOption) {
        case MountainSortOption.elevationDesc:
          final cmp = b.elevation.compareTo(a.elevation);
          if (cmp != 0) return cmp;
          return a.name.compareTo(b.name);

        case MountainSortOption.elevationAsc:
          final cmp = a.elevation.compareTo(b.elevation);
          if (cmp != 0) return cmp;
          return a.name.compareTo(b.name);

        case MountainSortOption.alphabeticalAsc:
          final cleanA = getCleanMountainName(a.name);
          final cleanB = getCleanMountainName(b.name);
          final cmp = cleanA.compareTo(cleanB);
          if (cmp != 0) return cmp;
          return b.elevation.compareTo(a.elevation);

        case MountainSortOption.alphabeticalDesc:
          final cleanA = getCleanMountainName(a.name);
          final cleanB = getCleanMountainName(b.name);
          final cmp = cleanB.compareTo(cleanA);
          if (cmp != 0) return cmp;
          return b.elevation.compareTo(a.elevation);

        case MountainSortOption.difficultyAsc:
          final diffA = getDifficultyRank(a.difficulty);
          final diffB = getDifficultyRank(b.difficulty);
          if (diffA != diffB) return diffA.compareTo(diffB);
          return b.elevation.compareTo(a.elevation);

        case MountainSortOption.difficultyDesc:
          final diffA = getDifficultyRank(a.difficulty);
          final diffB = getDifficultyRank(b.difficulty);
          if (diffA != diffB) return diffB.compareTo(diffA);
          return b.elevation.compareTo(a.elevation);

        case MountainSortOption.timeAsc:
          return _compareEstimatedTime(a, b, ascending: true);

        case MountainSortOption.timeDesc:
          return _compareEstimatedTime(a, b, ascending: false);
      }
    });
    return list;
  }

  static int _compareEstimatedTime(Mountain a, Mountain b, {required bool ascending}) {
    final hoursA = parseEstimatedHours(a.estimatedTime);
    final hoursB = parseEstimatedHours(b.estimatedTime);
    final aKnown = hoursA > 0;
    final bKnown = hoursB > 0;

    // Gunung dengan durasi tidak diketahui ditaruh di urutan paling belakang
    if (aKnown && !bKnown) return -1;
    if (!aKnown && bKnown) return 1;
    if (!aKnown && !bKnown) return b.elevation.compareTo(a.elevation);

    final cmp = hoursA.compareTo(hoursB);
    if (cmp != 0) return ascending ? cmp : -cmp;
    return b.elevation.compareTo(a.elevation);
  }

  /// Inisialisasi awal saat startup
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sort = prefs.getString(_keySort) ??
          prefs.getString(_keyLegacyHomeSort) ??
          prefs.getString(_keyLegacyLibrarySort);
      _cachedSort = _parseOption(sort);
      sortNotifier.value = _cachedSort;
    } catch (_) {
      _cachedSort = defaultSort;
      sortNotifier.value = defaultSort;
    }
  }

  /// Mocking untuk testing
  static void setMockCache({
    MountainSortOption? sort,
    MountainSortOption? home,
    MountainSortOption? library,
  }) {
    _cachedSort = sort ?? home ?? library ?? defaultSort;
    sortNotifier.value = _cachedSort;
  }
}
