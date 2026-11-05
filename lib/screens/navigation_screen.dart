import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:mendaki/core/services/gpx_parser_service.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/offline_map_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';
import 'package:mendaki/models/waypoint.dart';
import 'package:mendaki/widgets/navigation/navigation_checking_view.dart';
import 'package:mendaki/widgets/navigation/navigation_far_view.dart';
import 'package:mendaki/widgets/navigation/navigation_gps_disabled_view.dart';
import 'package:mendaki/widgets/navigation/navigation_markers.dart';
import 'package:mendaki/widgets/navigation/navigation_offline_required_view.dart';
import 'package:mendaki/widgets/navigation/navigation_permission_view.dart';
import 'package:path_provider/path_provider.dart';

enum NavigationGpsStatus {
  checking,
  offlineRequired,
  gpsDisabled,
  permissionDenied,
  farFromMountain,
  ready,
}

class NavigationScreen extends StatefulWidget {
  final Mountain mountain;
  final HikingRoute? selectedRoute;
  final bool bypassGpsCheckForTesting;
  final NavigationGpsStatus? initialGpsStatus;
  final double? mockDistanceKm;

  const NavigationScreen({
    super.key,
    required this.mountain,
    this.selectedRoute,
    this.bypassGpsCheckForTesting = false,
    this.initialGpsStatus,
    this.mockDistanceKm,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Gatekeeper States
  late NavigationGpsStatus _gpsStatus;
  String _statusMessage = 'Memeriksa paket offline & GPS...';
  double? _distanceToMountainKm;
  LatLng? _mountainCenter;
  StreamSubscription<Position>? _positionStreamSub;
  StreamSubscription<MapEvent>? _mapEventSub;
  String? _offlineBasePath;

  // Offline Package Status
  bool _isGpxDownloaded = false;
  bool _isMapDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  // GPX Data, Polylines & Markers (Persis seperti DetailScreen)
  GpxData? _gpxData;
  List<Polyline> _polylines = [];
  List<Marker> _markers = [];
  Waypoint? _selectedWaypoint;

  // Pulse animation untuk radar GPS pin pengguna
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Lokasi Pendaki (Default di pusat gunung / basecamp, diupdate oleh GPS)
  LatLng _currentPosition = const LatLng(-7.4542, 110.4397);
  LatLng _mapCenter = const LatLng(-7.4542, 110.4397);
  double _currentRotation = 0.0;
  double? _userHeading;

  @override
  void initState() {
    super.initState();
    _mountainCenter = LatLng(
      widget.mountain.latitude ?? -7.4542,
      widget.mountain.longitude ?? 110.4397,
    );
    _mapCenter = _mountainCenter!;
    _currentPosition = _mountainCenter!;

    _initPulseAnimation();
    _initBasePath();

    _mapEventSub = _mapController.mapEventStream.listen((event) {
      if (mounted && event.camera.rotation != _currentRotation) {
        setState(() {
          _currentRotation = event.camera.rotation;
        });
      }
    });

    if (widget.initialGpsStatus != null) {
      _gpsStatus = widget.initialGpsStatus!;
      _distanceToMountainKm = widget.mockDistanceKm ?? 45.2;
      if (_gpsStatus == NavigationGpsStatus.ready) {
        _loadGpxData();
      }
    } else if (widget.bypassGpsCheckForTesting) {
      _gpsStatus = NavigationGpsStatus.ready;
      _distanceToMountainKm = 0.5;
      _loadGpxData();
    } else {
      _gpsStatus = NavigationGpsStatus.checking;
      _checkOfflineAndGps();
    }
  }

  Future<void> _initBasePath() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      if (mounted) {
        setState(() {
          _offlineBasePath = appDir.path;
        });
      }
    } catch (_) {}
  }

