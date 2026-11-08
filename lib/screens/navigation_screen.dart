import 'dart:async';
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
import 'package:mendaki/widgets/navigation/navigation_finish_dialog.dart';
import 'package:mendaki/widgets/navigation/navigation_geo_utils.dart';
import 'package:mendaki/widgets/navigation/navigation_layer_builder.dart';
import 'package:mendaki/widgets/navigation/navigation_map_viewport.dart';
import 'package:mendaki/widgets/navigation/navigation_overlay_controls.dart';
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
    _polylines = [
      ..._baseGpxPolylines,
      ...NavigationLayerBuilder.buildBreadcrumbPolylines(_breadcrumbPath),
    ];
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
    final polylines = NavigationLayerBuilder.buildGpxPolylines(gpxData);

    final allPoints = <LatLng>[];
    for (final track in gpxData.tracks) {
      allPoints.addAll(
        track.trackPoints.map((pt) => LatLng(pt.latitude, pt.longitude)),
      );
    }

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

  void _focusGpsWithSummitUp({double zoom = 15.8}) {
    final summitCoord = NavigationGeoUtils.findSummitCoordinate(
      _gpxData,
      _mountainCenter ?? _currentPosition,
    );
    final targetRotation = NavigationGeoUtils.calculateSummitUpRotation(
      _currentPosition,
      summitCoord,
    );
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
    _markers = NavigationLayerBuilder.buildNavigationMarkers(
      gpxData: _gpxData,
      selectedWaypoint: _selectedWaypoint,
      hasUserPosition: _hasUserPosition,
      currentPosition: _currentPosition,
      pulseAnimation: _pulseAnimation,
      userHeading: _userHeading,
      onWaypointTap: _onWaypointTap,
    );
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
    NavigationFinishDialog.show(
      context,
      mountain: widget.mountain,
      route: widget.selectedRoute,
      distanceTraveledKm: NavigationGeoUtils.calculatePathDistanceKm(
        _breadcrumbPath,
      ),
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
                    : NavigationGeoUtils.calculateSummitUpRotation(
                        _currentPosition,
                        NavigationGeoUtils.findSummitCoordinate(
                          _gpxData,
                          _mountainCenter ?? _currentPosition,
                        ),
                      ),
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

            // 2. Overlay Controls & Metrics (Atribusi, Far Notice, Metrics Chip, Finish Button, Floating Controls)
            NavigationOverlayControls(
              isFarFromMountain: _isFarFromMountain,
              distanceToMountainKm: _distanceToMountainKm,
              elapsedDuration: _elapsedDuration,
              currentAltitude: _currentAltitude,
              distanceTraveledKm: NavigationGeoUtils.calculatePathDistanceKm(
                _breadcrumbPath,
              ),
              currentRotation: _currentRotation,
              onFinishTap: _showFinishConfirmationDialog,
              onCompassTap: () {
                setState(() {
                  _currentRotation = 0.0;
                });
                _mapController.rotate(0.0);
              },
              onFindMeTap: _handleFindMeTap,
            ),
          ],
        ),
      ),
    );
  }
}
