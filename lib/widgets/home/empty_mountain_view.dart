import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';

class EmptyMountainView extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final Widget? action;

  const EmptyMountainView({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
        child: Column(
          children: [
            Icon(
              icon ?? Icons.terrain_rounded,
              size: 56,
              color: AppTheme.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              title ?? 'Tidak ada data gunung',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message ?? 'Tarik ke bawah untuk memuat ulang data.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.outline),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
