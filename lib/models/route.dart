import 'waypoint.dart';

class LatLngPoint {
  final double latitude;
  final double longitude;
  final double? elevation;

  const LatLngPoint({
    required this.latitude,
    required this.longitude,
    this.elevation,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
    };
  }

  factory LatLngPoint.fromJson(Map<String, dynamic> json) {
    return LatLngPoint(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      elevation: (json['elevation'] as num?)?.toDouble(),
    );
  }
}

class HikingRoute {
  final String id;
  final String name;
  final String basecampName;
  final double distanceKm;
  final String estimatedDuration;
  final int elevationGainMeters;
  final String difficulty;
  final bool hasWater;
  final String? city;
  final List<String> igLinks;
  final List<Waypoint> waypoints;
  final List<LatLngPoint> trackPoints;

  /// Elevasi awal / basecamp awal rute (mdpl)
  int get startElevation => elevationGainMeters;
  int get basecampElevation => elevationGainMeters;
  int get elevation => elevationGainMeters;
  String get estimatedTime => estimatedDuration;

  String get difficultyText {
    final parsed = int.tryParse(difficulty);
    if (parsed != null) {
      switch (parsed) {
        case 1:
          return 'Sangat Mudah';
        case 2:
          return 'Mudah';
        case 3:
          return 'Sedang';
        case 4:
          return 'Sulit';
        case 5:
          return 'Sangat Sulit';
        default:
          return 'Sedang';
      }
    }
    return difficulty.isNotEmpty ? difficulty : 'Sedang';
  }

  const HikingRoute({
    required this.id,
    required this.name,
    required this.basecampName,
    required this.distanceKm,
    required this.estimatedDuration,
    required this.elevationGainMeters,
    required this.difficulty,
    this.hasWater = false,
    this.city,
    this.igLinks = const [],
    this.waypoints = const [],
    this.trackPoints = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'basecampName': basecampName,
      'distanceKm': distanceKm,
      'estimatedDuration': estimatedDuration,
      'elevationGainMeters': elevationGainMeters,
      'difficulty': difficulty,
      'hasWater': hasWater,
      'city': city,
      'igLinks': igLinks,
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
      'trackPoints': trackPoints.map((tp) => tp.toJson()).toList(),
    };
  }

  factory HikingRoute.fromJson(Map<String, dynamic> json) {
    return HikingRoute(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      basecampName: json['basecampName'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      estimatedDuration: json['estimatedDuration'] as String? ?? '',
      elevationGainMeters: (json['elevationGainMeters'] as num?)?.toInt() ?? 0,
      difficulty: json['difficulty']?.toString() ?? 'Sedang',
      hasWater: json['hasWater'] as bool? ?? false,
      city: json['city'] as String?,
      igLinks: ((json['igLinks'] ?? json['ig_link']) as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      waypoints: (json['waypoints'] as List<dynamic>?)
              ?.map((w) => Waypoint.fromJson(w as Map<String, dynamic>))
              .toList() ??
          const [],
      trackPoints: (json['trackPoints'] as List<dynamic>?)
              ?.map((tp) => LatLngPoint.fromJson(tp as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

