import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';

class HomeFilterChips extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  const HomeFilterChips({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(filter),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.onSurface,
            ),
            color: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.primary;
              }
              if (states.contains(WidgetState.pressed)) {
                return AppTheme.primary.withValues(alpha: 0.15);
              }
              return AppTheme.surfaceContainer;
            }),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primary
                  : AppTheme.outlineVariant.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onSelected: (val) => onSelected(filter),
          );
        },
      ),
    );
  }
}
