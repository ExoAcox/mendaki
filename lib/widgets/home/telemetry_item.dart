import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';

class TelemetryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const TelemetryItem({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color ?? AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}
