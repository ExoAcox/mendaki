import 'package:flutter/material.dart';
import 'package:mendaki/core/services/view_preference_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';

/// Reusable toggle button untuk berganti tampilan antara mode 'Detail' dan 'Simple' (Compact)
class ViewModeToggle extends StatelessWidget {
  final String currentMode;
  final ValueChanged<String> onModeChanged;

  const ViewModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem(
            label: 'Detail',
            icon: Icons.web,
            mode: ViewPreferenceService.viewModeDetail,
          ),
          _buildToggleItem(
            label: 'Simple',
            icon: Icons.format_list_bulleted,
            mode: ViewPreferenceService.viewModeCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required IconData icon,
    required String mode,
  }) {
    final isSelected = currentMode == mode;

    return GestureDetector(
      key: Key('toggle_mode_${label.toLowerCase()}'),
      onTap: () {
        if (!isSelected) {
          onModeChanged(mode);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        width: 32,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected
              ? AppTheme.primary
              : AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
