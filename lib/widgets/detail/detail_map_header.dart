import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mendaki/core/services/gpx_parser_service.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/waypoint.dart';
import 'package:mendaki/widgets/map/map_attribution_badge.dart';
import 'package:mendaki/widgets/navigation/navigation_markers.dart';

class DetailMapHeader extends StatefulWidget {
  final Mountain mountain;
  final VoidCallback? onBack;
  final VoidCallback? onDownloadTap;
  final bool isOfflineReady;
  final bool isDownloading;
  final double? downloadProgress;

  const DetailMapHeader({
    super.key,
    required this.mountain,
    this.onBack,
    this.onDownloadTap,
    this.isOfflineReady = false,
    this.isDownloading = false,
    this.downloadProgress,
  });

  @override
  State<DetailMapHeader> createState() => _DetailMapHeaderState();
}

class _DetailMapHeaderState extends State<DetailMapHeader> {
  final MapController _mapController = MapController();
  List<Polyline> _polylines = [];
  List<Marker> _markers = [];
  late LatLng _mapCenter;
  bool _isMapExpanded = false;
  GpxData? _gpxData;
  Waypoint? _selectedWaypoint;

  @override
  void initState() {
    super.initState();
    _initCoordinates();
    _loadGpxData();
  }

  @override
  void didUpdateWidget(covariant DetailMapHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mountain.id != widget.mountain.id) {
      _initCoordinates();
      _loadGpxData();
    }
  }

  void _initCoordinates() {
    _mapCenter = LatLng(
      widget.mountain.latitude ?? -2.5489,
      widget.mountain.longitude ?? 118.0149,
    );
  }

  Future<void> _loadGpxData() async {
    try {
      GpxData? gpxData;

      // 1. Tampilkan file GPX lokal dari penyimpanan terlebih dahulu (instan offline cache)
      final localFile = await GpxStorageService.getLocalGpxFile(
        widget.mountain.id,
      );
      if (localFile != null && await localFile.exists()) {
        gpxData = await GpxParserService.parseFile(localFile);
      }

      // Jika data lokal tersedia, langsung render agar pengguna tidak menunggu
      if (gpxData != null && mounted) {
        _buildMapElements(gpxData);
      }

      // 2. Jalankan sinkronisasi background via HTTP HEAD ETag (Stale-While-Revalidate)
      _syncGpxInBackground(hasExistingData: gpxData != null);
    } catch (e) {
      debugPrint('Error loading GPX for hero header map: $e');
    }
  }

  Future<void> _syncGpxInBackground({required bool hasExistingData}) async {
    try {
      final updatedFile = await GpxStorageService.checkAndSyncGpx(
        mountainId: widget.mountain.id,
      );

      // Jika ada versi baru yang diunduh dari Supabase
      if (updatedFile != null && mounted) {
        await GpxStorageService.saveDownloadedMountain(widget.mountain);
        final newGpxData = await GpxParserService.parseFile(updatedFile);
        if (!mounted) return;
        _buildMapElements(newGpxData);
      }
    } catch (e) {
      debugPrint('Error syncing GPX in background: $e');
    }
  }

  void _buildMapElements(GpxData gpxData) {
    _gpxData = gpxData;

    final polylines = <Polyline>[];
    final allPoints = <LatLng>[];

    // Warna seragam untuk seluruh polyline jalur
    const polylineColor = Color(0xFF0F5238);

    for (final track in gpxData.tracks) {
      final points = track.trackPoints
          .map((pt) => LatLng(pt.latitude, pt.longitude))
          .toList();

      if (points.isNotEmpty) {
        allPoints.addAll(points);

        // Background polyline (border putih kontras tinggi)
        polylines.add(
          Polyline(
            points: points,
            strokeWidth: 5.5,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        );

        // Foreground polyline (warna seragam)
        polylines.add(
          Polyline(points: points, strokeWidth: 3.5, color: polylineColor),
        );
      }
    }

    // Set Map Center ke rata-rata koordinat jalur atau koordinat gunung
    LatLng calculatedCenter = _mapCenter;
    if (allPoints.isNotEmpty) {
      double totalLat = 0;
      double totalLng = 0;
      for (final p in allPoints) {
        totalLat += p.latitude;
        totalLng += p.longitude;
      }
      calculatedCenter = LatLng(
        totalLat / allPoints.length,
        totalLng / allPoints.length,
      );
    } else if (gpxData.waypoints.isNotEmpty) {
      calculatedCenter = LatLng(
        gpxData.waypoints.first.latitude,
        gpxData.waypoints.first.longitude,
      );
    }

    if (mounted) {
      setState(() {
        _polylines = polylines;
        _mapCenter = calculatedCenter;
        _rebuildMarkers();
      });
      try {
        _mapController.move(_mapCenter, 12.2);
      } catch (_) {}
    } else {
      _polylines = polylines;
      _mapCenter = calculatedCenter;
      _rebuildMarkers();
    }
  }

  void _onWaypointTap(Waypoint wpt) {
    setState(() {
      if (_selectedWaypoint == wpt) {
        _selectedWaypoint = null;
      } else {
        _selectedWaypoint = wpt;
      }
      _rebuildMarkers();
    });
  }

  bool _isSummit(Waypoint wpt) {
    final comment = (wpt.comment ?? '').trim().toLowerCase();
    final type = wpt.type.toLowerCase();
    final name = wpt.name.toLowerCase();
    return comment == 'summit' ||
        comment.contains('summit') ||
        type == 'summit' ||
        name.contains('puncak') ||
        name.contains('summit') ||
        name.contains('peak');
  }

  bool _isBasecamp(Waypoint wpt) {
    final comment = (wpt.comment ?? '').trim().toLowerCase();
    final type = wpt.type.toLowerCase();
    final name = wpt.name.toLowerCase();
    final isGate = name.contains('pintu rimba') || name.contains('gerbang');
    if (isGate) return false;

    return comment == 'basecamp' ||
        comment.contains('basecamp') ||
        type == 'basecamp' ||
        name.contains('basecamp') ||
        widget.mountain.routes.any(
          (r) =>
              r.basecampName.toLowerCase() == name ||
              (r.basecampName.toLowerCase().isNotEmpty &&
                  name.contains(r.basecampName.toLowerCase())),
        );
  }

  bool _isCamp(Waypoint wpt) {
    final comment = (wpt.comment ?? '').trim().toLowerCase();
    final type = wpt.type.toLowerCase();
    final name = wpt.name.toLowerCase();
    return comment == 'camp' ||
        comment.contains('camp') ||
        type == 'camp' ||
        name.contains('camp') ||
        name.contains('camping') ||
        wpt.isCamp;
  }

  void _rebuildMarkers() {
    if (_gpxData == null) return;

    final regularMarkers = <Marker>[];
    final campMarkers = <Marker>[];
    final summitMarkers = <Marker>[];
    final basecampMarkers = <Marker>[];
    Marker? selectedMarker;

    for (final wpt in _gpxData!.waypoints) {
      final isSelected = _selectedWaypoint == wpt;
      final isSummit = _isSummit(wpt);
      final isBasecamp = !isSummit && _isBasecamp(wpt);
      final isCamp = !isSummit && !isBasecamp && _isCamp(wpt);

      final marker = buildWaypointMapMarker(
        waypoint: wpt,
        isSelected: isSelected,
        isSummit: isSummit,
        isBasecamp: isBasecamp,
        isCamp: isCamp,
        showCampLabel: false,
        rotate: false,
        onTap: () => _onWaypointTap(wpt),
      );

      if (isSelected) {
        selectedMarker = marker;
      } else if (isBasecamp) {
        basecampMarkers.add(marker);
      } else if (isSummit) {
        summitMarkers.add(marker);
      } else if (isCamp) {
        campMarkers.add(marker);
      } else {
        regularMarkers.add(marker);
      }
    }

    // Urutan z-index dari belakang ke depan:
    // 1. Waypoint biasa (di belakang)
    // 2. Camp / Tenda markers
    // 3. Summit markers
    // 4. Basecamp markers (selalu di depan waypoint biasa agar labelnya tidak tertimpa)
    // 5. Marker yang sedang aktif/dipilih (z-index paling depan)
    final markers = <Marker>[
      ...regularMarkers,
      ...campMarkers,
      ...summitMarkers,
      ...basecampMarkers,
    ];

    if (selectedMarker != null) {
      markers.add(selectedMarker);
    }

    _markers = markers;
  }

  void _setMapExpanded(bool expanded) {
    if (_isMapExpanded == expanded) return;
    setState(() {
      _isMapExpanded = expanded;
    });
    _mapController.move(_mapCenter, 12.2);
    // Setelah animasi ekspansi (350ms) selesai, trigger move kembali agar center viewport akurat
    Future.delayed(const Duration(milliseconds: 360), () {
      if (mounted) {
        _mapController.move(_mapCenter, 12.2);
      }
    });
  }

  LatLngBounds _calculateBounds() {
    // 15 km buffer ≈ 0.135 derajat
    const buffer = 0.135;
    double minLat = _mapCenter.latitude;
    double maxLat = _mapCenter.latitude;
    double minLng = _mapCenter.longitude;
    double maxLng = _mapCenter.longitude;

    if (_gpxData != null) {
      for (final track in _gpxData!.tracks) {
        for (final pt in track.trackPoints) {
          if (pt.latitude < minLat) minLat = pt.latitude;
          if (pt.latitude > maxLat) maxLat = pt.latitude;
          if (pt.longitude < minLng) minLng = pt.longitude;
          if (pt.longitude > maxLng) maxLng = pt.longitude;
        }
      }
    }

    return LatLngBounds(
      LatLng(minLat - buffer, minLng - buffer),
      LatLng(maxLat + buffer, maxLng + buffer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final collapsedHeight = 380.0 + topPadding;
    final expandedHeight = (screenHeight * 0.78).clamp(540.0, 750.0);
    final totalHeight = _isMapExpanded ? expandedHeight : collapsedHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Interactive Topo / OSM Map with GPX Polyline (Fullscreen under status bar)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 12.0,
              minZoom: 12.0,
              maxZoom: 16.5,
              cameraConstraint: CameraConstraint.containCenter(
                bounds: _calculateBounds(),
              ),
              onTap: (tapPosition, point) {
                if (_selectedWaypoint != null) {
                  setState(() {
                    _selectedWaypoint = null;
                    _rebuildMarkers();
                  });
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'ayo.mendaki.bersama',
                maxNativeZoom: 17,
                maxZoom: 18,
              ),
              if (_polylines.isNotEmpty) PolylineLayer(polylines: _polylines),
              if (_markers.isNotEmpty) MarkerLayer(markers: _markers),
            ],
          ),

          // Bottom Vignette Gradient for Title & Elevation legibility
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 80,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Top Navigation Bar (Back Button + Recenter)
          Positioned(
            top: topPadding + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                // Circular Frosted Back Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap:
                        widget.onBack ?? () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const Spacer(),

                // Recenter Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _mapController.move(_mapCenter, 12.2);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            color: Color(0xFF89EDBA),
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Pusatkan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Expand / Collapse Map Toggle Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _setMapExpanded(!_isMapExpanded),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isMapExpanded
                                ? Icons.close_fullscreen_rounded
                                : Icons.open_in_full_rounded,
                            color: const Color(0xFF89EDBA),
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isMapExpanded ? 'Perkecil' : 'Perbesar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (widget.isOfflineReady) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0F5238,
                          ).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFF89EDBA,
                            ).withValues(alpha: 0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF89EDBA),
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Offline',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Map Attribution Badge (Kanan Atas, persis di bawah tombol aksi Pusatkan & Perbesar)
          Positioned(
            top: topPadding + 48,
            right: 12,
            child: const MapAttributionBadge(),
          ),

          // Bottom Content Overlay (Swipe Up to Expand, Swipe Down to Collapse)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity;
                if (velocity != null) {
                  if (velocity < -80) {
                    // Swipe UP -> Peta Membesar!
                    _setMapExpanded(true);
                  } else if (velocity > 80) {
                    // Swipe DOWN -> Peta Kembali Normal
                    _setMapExpanded(false);
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mountain Name & Elevation Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            widget.mountain.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0F5238,
                            ).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(
                                0xFF89EDBA,
                              ).withValues(alpha: 0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${widget.mountain.elevation}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Mdpl',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Indikator Drag/Swipe Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
