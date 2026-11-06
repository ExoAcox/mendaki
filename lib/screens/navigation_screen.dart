import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:mendaki/core/services/gpx_parser_service.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/navigation_session_service.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/route.dart';
import 'package:mendaki/models/waypoint.dart';
import 'package:mendaki/widgets/navigation/finish_hike_dialog.dart';
import 'package:mendaki/widgets/navigation/navigation_far_notice.dart';
import 'package:mendaki/widgets/navigation/navigation_finish_button.dart';
import 'package:mendaki/widgets/navigation/navigation_floating_controls.dart';
import 'package:mendaki/widgets/navigation/navigation_map_viewport.dart';
import 'package:mendaki/widgets/navigation/navigation_markers.dart';
import 'package:path_provider/path_provider.dart';

class NavigationScreen extends StatefulWidget {
  final Mountain mountain;
  final HikingRoute? selectedRoute;
  final double? mockDistanceKm;
  final LatLng? mockUserLocation;
  final double? mockAltitude;
  final List<LatLng>? mockTraveledPath;
  final DateTime? initialStartTime;
  final List<LatLng>? initialTraveledPath;

  const NavigationScreen({
    super.key,
    required this.mountain,
    this.selectedRoute,
    this.mockDistanceKm,
    this.mockUserLocation,
    this.mockAltitude,
    this.mockTraveledPath,
    this.initialStartTime,
    this.initialTraveledPath,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final MapController _mapController = MapController();

  // Lokasi & Jarak ke Gunung
  double? _distanceToMountainKm;
  bool _isFarFromMountain = false;
  bool _hasUserPosition = false;
  LatLng? _mountainCenter;
  StreamSubscription<Position>? _positionStreamSub;
  StreamSubscription<MapEvent>? _mapEventSub;
  String? _offlineBasePath;

  // GPX Data, Polylines & Markers
  GpxData? _gpxData;
  List<Polyline> _baseGpxPolylines = [];
  List<Polyline> _polylines = [];
  final List<LatLng> _breadcrumbPath = [];
  List<Marker> _markers = [];
  Waypoint? _selectedWaypoint;

  // Pulse animation untuk radar GPS pin pengguna
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Lokasi Pendaki & Kamera
  late LatLng _currentPosition;
  late LatLng _mapCenter;
  double _currentRotation = 0.0;
  double? _userHeading;
  double? _currentAltitude;

  // Tracking Durasi Navigasi
  late final DateTime _startTime;
  Duration _elapsedDuration = Duration.zero;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentAltitude = widget.mockAltitude;
    if (widget.initialTraveledPath != null) {
      _breadcrumbPath.addAll(widget.initialTraveledPath!);
    }
    if (widget.mockTraveledPath != null) {
      _breadcrumbPath.addAll(widget.mockTraveledPath!);
    }
    _rebuildPolylines();
    _startTime = widget.initialStartTime ?? DateTime.now();
    _elapsedDuration = DateTime.now().difference(_startTime);
    _saveSession();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedDuration = DateTime.now().difference(_startTime);
        });
      }
    });

    _mountainCenter = LatLng(
      widget.mountain.latitude ?? -7.4542,
      widget.mountain.longitude ?? 110.4397,
    );
    _mapCenter = _mountainCenter!;
    _currentPosition = widget.mockUserLocation ?? _mountainCenter!;

    _initPulseAnimation();
    _initBasePath();

    _mapEventSub = _mapController.mapEventStream.listen((event) {
      if (mounted && event.camera.rotation != _currentRotation) {
        setState(() {
          _currentRotation = event.camera.rotation;
        });
      }
    });

    // Muat data GPX peta langsung tanpa gatekeeper
    _loadGpxData();

    // Inisialisasi pengecekan lokasi secara non-blocking di background
    if (widget.mockDistanceKm != null) {
      final distKm = widget.mockDistanceKm!;
      _distanceToMountainKm = distKm;
      _isFarFromMountain = distKm > 15.0;
      _hasUserPosition = true;
    } else {
      _initLocationInBackground();
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

  /// Pengecekan GPS di background tanpa memblokir tampilan peta
  Future<void> _initLocationInBackground() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _updateUserPosition(pos);
      _startLocationStream();
    } catch (e) {
      debugPrint('Info GPS background: $e');
    }
  }

  void _rebuildPolylines() {
    final combined = List<Polyline>.from(_baseGpxPolylines);

    if (_breadcrumbPath.length >= 2) {
      // 1. Background casing putih untuk trace path
      combined.add(
        Polyline(
          points: List<LatLng>.from(_breadcrumbPath),
          strokeWidth: 6.0,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      );

      // 2. Foreground trace path warna secondary Color(0xFFA33D23)
      combined.add(
        Polyline(
          points: List<LatLng>.from(_breadcrumbPath),
          strokeWidth: 4.0,
          color: const Color(0xFFA33D23),
        ),
      );
    }

    _polylines = combined;
  }

  void _updateUserPosition(Position pos) {
    if (!mounted) return;

    final userLoc = LatLng(pos.latitude, pos.longitude);
    final center = _mountainCenter ?? const LatLng(-7.4542, 110.4397);
    final distMeters = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      center.latitude,
      center.longitude,
    );
    final distKm = distMeters / 1000.0;
    final isFar = distKm > 15.0;

    // Rekam titik koordinat jejak langkah (breadcrumb trace path)
    if (_breadcrumbPath.isEmpty) {
      _breadcrumbPath.add(userLoc);
      _saveSession();
    } else {
      final last = _breadcrumbPath.last;
      final dist = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        userLoc.latitude,
        userLoc.longitude,
      );
      if (dist >= 3.0) {
        _breadcrumbPath.add(userLoc);
        _saveSession();
      }
    }

    setState(() {
      _currentPosition = userLoc;
      _distanceToMountainKm = distKm;
      _isFarFromMountain = isFar;
      _hasUserPosition = true;
      _currentAltitude = pos.altitude;
      if (pos.heading >= 0) {
        _userHeading = pos.heading;
      }
      _rebuildPolylines();
      _rebuildMarkers();
    });

    // Jika dekat gunung, arahkan kamera ke GPS user dengan summit-up.
    // Jika jauh dari gunung, jangan fokus ke marker GPS, tetap fokus di gunung.
    if (!isFar) {
      _focusGpsWithSummitUp(zoom: 15.8);
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
          _updateUserPosition(pos);
        }, onError: (err) => debugPrint('Error GPS stream: $err'));
  }

  /// Memuat GPX dan menyusun polyline & marker peta
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
        _baseGpxPolylines = polylines;
        _rebuildPolylines();
        _mapCenter = calculatedCenter;
        _rebuildMarkers();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Jika lokasi jauh dari gunung, tetap fokus di gunung
        if (_isFarFromMountain || !_hasUserPosition) {
          _focusMountain(zoom: 14.0);
        } else {
          _focusGpsWithSummitUp(zoom: 15.8);
        }
      });
    } else {
      _baseGpxPolylines = polylines;
      _rebuildPolylines();
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

  void _focusMountain({double zoom = 14.0}) {
    final targetCenter = _mapCenter;
    if (mounted) {
      setState(() {
        _currentRotation = 0.0;
      });
    }
    try {
      _mapController.moveAndRotate(targetCenter, zoom, 0.0);
    } catch (_) {
      try {
        _mapController.move(targetCenter, zoom);
        _mapController.rotate(0.0);
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

    final markers = <Marker>[
      ...regularMarkers,
      ...campMarkers,
      ...summitMarkers,
      ...basecampMarkers,
    ];

    if (selectedMarker != null) {
      markers.add(selectedMarker);
    }

    // Pin Posisi GPS Pendaki (Live radar pulse) jika posisi tersedia
    if (_hasUserPosition) {
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
    }

    _markers = markers;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _durationTimer?.cancel();
    _positionStreamSub?.cancel();
    _mapEventSub?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveSession();
    }
  }

  void _saveSession() {
    NavigationSessionService.saveActiveSession(
      ActiveNavigationSession(
        mountain: widget.mountain,
        selectedRoute: widget.selectedRoute,
        startTime: _startTime,
        traveledPath: _breadcrumbPath,
      ),
    );
  }

  void _finishNavigation() {
    NavigationSessionService.clearActiveSession();
    Navigator.of(context).pop();
  }

  void _showFinishConfirmationDialog() {
    FinishHikeDialog.show(
      context,
      mountain: widget.mountain,
      route: widget.selectedRoute,
      elapsed: _elapsedDuration,
      onFinish: _finishNavigation,
    );
  }

  void _handleFindMeTap() {
    if (_isFarFromMountain) {
      _focusMountain(zoom: 14.0);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _distanceToMountainKm != null
                ? 'Lokasi Anda terlalu jauh (${_distanceToMountainKm!.toStringAsFixed(1)} km dari gunung)'
                : 'Lokasi Anda terlalu jauh dari gunung',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      _focusGpsWithSummitUp(zoom: 15.8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showFinishConfirmationDialog();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Clean Fullscreen Interactive Map Viewport
            Positioned.fill(
              child: NavigationMapViewport(
                mapController: _mapController,
                initialCenter: _mapCenter,
                initialZoom: 14.0,
                initialRotation: _isFarFromMountain
                    ? 0.0
                    : _calculateSummitUpRotation(),
                offlineBasePath: _offlineBasePath,
                mountainId: widget.mountain.id,
                polylines: _polylines,
                markers: _markers,
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
              ),
            ),

            // Floating Far Notice jika jauh
            if (_isFarFromMountain)
              Positioned(
                top: MediaQuery.of(context).padding.top + 24,
                left: 16,
                right: 16,
                child: NavigationFarNotice(distanceKm: _distanceToMountainKm),
              ),

            // Kiri Bawah: Button Finish
            Positioned(
              left: 16,
              bottom: 16,
              child: NavigationFinishButton(
                onTap: _showFinishConfirmationDialog,
              ),
            ),

            // Kanan Bawah: Elapse Duration, Altitude, Compass, Find Me (dari bawah ke atas)
            Positioned(
              right: 16,
              bottom: 16,
              child: NavigationFloatingControls(
                currentRotation: _currentRotation,
                onCompassTap: () {
                  setState(() {
                    _currentRotation = 0.0;
                  });
                  _mapController.rotate(0.0);
                },
                onFindMeTap: _handleFindMeTap,
                elapsedDuration: _elapsedDuration,
                altitude: _currentAltitude,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
