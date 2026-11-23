import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain_category.dart';

/// Modal dialog untuk memilih kategori gunung (7 Summits, Triple S, dll)
class MountainCategoryModal extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const MountainCategoryModal({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String? selectedCategory,
    required ValueChanged<String?> onCategorySelected,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MountainCategoryModal(
        selectedCategory: selectedCategory,
        onCategorySelected: onCategorySelected,
      ),
    );
  }

  void _handleSelect(BuildContext context, String? category) {
    onCategorySelected(category);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedCategory != null && selectedCategory!.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Kategori Gunung',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppTheme.outline,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 0.6,
                color: AppTheme.outlineVariant.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 6),

              // Opsi Kategori
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTile(
                        context: context,
                        label: 'Tampilkan Semua Gunung',
                        categoryTitle: null,
                        icon: Icons.grid_view_rounded,
                        isSelected:
                            selectedCategory == null ||
                            selectedCategory!.isEmpty,
                      ),
                      for (final cat in MountainCategory.values)
                        _buildTile(
                          context: context,
                          label: cat.title,
                          categoryTitle: cat.title,
                          icon: Icons.filter_hdr_rounded,
                          isSelected: _isCatSelected(cat),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isCatSelected(MountainCategory cat) {
    if (selectedCategory == null) return false;
    final clean = selectedCategory!.trim().toLowerCase();
    return cat.slug.toLowerCase() == clean || cat.title.toLowerCase() == clean;
  }

  Widget _buildTile({
    required BuildContext context,
    required String label,
    required String? categoryTitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected
          ? AppTheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        key: Key(
          categoryTitle == null
              ? 'category_option_all'
              : 'category_option_$categoryTitle',
        ),
        onTap: () {
          // Jika opsi yang sama diklik lagi, toggle off (reset ke null) jika bukan "Semua Kategori"
          if (isSelected && categoryTitle != null) {
            _handleSelect(context, null);
          } else {
            _handleSelect(context, categoryTitle);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: isSelected ? AppTheme.primary : AppTheme.outline,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_rounded,
                  size: 19,
                  color: AppTheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
