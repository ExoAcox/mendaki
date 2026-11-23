import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain_category.dart';
import 'mountain_category_modal.dart';

/// Tombol pemilih kategori gunung yang diletakkan di samping kiri filter provinsi
class MountainCategoryButton extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  const MountainCategoryButton({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedCategory != null && selectedCategory!.isNotEmpty;
    final catObj = MountainCategory.fromSlugOrTitle(selectedCategory);
    final displayLabel = isSelected
        ? (catObj?.title ?? selectedCategory!)
        : 'Kategori';

    return Tooltip(
      message: isSelected
          ? 'Kategori: $selectedCategory'
          : 'Pilih Kategori Gunung',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('mountain_category_button'),
          onTap: () {
            MountainCategoryModal.show(
              context,
              selectedCategory: selectedCategory,
              onCategorySelected: onCategoryChanged,
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 38,
            padding: const EdgeInsets.only(left: 16, right: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon(
                //   Icons.category_outlined,
                //   size: 15,
                //   color: isSelected ? Colors.white : AppTheme.onSurface,
                // ),
                // const SizedBox(width: 6),
                Text(
                  displayLabel,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.onSurface,
                  ),
                ),
                const SizedBox(width: 2),
                if (isSelected)
                  GestureDetector(
                    key: const Key('clear_category_button'),
                    onTap: () => onCategoryChanged(null),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6, right: 4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: AppTheme.onSurface,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