  void _initPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  /// Memeriksa apakah GPX dan Peta Offline sudah terunduh sebelum verifikasi GPS
  Future<void> _checkOfflineAndGps() async {
    if (widget.bypassGpsCheckForTesting) {
      if (mounted) {
        setState(() {
          _gpsStatus = NavigationGpsStatus.ready;
        });
        _loadGpxData();
      }
      return;
    }

    setState(() {
      _gpsStatus = NavigationGpsStatus.checking;
      _statusMessage = 'Memeriksa paket offline GPX & peta...';
    });

    try {
      final isGpx = await GpxStorageService.isGpxDownloaded(widget.mountain.id);
      final isMap = await OfflineMapService.isOfflineMapDownloaded(
        widget.mountain.id,
      );

      _isGpxDownloaded = isGpx;
      _isMapDownloaded = isMap;

      if (!isGpx || !isMap) {
        if (mounted) {
          setState(() {
            _gpsStatus = NavigationGpsStatus.offlineRequired;
          });
        }
        return;
      }

      await _checkGpsAndProximity();
    } catch (e) {
      debugPrint('Error memeriksa paket offline: $e');
      if (mounted) {
        setState(() {
          _gpsStatus = NavigationGpsStatus.offlineRequired;
        });
      }
    }
  }

  /// Mengunduh file GPX dan seluruh paket ubin peta offline
  Future<void> _downloadOfflinePackage() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await GpxStorageService.downloadAndSaveGpx(
        mountainId: widget.mountain.id,
      );
      _isGpxDownloaded = true;

      final gpxFile = await GpxStorageService.getLocalGpxFile(
        widget.mountain.id,
      );
      List<LatLng>? trackPoints;
      if (gpxFile != null) {
        final parsed = await GpxParserService.parseFile(gpxFile);
        if (parsed.tracks.isNotEmpty) {
          trackPoints = parsed.tracks
              .expand((t) => t.trackPoints)
              .map((pt) => LatLng(pt.latitude, pt.longitude))
              .toList();
        }
      }

