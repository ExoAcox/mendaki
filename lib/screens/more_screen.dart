import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/widgets/home/home_app_bar.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const HomeAppBar(),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  size: 36,
                  color: AppTheme.outline,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'More',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Halaman dalam pengembangan',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

