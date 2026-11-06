import 'package:flutter/material.dart';

class NavigationFarNotice extends StatelessWidget {
  final double? distanceKm;

  const NavigationFarNotice({super.key, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final text = distanceKm != null
        ? 'Lokasi Anda terlalu jauh (${distanceKm! >= 100 ? distanceKm!.toStringAsFixed(0) : distanceKm!.toStringAsFixed(1)} km)'
        : 'Lokasi Anda terlalu jauh';

    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFF8162).withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFF8162),
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
