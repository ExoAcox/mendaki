import 'package:flutter/material.dart';
import 'package:mendaki/core/services/mountain_sort_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'mountain_sort_modal.dart';

/// Reusable sort button yang diletakkan di samping kiri ViewModeToggle
class MountainSortButton extends StatelessWidget {
  final MountainSortOption currentSort;
  final ValueChanged<MountainSortOption> onSortChanged;

  const MountainSortButton({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Urutkan: ${currentSort.label}',
      child: GestureDetector(
        key: const Key('mountain_sort_button'),
        onTap: () {
          MountainSortModal.show(
            context,
            currentSort: currentSort,
            onSortSelected: onSortChanged,
          );
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: 46,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Icon(
            Icons.swap_vert_rounded,
            size: 19,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
