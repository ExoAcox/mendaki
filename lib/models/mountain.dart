import 'route.dart';
import 'waypoint.dart';

class Mountain {
  final String id;
  final String name;
  final int elevation;
  final String location;
  final String province;
  final String difficulty;
  final String estimatedTime;
  final String? assetUrl;
  final String? imageUrl;
  final bool isGpxReady;
  final bool isMapReady;
  final String status;
  final double? latitude;
  final double? longitude;
  final List<String> cities;
  final List<HikingRoute> _routes;
  final List<String> rawRoutes;
  final List<Waypoint> allWaypoints;
  final String? localImagePath;

  // Backward-compatible getters
  int get elevationMdpl => elevation;

  /// Daftar rute terurut sesuai dengan urutan array rawRoutes dari API
  List<HikingRoute> get routes {
    if (rawRoutes.isEmpty) return _routes;
    final list = List<HikingRoute>.from(_routes);
    list.sort((a, b) {
      int getIndex(HikingRoute r) {
        int idx = rawRoutes.indexOf(r.id);
        if (idx != -1) return idx;
        final clean = r.name.trim().toLowerCase();
        idx = rawRoutes.indexWhere((o) {
          final cleanO = o.trim().toLowerCase();
          return cleanO == clean ||
              cleanO.endsWith('-$clean') ||
              cleanO.endsWith('.$clean') ||
              cleanO.contains(clean);
        });
        return idx != -1 ? idx : 999999;
      }

      return getIndex(a).compareTo(getIndex(b));
    });
    return list;
  }

  List<String> get routeNames => routes.map((r) => r.name).toList();
  List<String> get routeIds => routes.map((r) => r.id).toList();
  String? get gpxAssetPath => assetUrl;

  /// Memformat nama rute (misal "merbabu-selo" -> "Selo", "merbabu-suwanting" -> "Suwanting")
  static String formatRouteName(String rawRoute, {String? mountainId}) {
    String clean = rawRoute.trim();
    if (mountainId != null && mountainId.isNotEmpty) {
      final prefix = '${mountainId.toLowerCase()}.';
      clean = clean.substring(prefix.length);
    }

    // Ganti strip tersisa dengan spasi (misal "selo-barat" -> "selo barat")
    clean = clean.replaceAll('_', ' ');

    // Capitalize setiap kata
    return clean
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.length > 1
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : word.toUpperCase(),
        )
        .join(' ');
  }

  /// Daftar rute terformat siap tampil di UI (misal: ["Selo", "Suwanting"])
  List<String> get formattedRoutes {
    final list = rawRoutes.isNotEmpty ? rawRoutes : routeNames;
    return list.map((r) => formatRouteName(r, mountainId: id)).toList();
  }

  List<String> get displayRoutes => formattedRoutes;

  const Mountain({
    required this.id,
    required this.name,
    required this.elevation,
    required this.location,
    required this.province,
    required this.difficulty,
    required this.estimatedTime,
    List<HikingRoute> routes = const [],
    this.rawRoutes = const [],
    this.assetUrl,
    this.imageUrl,
    this.isGpxReady = false,
    this.isMapReady = false,
    this.status = 'Buka (Aman)',
    this.latitude,
    this.longitude,
    this.cities = const [],
    this.allWaypoints = const [],
    this.localImagePath,
  }) : _routes = routes;

  Mountain copyWith({
    String? id,
    String? name,
    int? elevation,
    String? location,
    String? province,
    String? difficulty,
    String? estimatedTime,
    List<HikingRoute>? routes,
    List<String>? rawRoutes,
    String? assetUrl,
    String? imageUrl,
    bool? isGpxReady,
    bool? isMapReady,
    String? status,
    double? latitude,
    double? longitude,
    List<String>? cities,
    List<Waypoint>? allWaypoints,
    String? localImagePath,
  }) {
    return Mountain(
      id: id ?? this.id,
      name: name ?? this.name,
      elevation: elevation ?? this.elevation,
      location: location ?? this.location,
      province: province ?? this.province,
      difficulty: difficulty ?? this.difficulty,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      routes: routes ?? _routes,
      rawRoutes: rawRoutes ?? this.rawRoutes,
      assetUrl: assetUrl ?? this.assetUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isGpxReady: isGpxReady ?? this.isGpxReady,
      isMapReady: isMapReady ?? this.isMapReady,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cities: cities ?? this.cities,
      allWaypoints: allWaypoints ?? this.allWaypoints,
      localImagePath: localImagePath ?? this.localImagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'elevation': elevation,
      'location': location,
      'province': province,
      'difficulty': difficulty,
      'estimatedTime': estimatedTime,
      'assetUrl': assetUrl,
      'imageUrl': imageUrl,
      'isGpxReady': isGpxReady,
      'isMapReady': isMapReady,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'cities': cities,
      'routes': routes.map((r) => r.toJson()).toList(),
      'rawRoutes': rawRoutes,
      'allWaypoints': allWaypoints.map((w) => w.toJson()).toList(),
      'localImagePath': localImagePath,
    };
  }

  factory Mountain.fromJson(Map<String, dynamic> json) {
    return Mountain(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      elevation: (json['elevation'] as num?)?.toInt() ?? 0,
      location: json['location'] as String? ?? '',
      province: json['province'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      estimatedTime: json['estimatedTime'] as String? ?? '',
      assetUrl: json['assetUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isGpxReady: json['isGpxReady'] as bool? ?? false,
      isMapReady: json['isMapReady'] as bool? ?? false,
      status: json['status'] as String? ?? 'Buka (Aman)',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      cities:
          (json['cities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      routes:
          (json['routes'] as List<dynamic>?)
              ?.map((r) => HikingRoute.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
      rawRoutes:
          (json['rawRoutes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      allWaypoints:
          (json['allWaypoints'] as List<dynamic>?)
              ?.map((w) => Waypoint.fromJson(w as Map<String, dynamic>))
              .toList() ??
          const [],
      localImagePath: json['localImagePath'] as String?,
    );
  }
}
