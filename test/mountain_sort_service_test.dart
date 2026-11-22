import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/services/mountain_sort_service.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyMountains = [
    const Mountain(
      id: 'merbabu',
      name: 'Gunung Merbabu',
      elevation: 3145,
      location: 'Boyolali',
      province: 'Jawa Tengah',
      difficulty: 'Sedang',
      estimatedTime: '5 - 9 Jam',
    ),
    const Mountain(
      id: 'prau',
      name: 'Gunung Prau',
      elevation: 2590,
      location: 'Wonosobo',
      province: 'Jawa Tengah',
      difficulty: 'Mudah',
      estimatedTime: '3 - 5 Jam',
    ),
    const Mountain(
      id: 'slamet',
      name: 'Gunung Slamet',
      elevation: 3428,
      location: 'Purbalingga',
      province: 'Jawa Tengah',
      difficulty: 'Sulit',
      estimatedTime: '8 - 12 Jam',
    ),
    const Mountain(
      id: 'argopuro',
      name: 'Gunung Argopuro',
      elevation: 3088,
      location: 'Probolinggo',
      province: 'Jawa Timur',
      difficulty: 'Menantang',
      estimatedTime: '24 - 36 Jam',
    ),
  ];

  group('MountainSortService Sorting Tests', () {
    test('sorts by elevation descending (highest first)', () {
      final sorted = MountainSortService.sort(
        dummyMountains,
        MountainSortOption.elevationDesc,
      );
      expect(sorted.map((m) => m.id).toList(), [
        'slamet', // 3428
        'merbabu', // 3145
        'argopuro', // 3088
        'prau', // 2590
      ]);
    });

    test('sorts by elevation ascending (lowest first)', () {
      final sorted = MountainSortService.sort(
        dummyMountains,
        MountainSortOption.elevationAsc,
      );
      expect(sorted.map((m) => m.id).toList(), [
        'prau', // 2590
        'argopuro', // 3088
        'merbabu', // 3145
        'slamet', // 3428
      ]);
    });

    test('sorts by alphabetical ascending (A - Z, stripping Gunung)', () {
      final sorted = MountainSortService.sort(
        dummyMountains,
        MountainSortOption.alphabeticalAsc,
      );
      expect(sorted.map((m) => m.id).toList(), [
        'argopuro', // A
        'merbabu', // M
        'prau', // P
        'slamet', // S
      ]);
    });

    test('sorts by alphabetical descending (Z - A, stripping Gunung)', () {
      final sorted = MountainSortService.sort(
        dummyMountains,
        MountainSortOption.alphabeticalDesc,
      );
      expect(sorted.map((m) => m.id).toList(), [
        'slamet', // S
        'prau', // P
        'merbabu', // M
        'argopuro', // A
      ]);
    });

    test('sorts by difficulty ascending (Mudah -> Sedang -> Sulit -> Menantang)', () {
      final sorted = MountainSortService.sort(
        dummyMountains,
        MountainSortOption.difficultyAsc,
      );
      expect(sorted.map((m) => m.id).toList(), [
        'prau', // Mudah (1)
        'merbabu', // Sedang (2)
        'slamet', // Sulit (3)
        'argopuro', // Menantang (4)
      ]);
    });

    test('sorts by difficulty descending (Menantang -> Sulit -> Sedang -> Mudah)', () {
      final sorted = MountainSortService.sort(
        dummyMountains,
        MountainSortOption.difficultyDesc,
      );
      expect(sorted.map((m) => m.id).toList(), [
        'argopuro', // Menantang (4)
        'slamet', // Sulit (3)
        'merbabu', // Sedang (2)
        'prau', // Mudah (1)
      ]);
    });

    test('sorts by estimated time ascending (Tercepat)', () {
      final sorted = MountainSortService.sort(
        dummyMountains,
        MountainSortOption.timeAsc,
      );
      expect(sorted.map((m) => m.id).toList(), [
        'prau', // avg 4 Jam
        'merbabu', // avg 7 Jam
        'slamet', // avg 10 Jam
        'argopuro', // avg 30 Jam
      ]);
    });

    test('sorts by estimated time descending (Terlama)', () {
      final sorted = MountainSortService.sort(
        dummyMountains,
        MountainSortOption.timeDesc,
      );
      expect(sorted.map((m) => m.id).toList(), [
        'argopuro', // avg 30 Jam
        'slamet', // avg 10 Jam
        'merbabu', // avg 7 Jam
        'prau', // avg 4 Jam
      ]);
    });
  });

  group('MountainSortService Helper & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      MountainSortService.setMockCache(home: null, library: null);
    });

    test('difficulty ranking parsing works for various terms', () {
      expect(MountainSortService.getDifficultyRank('Mudah'), 1);
      expect(MountainSortService.getDifficultyRank('easy'), 1);
      expect(MountainSortService.getDifficultyRank('Sedang'), 2);
      expect(MountainSortService.getDifficultyRank('medium'), 2);
      expect(MountainSortService.getDifficultyRank('Sulit'), 3);
      expect(MountainSortService.getDifficultyRank('hard'), 3);
      expect(MountainSortService.getDifficultyRank('Menantang'), 4);
      expect(MountainSortService.getDifficultyRank('challenging'), 4);
    });

    test('estimated hours parsing extracts min-max average and single numbers', () {
      expect(MountainSortService.parseEstimatedHours('3 - 5 Jam'), 4.0);
      expect(MountainSortService.parseEstimatedHours('8 - 12 Jam'), 10.0);
      expect(MountainSortService.parseEstimatedHours('6 Jam'), 6.0);
      expect(MountainSortService.parseEstimatedHours(''), 0.0);
    });

    test('getCleanMountainName strips Gunung prefix', () {
      expect(MountainSortService.getCleanMountainName('Gunung Merbabu'), 'merbabu');
      expect(MountainSortService.getCleanMountainName('gunung slamet'), 'slamet');
      expect(MountainSortService.getCleanMountainName('Prau'), 'prau');
    });

    test('persists and synchronizes sort preference across Home and Library', () async {
      expect(await MountainSortService.getSort(), MountainSortOption.elevationDesc);
      expect(await MountainSortService.getHomeSort(), MountainSortOption.elevationDesc);
      expect(await MountainSortService.getLibrarySort(), MountainSortOption.elevationDesc);

      // Ubah sort via setSort (misal dari Home)
      await MountainSortService.setSort(MountainSortOption.alphabeticalAsc);

      // Home dan Library harus sama-sama terupdate
      expect(await MountainSortService.getSort(), MountainSortOption.alphabeticalAsc);
      expect(await MountainSortService.getHomeSort(), MountainSortOption.alphabeticalAsc);
      expect(await MountainSortService.getLibrarySort(), MountainSortOption.alphabeticalAsc);
      expect(MountainSortService.currentSort, MountainSortOption.alphabeticalAsc);
      expect(MountainSortService.sortNotifier.value, MountainSortOption.alphabeticalAsc);

      // Ubah sort via setLibrarySort (dari Library)
      await MountainSortService.setLibrarySort(MountainSortOption.difficultyAsc);

      // Keduanya tetap tersinkronisasi
      expect(await MountainSortService.getSort(), MountainSortOption.difficultyAsc);
      expect(await MountainSortService.getHomeSort(), MountainSortOption.difficultyAsc);
      expect(await MountainSortService.getLibrarySort(), MountainSortOption.difficultyAsc);
      expect(MountainSortService.currentSort, MountainSortOption.difficultyAsc);
      expect(MountainSortService.sortNotifier.value, MountainSortOption.difficultyAsc);
    });
  });
}
