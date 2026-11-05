import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';

class FinishHikeDialog extends StatelessWidget {
  final Mountain mountain;
  final HikingRoute? route;
  final Duration elapsed;
  final VoidCallback onFinish;

  const FinishHikeDialog({
    super.key,
    required this.mountain,
    this.route,
    required this.elapsed,
    required this.onFinish,
  });

  static Future<void> show(
    BuildContext context, {
    required Mountain mountain,
    HikingRoute? route,
    required Duration elapsed,
    required VoidCallback onFinish,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => FinishHikeDialog(
        mountain: mountain,
        route: route,
        elapsed: elapsed,
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.surfaceContainerLowest,
      title: const Row(
        children: [
          Icon(Icons.flag_rounded, color: AppTheme.primary),
          SizedBox(width: 8),
          Text(
            'Selesaikan Pendakian?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apakah Anda ingin mengakhiri sesi pendakian di ${mountain.name}?',
            style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'WAKTU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatStopwatch(elapsed),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'JARAK RUTE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${route?.distanceKm.toStringAsFixed(1) ?? '6.0'} km',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal', style: TextStyle(color: AppTheme.outline)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onFinish();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}

