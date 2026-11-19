import 'dart:ui';
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
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: AppTheme.primary.withValues(alpha: 0.12),
              highlightColor: Colors.transparent,
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0.58),
                      Colors.white.withValues(alpha: 0.72),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child:
                      customChild ??
                      Icon(icon, color: color ?? AppTheme.onSurface, size: 22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

