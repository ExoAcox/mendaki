import 'package:flutter/material.dart';
import 'package:mendaki/core/services/mountain_sort_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/widgets/home/mountain_sort_button.dart';
import 'package:mendaki/widgets/home/view_mode_toggle.dart';

/// Baris header bagian atas daftar gunung di halaman Home dan Library
/// Menampilkan jumlah gunung tersedia, tombol sorting, dan tombol toggle view mode
class MountainSectionHeader extends StatelessWidget {
  final int count;
  final MountainSortOption currentSort;
  final ValueChanged<MountainSortOption> onSortChanged;
  final String currentViewMode;
  final ValueChanged<String> onViewModeChanged;

  const MountainSectionHeader({
    super.key,
    required this.count,
    required this.currentSort,
    required this.onSortChanged,
    required this.currentViewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$count Gunung Tersedia',
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MountainSortButton(
              currentSort: currentSort,
              onSortChanged: onSortChanged,
            ),
            const SizedBox(width: 8),
            ViewModeToggle(
              currentMode: currentViewMode,
              onModeChanged: onViewModeChanged,
            ),
          ],
        ),
      ],
    );
  }
}

