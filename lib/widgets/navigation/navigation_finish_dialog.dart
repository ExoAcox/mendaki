import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';

class NavigationFinishDialog extends StatelessWidget {
  final Mountain mountain;
  final HikingRoute? route;
  final Duration elapsed;
  final double? distanceTraveledKm;
  final VoidCallback onFinish;

  const NavigationFinishDialog({
    super.key,
    required this.mountain,
    this.route,
    required this.elapsed,
    this.distanceTraveledKm,
    required this.onFinish,
  });

  static Future<void> show(
    BuildContext context, {
    required Mountain mountain,
    HikingRoute? route,
    required Duration elapsed,
    double? distanceTraveledKm,
    required VoidCallback onFinish,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => NavigationFinishDialog(
        mountain: mountain,
        route: route,
        elapsed: elapsed,
        distanceTraveledKm: distanceTraveledKm,
        onFinish: onFinish,
      ),
    );
  }

  String _formatStopwatch(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.60),
                    Colors.white.withValues(alpha: 0.78),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFDC2626,
                          ).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFDC2626,
                            ).withValues(alpha: 0.20),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Selesaikan Navigasi?',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Apakah Anda yakin ingin menyelesaikan sesi navigasi di ${mountain.name}?',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'WAKTU DILALUI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.outline,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatStopwatch(elapsed),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        if (distanceTraveledKm != null || route != null) ...[
                          Container(
                            width: 1,
                            height: 28,
                            color: AppTheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          Column(
                            children: [
                              const Text(
                                'JARAK DITEMPUH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.outline,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDistance(
                                  distanceTraveledKm ??
                                      route?.distanceKm ??
                                      0.0,
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.35,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.7),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFDC2626,
                                ).withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  onFinish();
                                },
                                splashColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.90),
                                        const Color(
                                          0xFFDC2626,
                                        ).withValues(alpha: 0.85),
                                        const Color(
                                          0xFFB91C1C,
                                        ).withValues(alpha: 0.90),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 1.2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Selesai',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef FinishHikeDialog = NavigationFinishDialog;
