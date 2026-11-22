import 'package:flutter/material.dart';
import 'package:mendaki/core/services/mountain_sort_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';

/// Modal dialog simpel untuk memilih kriteria pengurutan gunung
class MountainSortModal extends StatelessWidget {
  final MountainSortOption currentSort;
  final ValueChanged<MountainSortOption> onSortSelected;

  const MountainSortModal({
    super.key,
    required this.currentSort,
    required this.onSortSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required MountainSortOption currentSort,
    required ValueChanged<MountainSortOption> onSortSelected,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MountainSortModal(
        currentSort: currentSort,
        onSortSelected: onSortSelected,
      ),
    );
  }

  void _handleSelect(BuildContext context, MountainSortOption option) {
    onSortSelected(option);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNonDefault = currentSort != MountainSortService.defaultSort;

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
                    const Icon(
                      Icons.swap_vert_rounded,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Urutkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    if (isNonDefault) ...[
                      GestureDetector(
                        key: const Key('sort_reset_button'),
                        onTap: () => _handleSelect(
                          context,
                          MountainSortService.defaultSort,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
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

              // Opsi pengurutan
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTile(
                        context: context,
                        label: 'Elevasi Tertinggi',
                        option: MountainSortOption.elevationDesc,
                        icon: Icons.filter_hdr_rounded,
                      ),
                      _buildTile(
                        context: context,
                        label: 'Elevasi Terendah',
                        option: MountainSortOption.elevationAsc,
                        icon: Icons.terrain_rounded,
                      ),
                      _buildTile(
                        context: context,
                        label: 'Nama Gunung (A - Z)',
                        option: MountainSortOption.alphabeticalAsc,
                        icon: Icons.sort_by_alpha_rounded,
                      ),
                      _buildTile(
                        context: context,
                        label: 'Nama Gunung (Z - A)',
                        option: MountainSortOption.alphabeticalDesc,
                        icon: Icons.sort_by_alpha_rounded,
                      ),
                      _buildTile(
                        context: context,
                        label: 'Estimasi Waktu Tercepat',
                        option: MountainSortOption.timeAsc,
                        icon: Icons.timer_outlined,
                      ),
                      _buildTile(
                        context: context,
                        label: 'Estimasi Waktu Terlama',
                        option: MountainSortOption.timeDesc,
                        icon: Icons.hourglass_bottom_rounded,
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

  Widget _buildTile({
    required BuildContext context,
    required String label,
    required MountainSortOption option,
    required IconData icon,
  }) {
    final isSelected = currentSort == option;

    return Material(
      color: isSelected
          ? AppTheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        key: Key('sort_option_${option.name}'),
        onTap: () => _handleSelect(context, option),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
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
