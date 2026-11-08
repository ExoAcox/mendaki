import 'package:flutter/material.dart';
import 'package:mendaki/widgets/map/map_attribution_badge.dart';
import 'package:mendaki/widgets/navigation/navigation_far_notice.dart';
import 'package:mendaki/widgets/navigation/navigation_finish_button.dart';
import 'package:mendaki/widgets/navigation/navigation_floating_controls.dart';

/// Kumpulan layer widget overlay kontrol, tombol, status, dan metrik di atas peta navigasi
class NavigationOverlayControls extends StatelessWidget {
  final bool isFarFromMountain;
  final double? distanceToMountainKm;
  final Duration elapsedDuration;
  final double? currentAltitude;
  final double distanceTraveledKm;
  final double currentRotation;
  final VoidCallback onFinishTap;
  final VoidCallback onCompassTap;
  final VoidCallback onFindMeTap;

  const NavigationOverlayControls({
    super.key,
    required this.isFarFromMountain,
    this.distanceToMountainKm,
    required this.elapsedDuration,
    this.currentAltitude,
    required this.distanceTraveledKm,
    required this.currentRotation,
    required this.onFinishTap,
    required this.onCompassTap,
    required this.onFindMeTap,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Stack(
      children: [
        // 1. Floating Far Notice jika pengguna berada jauh dari lokasi gunung
        if (isFarFromMountain)
          Positioned(
            top: topPadding + 24,
            left: 16,
            right: 16,
            child: NavigationFarNotice(distanceKm: distanceToMountainKm),
          ),

        // 2. Atribusi Peta (Di Atas Kanan atau Tengah jika Far Notice aktif)
        Positioned(
          top: topPadding + (isFarFromMountain ? 76 : 12),
          left: 16,
          right: 16,
          child: Align(
            alignment: isFarFromMountain
                ? Alignment.topCenter
                : Alignment.topRight,
            child: const MapAttributionBadge(),
          ),
        ),

        // 3. Paling Bawah: Chip gabungan 3 Info Full Width (Elapsed Time, Altitude, Jarak yang dilalui)
        Positioned(
          left: 16,
          right: 16,
          bottom: bottomPadding + 16,
          child: NavigationMetricsChip(
            elapsedDuration: elapsedDuration,
            altitude: currentAltitude,
            distanceKm: distanceTraveledKm,
          ),
        ),

        // 4. Di Atas Chip - Sebelah Kiri: Tombol Selesai (Finish Navigation)
        Positioned(
          left: 16,
          bottom: bottomPadding + 68,
          child: NavigationFinishButton(onTap: onFinishTap),
        ),

        // 5. Di Atas Chip - Sebelah Kanan: Tombol Kompas & Find Me
        Positioned(
          right: 16,
          bottom: bottomPadding + 68,
          child: NavigationFloatingControls(
            currentRotation: currentRotation,
            onCompassTap: onCompassTap,
            onFindMeTap: onFindMeTap,
          ),
        ),
      ],
    );
  }
}