      await OfflineMapService.downloadOfflineMap(
        mountainId: widget.mountain.id,
        centerLat: widget.mountain.latitude ?? -7.4542,
        centerLng: widget.mountain.longitude ?? 110.4397,
        trackPoints: trackPoints,
        minZoom: 11,
        maxZoom: 15,
        onProgress: (downloaded, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = total > 0 ? (downloaded / total) : 0.0;
            });
          }
        },
      );
      _isMapDownloaded = true;

      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        await _checkGpsAndProximity();
      }
    } catch (e) {
      debugPrint('Error mengunduh paket offline: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh paket offline: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Verifikasi GPS dan jarak user ke gunung sebelum memuat peta
  Future<void> _checkGpsAndProximity() async {
    if (widget.bypassGpsCheckForTesting) {
      if (mounted) {
        setState(() {
          _gpsStatus = NavigationGpsStatus.ready;
        });
        _loadGpxData();
      }
      return;
    }

    setState(() {
      _gpsStatus = NavigationGpsStatus.checking;
      _statusMessage = 'Memeriksa keaktifan GPS perangkat...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _gpsStatus = NavigationGpsStatus.gpsDisabled;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _gpsStatus = NavigationGpsStatus.permissionDenied;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _gpsStatus = NavigationGpsStatus.permissionDenied;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _statusMessage = 'Mendapatkan titik koordinat lokasi GPS Anda...';
        });
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final userLoc = LatLng(pos.latitude, pos.longitude);
      final center =
          _mountainCenter ??
          LatLng(
            widget.mountain.latitude ?? -7.4542,
            widget.mountain.longitude ?? 110.4397,
          );

      final distMeters = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        center.latitude,
        center.longitude,
      );
      final distKm = distMeters / 1000.0;

      if (mounted) {
        _distanceToMountainKm = distKm;
        _currentPosition = userLoc;
        if (pos.heading >= 0) {
          _userHeading = pos.heading;
        }

        if (distKm > 15.0) {
          setState(() {
            _gpsStatus = NavigationGpsStatus.farFromMountain;
          });
        } else {
          setState(() {
            _gpsStatus = NavigationGpsStatus.ready;
          });
          _loadGpxData();
          _startLocationStream();
        }
      }
    } catch (e) {
      debugPrint('Error pengecekan GPS: $e');
      if (mounted) {
        setState(() {
          _gpsStatus = NavigationGpsStatus.farFromMountain;
          _distanceToMountainKm = _distanceToMountainKm ?? 999.0;
        });
      }
    }
  }

  void _startLocationStream() {
    _positionStreamSub?.cancel();
    _positionStreamSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          if (mounted) {
            setState(() {
              _currentPosition = LatLng(pos.latitude, pos.longitude);
              if (pos.heading >= 0) {
                _userHeading = pos.heading;
              }
              if (_mountainCenter != null) {
                final dMeters = Geolocator.distanceBetween(
                  pos.latitude,
                  pos.longitude,
                  _mountainCenter!.latitude,
                  _mountainCenter!.longitude,
                );
                _distanceToMountainKm = dMeters / 1000.0;
              }
              _rebuildMarkers();
            });
          }
        }, onError: (err) => debugPrint('Error GPS stream: $err'));
  }

  /// Memuat GPX dan menyusun polyline & marker dengan gaya yang persis sama seperti DetailScreen
  Future<void> _loadGpxData() async {
    try {
      GpxData? parsed;

      final localFile = await GpxStorageService.getLocalGpxFile(
        widget.mountain.id,
      );
      if (localFile != null && await localFile.exists()) {
        parsed = await GpxParserService.parseFile(localFile);
      }

      if (parsed != null) {
        _buildMapElements(parsed);
      }
    } catch (e) {
      debugPrint('Error loading GPX in NavigationScreen: $e');
    }
  }

  void _buildMapElements(GpxData gpxData) {
    _gpxData = gpxData;

    final polylines = <Polyline>[];
    final allPoints = <LatLng>[];

    // Warna seragam hijau rimba gelap (sama persis dengan DetailScreen)
    const polylineColor = Color(0xFF0F5238);

    for (final track in gpxData.tracks) {
      final points = track.trackPoints
          .map((pt) => LatLng(pt.latitude, pt.longitude))
          .toList();

      if (points.isNotEmpty) {
        allPoints.addAll(points);

        // 1. Background polyline (border putih kontras tinggi)
        polylines.add(
          Polyline(
            points: points,
            strokeWidth: 5.5,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        );

        // 2. Foreground polyline (warna seragam)
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusGpsWithSummitUp(zoom: 15.8);
      });
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

  LatLng _getSummitCoordinate() {
    if (_gpxData != null) {
      for (final wpt in _gpxData!.waypoints) {
        if (_isSummit(wpt)) {
          return LatLng(wpt.latitude, wpt.longitude);
        }
      }
      Waypoint? highest;
      for (final wpt in _gpxData!.waypoints) {
        if (wpt.elevation != null) {
          if (highest == null || wpt.elevation! > (highest.elevation ?? 0)) {
            highest = wpt;
          }
        }
      }
      if (highest != null) {
        return LatLng(highest.latitude, highest.longitude);
      }
    }
    return _mountainCenter ??
        LatLng(
          widget.mountain.latitude ?? -7.4542,
          widget.mountain.longitude ?? 110.4397,
        );
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final double lat1 = from.latitude * (math.pi / 180.0);
    final double lon1 = from.longitude * (math.pi / 180.0);
    final double lat2 = to.latitude * (math.pi / 180.0);
    final double lon2 = to.longitude * (math.pi / 180.0);

    final double dLon = lon2 - lon1;

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final double bearingRad = math.atan2(y, x);
    final double bearingDeg = (bearingRad * (180.0 / math.pi) + 360.0) % 360.0;
    return bearingDeg;
  }

  double _calculateSummitUpRotation() {
    final summitCoord = _getSummitCoordinate();
    final bearing = _calculateBearing(_currentPosition, summitCoord);
    return (360.0 - bearing) % 360.0;
  }

  void _focusGpsWithSummitUp({double zoom = 15.8}) {
    final targetRotation = _calculateSummitUpRotation();
    if (mounted) {
      setState(() {
        _currentRotation = targetRotation;
      });
    }
    try {
      _mapController.moveAndRotate(_currentPosition, zoom, targetRotation);
    } catch (_) {
      try {
        _mapController.move(_currentPosition, zoom);
        _mapController.rotate(targetRotation);
      } catch (_) {}
    }
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
        showCampLabel: true,
        rotate: true,
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
    // 1. Waypoint biasa
    // 2. Camp / Tenda markers
    // 3. Summit markers
    // 4. Basecamp markers
    // 5. Selected marker
    // 6. User GPS marker (posisi pendaki paling depan)
    final markers = <Marker>[
      ...regularMarkers,
      ...campMarkers,
      ...summitMarkers,
      ...basecampMarkers,
    ];

    if (selectedMarker != null) {
      markers.add(selectedMarker);
    }

    // Pin Posisi GPS Pendaki (Live radar pulse) - rotate: false agar tetap menunjukkan arah hadap pendaki di peta
    markers.add(
      Marker(
        point: _currentPosition,
        width: 52,
        height: 52,
        rotate: false,
        child: NavigationUserMarker(
          pulseAnimation: _pulseAnimation,
          heading: _userHeading,
        ),
      ),
    );

    _markers = markers;
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _mapEventSub?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ==========================================
  // ROOT BUILD GATEKEEPER
  // ==========================================
  @override
  Widget build(BuildContext context) {
    switch (_gpsStatus) {
      case NavigationGpsStatus.checking:
        return NavigationCheckingView(
          mountain: widget.mountain,
          statusMessage: _statusMessage,
          onBack: () => Navigator.of(context).pop(),
        );
      case NavigationGpsStatus.offlineRequired:
        return NavigationOfflineRequiredView(
          mountain: widget.mountain,
          isGpxDownloaded: _isGpxDownloaded,
          isMapDownloaded: _isMapDownloaded,
          isDownloading: _isDownloading,
          downloadProgress: _downloadProgress,
          onDownload: _downloadOfflinePackage,
          onBack: () => Navigator.of(context).pop(),
        );
      case NavigationGpsStatus.gpsDisabled:
        return NavigationGpsDisabledView(
          mountain: widget.mountain,
          onRetry: _checkGpsAndProximity,
          onBack: () => Navigator.of(context).pop(),
        );
      case NavigationGpsStatus.permissionDenied:
        return NavigationPermissionView(
          mountain: widget.mountain,
          onRetry: _checkGpsAndProximity,
          onBack: () => Navigator.of(context).pop(),
        );
      case NavigationGpsStatus.farFromMountain:
        return NavigationFarView(
          mountain: widget.mountain,
          distanceToMountainKm: _distanceToMountainKm,
          onRetry: _checkGpsAndProximity,
          onBack: () => Navigator.of(context).pop(),
        );
      case NavigationGpsStatus.ready:
        return _buildNavigationMapScreen(context);
    }
  }

  // ==========================================
  // CLEAN FULLSCREEN MAP SCREEN
  // ==========================================
  Widget _buildNavigationMapScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Clean Fullscreen Interactive Map Viewport (Identik dengan DetailScreen)
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 15.8,
                initialRotation: _calculateSummitUpRotation(),
                minZoom: 10.0,
                maxZoom: 18.0,
                onTap: (tapPosition, point) {
                  if (_selectedWaypoint != null) {
                    setState(() {
                      _selectedWaypoint = null;
                      _rebuildMarkers();
                    });
                  }
                },
                onPositionChanged: (camera, hasGesture) {
                  if (camera.rotation != _currentRotation) {
                    setState(() {
                      _currentRotation = camera.rotation;
                    });
                  }
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
                  tileProvider: _offlineBasePath != null
                      ? OfflineFirstTileProvider(
                          mountainId: widget.mountain.id,
                          offlineBasePath: _offlineBasePath!,
                        )
                      : null,
                  userAgentPackageName: 'ayo.mendaki.bersama',
                  maxNativeZoom: 16,
                  maxZoom: 18,
                ),
                if (_polylines.isNotEmpty) PolylineLayer(polylines: _polylines),
                if (_markers.isNotEmpty)
                  MarkerLayer(rotate: true, markers: _markers),
              ],
            ),
          ),

          // 2. Minimal Floating Back Button (Pojok Kiri Atas)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _buildFloatingButton(
              icon: Icons.arrow_back_rounded,
              color: AppTheme.onSurface,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          // 3. Floating Compass & Find Me Buttons (Pojok Kanan Atas)
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating Compass Button (Jarum merah 'N' selalu menunjuk ke arah Utara sebenarnya)
                _buildFloatingButton(
                  customChild: CompassNeedle(rotationDegrees: _currentRotation),
                  onTap: () {
                    setState(() {
                      _currentRotation = 0.0;
                    });
                    _mapController.rotate(0.0);
                  },
                ),
                const SizedBox(height: 10),
                // Floating Find Me Button (Fokus ke lokasi pendaki dengan arah puncak ke atas)
                _buildFloatingButton(
                  icon: Icons.my_location_rounded,
                  color: AppTheme.primary,
                  onTap: () {
                    _focusGpsWithSummitUp(zoom: 15.8);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    IconData? icon,
    Widget? customChild,
    Color? color,
    required VoidCallback onTap,
  }) {
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
