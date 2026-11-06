import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';

class NavigationFloatingButton extends StatelessWidget {
  final IconData? icon;
  final Widget? customChild;
  final Color? color;
  final VoidCallback onTap;

  const NavigationFloatingButton({
    super.key,
    this.icon,
    this.customChild,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child:
                customChild ??
                Icon(icon, color: color ?? AppTheme.onSurface, size: 22),
          ),
        ),
      ),
    );
  }
}

