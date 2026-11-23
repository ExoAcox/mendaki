/// Kategori gunung yang didukung aplikasi
class MountainCategory {
  final String slug;
  final String title;

  const MountainCategory({required this.slug, required this.title});

  static const List<MountainCategory> values = [
    MountainCategory(slug: '7s_indonesia', title: '7 Summit Indonesia'),
    MountainCategory(slug: '7s_jawa', title: '7 Summit Jawa'),
    MountainCategory(slug: '7s_jateng', title: '7 Summit Jawa Tengah'),
    MountainCategory(slug: '7s_jabar', title: '7 Summit Jawa Barat'),
    MountainCategory(slug: '3s_jateng', title: 'Triple S Jawa Tengah'),
  ];

  static MountainCategory? fromSlugOrTitle(String? value) {
    if (value == null) return null;
    final clean = value.trim().toLowerCase();
    for (final cat in values) {
      if (cat.slug.toLowerCase() == clean || cat.title.toLowerCase() == clean) {
        return cat;
      }
    }
    return null;
  }
}
