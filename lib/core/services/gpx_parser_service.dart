import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';
import 'package:mendaki/models/route.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/models/waypoint.dart';

/// Representasi data hasil parsing GPX secara umum (agnostik terhadap nama gunung).
class GpxData {
  final String name;
  final String? description;
  final List<Waypoint> waypoints;
  final List<HikingRoute> tracks;
  final double totalDistanceKm;
  final double minElevation;
  final double maxElevation;
  final double totalElevationGain;

  const GpxData({
    required this.name,
    this.description,
    required this.waypoints,
    required this.tracks,
    this.totalDistanceKm = 0.0,
    this.minElevation = 0.0,
    this.maxElevation = 0.0,
    this.totalElevationGain = 0.0,
  });

  /// Helper untuk mengonversi data GPX umum ke model Mountain
  Mountain toMountain({
    required String id,
    String? name,
    String location = '',
    String province = '',
    String difficulty = '',
    String estimatedTime = '',
    String status = '',
    String? gpxAssetPath,
  }) {
    final highestElevation = maxElevation > 0
        ? maxElevation.toInt()
        : (waypoints.isNotEmpty
              ? waypoints
                    .map((w) => w.elevation ?? 0.0)
                    .reduce(math.max)
                    .toInt()
              : 0);

    return Mountain(
      id: id,
      name: name ?? this.name,
      elevation: highestElevation,
      location: location,
      province: province,
      difficulty: difficulty,
      estimatedTime: estimatedTime,
      routes: tracks,
      assetUrl: gpxAssetPath,
      isGpxReady: true,
      isMapReady: false,
      status: status,
      allWaypoints: waypoints,
    );
  }
}

/// Service Parser GPX yang bersifat umum (General GPX Parser).
/// Dapat memproses file GPX dari aset, string mentah (dari API/Network), maupun file lokal.
class GpxParserService {
  /// Parse file GPX dari aset aplikasi
  static Future<GpxData> parseAsset(
    String assetPath, {
    String? defaultName,
  }) async {
    final gpxString = await rootBundle.loadString(assetPath);
    final fallbackName =
        defaultName ??
        assetPath
            .split('/')
            .last
            .replaceAll('.gpx', '')
            .replaceAll('_', ' ')
            .toUpperCase();
    return parseString(gpxString, defaultName: fallbackName);
  }

  /// Parse file GPX dari penyimpanan lokal (File)
  static Future<GpxData> parseFile(
    File file, {
    String? defaultName,
  }) async {
    final gpxString = await file.readAsString();
    final fallbackName =
        defaultName ??
        file.uri.pathSegments.last
            .replaceAll('.gpx', '')
            .replaceAll('_', ' ')
            .toUpperCase();
    return parseString(gpxString, defaultName: fallbackName);
  }

  /// Parse string XML GPX mentah (dapat digunakan untuk respon API / server / file)
  static GpxData parseString(
    String gpxString, {
    String defaultName = 'Jalur Pendakian',
  }) {
    final document = XmlDocument.parse(gpxString);

    // 1. Ambil Nama & Metadata Dokumen
    final metadataElem = document.findAllElements('metadata').firstOrNull;
    final metadataName = metadataElem
        ?.findElements('name')
        .firstOrNull
        ?.innerText
        .trim();
    final metadataDesc = metadataElem
        ?.findElements('desc')
        .firstOrNull
        ?.innerText
        .trim();
    final documentName = metadataName ?? defaultName;

    // 2. Parse Waypoints murni (<wpt>)
    final wptElements = document.findAllElements('wpt');
    final List<Waypoint> waypoints = [];

    double minEle = double.infinity;
    double maxEle = -double.infinity;

    for (final wpt in wptElements) {
      final waypoint = _parseWaypointElement(wpt);
      if (waypoint.elevation != null) {
        if (waypoint.elevation! < minEle) minEle = waypoint.elevation!;
        if (waypoint.elevation! > maxEle) maxEle = waypoint.elevation!;
      }
      waypoints.add(waypoint);
    }

    final List<HikingRoute> routes = [];
    double totalDistanceKm = 0.0;
    double totalElevationGain = 0.0;
    int routeCounter = 1;

    // Helper internal untuk memproses sekumpulan titik koordinat menjadi rute
    void processPointsList({
      required String routeName,
      required Iterable<XmlElement> points,
    }) {
      final List<LatLngPoint> coords = [];
      double routeDistance = 0.0;
      double routeElevationGain = 0.0;
      LatLngPoint? prevPoint;

      for (final pt in points) {
        final lat = double.tryParse(pt.getAttribute('lat') ?? '') ?? 0.0;
        final lon = double.tryParse(pt.getAttribute('lon') ?? '') ?? 0.0;
        final ele = double.tryParse(
          pt.findElements('ele').firstOrNull?.innerText.trim() ?? '',
        );

        if (ele != null) {
          if (ele < minEle) minEle = ele;
          if (ele > maxEle) maxEle = ele;
        }

        // Ekstraksi waypoint otomatis jika titik memiliki <name> dan belum ada di waypoints
        final ptName = pt.findElements('name').firstOrNull?.innerText.trim();
        if (ptName != null && ptName.isNotEmpty) {
          if (!_isWaypointDuplicate(waypoints, lat, lon)) {
            waypoints.add(_parseWaypointElement(pt));
          }
        }

        final currentPoint = LatLngPoint(
          latitude: lat,
          longitude: lon,
          elevation: ele,
        );
        coords.add(currentPoint);

        if (prevPoint != null) {
          routeDistance += _calculateHaversineDistanceKm(
            prevPoint.latitude,
            prevPoint.longitude,
            currentPoint.latitude,
            currentPoint.longitude,
          );

          if (prevPoint.elevation != null && currentPoint.elevation != null) {
            final diff = currentPoint.elevation! - prevPoint.elevation!;
            if (diff > 0) routeElevationGain += diff;
          }
        }
        prevPoint = currentPoint;
      }

      if (coords.isEmpty) return;

      // Cek apakah rute ini adalah duplikat dari track yang sudah diparse
      final isDuplicate = routes.any((r) =>
          r.name.toLowerCase() == routeName.toLowerCase() ||
          (r.trackPoints.isNotEmpty &&
              _calculateHaversineDistanceKm(
                    r.trackPoints.first.latitude,
                    r.trackPoints.first.longitude,
                    coords.first.latitude,
                    coords.first.longitude,
                  ) < 0.05 &&
              _calculateHaversineDistanceKm(
                    r.trackPoints.last.latitude,
                    r.trackPoints.last.longitude,
                    coords.last.latitude,
                    coords.last.longitude,
                  ) < 0.05));

      if (isDuplicate) return;

      totalDistanceKm += routeDistance;
      totalElevationGain += routeElevationGain;

      routes.add(
        _buildHikingRoute(
          id: 'route_$routeCounter',
          name: routeName,
          trackCoords: coords,
          routeDistance: routeDistance,
          routeElevationGain: routeElevationGain,
          allWaypoints: waypoints,
        ),
      );

      routeCounter++;
    }

    // 3. Parse Tracks (<trk>)
    final trkElements = document.findAllElements('trk');
    for (final trk in trkElements) {
      final trackName =
          trk.findElements('name').firstOrNull?.innerText.trim() ??
          'Rute $routeCounter';
      final trkpts = trk.findAllElements('trkpt');
      processPointsList(routeName: trackName, points: trkpts);
    }

    // 4. Parse Routes (<rte>) - Dukungan Hybrid GPX
    final rteElements = document.findAllElements('rte');
    for (final rte in rteElements) {
      final routeName =
          rte.findElements('name').firstOrNull?.innerText.trim() ??
          'Rute $routeCounter';
      final rtepts = rte.findAllElements('rtept');
      processPointsList(routeName: routeName, points: rtepts);
    }

    // 5. Fallback: Jika tidak ada <trk> maupun <rte>, namun ada waypoints (>= 2)
    if (routes.isEmpty && waypoints.length >= 2) {
      final List<LatLngPoint> fallbackCoords = [];
      double routeDistance = 0.0;
      double routeElevationGain = 0.0;
      LatLngPoint? prevPoint;

      for (final wpt in waypoints) {
        final currentPoint = LatLngPoint(
          latitude: wpt.latitude,
          longitude: wpt.longitude,
          elevation: wpt.elevation,
        );
        fallbackCoords.add(currentPoint);

        if (prevPoint != null) {
          routeDistance += _calculateHaversineDistanceKm(
            prevPoint.latitude,
            prevPoint.longitude,
            currentPoint.latitude,
            currentPoint.longitude,
          );

          if (prevPoint.elevation != null && currentPoint.elevation != null) {
            final diff = currentPoint.elevation! - prevPoint.elevation!;
            if (diff > 0) routeElevationGain += diff;
          }
        }
        prevPoint = currentPoint;
      }

      totalDistanceKm += routeDistance;
      totalElevationGain += routeElevationGain;

      routes.add(
        _buildHikingRoute(
          id: 'route_$routeCounter',
          name: documentName,
          trackCoords: fallbackCoords,
          routeDistance: routeDistance,
          routeElevationGain: routeElevationGain,
          allWaypoints: waypoints,
        ),
      );
    }

    return GpxData(
      name: documentName,
      description: metadataDesc,
      waypoints: waypoints,
      tracks: routes,
      totalDistanceKm: double.parse(totalDistanceKm.toStringAsFixed(2)),
      minElevation: minEle.isFinite ? minEle : 0.0,
      maxElevation: maxEle.isFinite ? maxEle : 0.0,
      totalElevationGain: totalElevationGain,
    );
  }

  // --- Helper Pembangunan Model & Klasifikasi ---

  static Waypoint _parseWaypointElement(XmlElement elem) {
    final lat = double.tryParse(elem.getAttribute('lat') ?? '') ?? 0.0;
    final lon = double.tryParse(elem.getAttribute('lon') ?? '') ?? 0.0;
    final name =
        elem.findElements('name').firstOrNull?.innerText.trim() ?? 'Waypoint';
    final desc = elem.findElements('desc').firstOrNull?.innerText.trim();
    final cmt = elem.findElements('cmt').firstOrNull?.innerText.trim();

    final eleElem = elem.findElements('ele').firstOrNull;
    final elevation = eleElem != null
        ? double.tryParse(eleElem.innerText.trim())
        : null;

    final type = _classifyWaypointType(cmt);
    final hasWater = _checkWaterAvailable(name, desc, cmt);
    final tentCapacity = _extractTentCapacity(name, desc, type);
    final signalInfo = _extractSignalInfo(name, desc);

    return Waypoint(
      name: name,
      latitude: lat,
      longitude: lon,
      elevation: elevation,
      type: type,
      description: desc,
      comment: cmt,
      hasWater: hasWater,
      tentCapacity: tentCapacity,
      signalInfo: signalInfo,
    );
  }

  static bool _isWaypointDuplicate(List<Waypoint> list, double lat, double lon) {
    for (final w in list) {
      if ((w.latitude - lat).abs() < 0.0001 && (w.longitude - lon).abs() < 0.0001) {
        return true;
      }
    }
    return false;
  }

  static HikingRoute _buildHikingRoute({
    required String id,
    required String name,
    required List<LatLngPoint> trackCoords,
    required double routeDistance,
    required double routeElevationGain,
    required List<Waypoint> allWaypoints,
  }) {
    // Cari pos yang berada di dekat rute track ini (radius 500 meter)
    final matchingWaypoints = allWaypoints.where((wpt) {
      if (trackCoords.isEmpty) return true;
      return trackCoords.any(
        (coord) =>
            _calculateHaversineDistanceKm(
              wpt.latitude,
              wpt.longitude,
              coord.latitude,
              coord.longitude,
            ) <=
            0.5,
      );
    }).toList();

    final basecampWpt = matchingWaypoints.firstWhere(
      (w) => w.type == 'basecamp',
      orElse: () => WaypointsFallback.defaultBasecamp,
    );

    final roundedDistance = double.parse(
      (routeDistance > 0 ? routeDistance : 5.0).toStringAsFixed(1),
    );
    final roundedGain = routeElevationGain.toInt();
    final estHours = math.max(2, (roundedDistance / 1.5).round());

    return HikingRoute(
      id: id,
      name: name,
      basecampName: basecampWpt.name,
      distanceKm: roundedDistance,
      estimatedDuration: '$estHours - ${estHours + 2} Jam',
      elevationGainMeters: roundedGain > 0 ? roundedGain : 1000,
      difficulty: roundedGain > 1500 ? 'Sangat Curam' : 'Sedang',
      waypoints: matchingWaypoints.isNotEmpty ? matchingWaypoints : allWaypoints,
      trackPoints: trackCoords,
    );
  }

  // --- Helper Klasifikasi Umum (Hanya 4 tipe: post, basecamp, camp, summit) ---

  static String _classifyWaypointType(String? cmt) {
    final comment = (cmt ?? '').trim().toLowerCase();
    if (comment == 'basecamp') {
      return 'basecamp';
    } else if (comment == 'camp') {
      return 'camp';
    } else if (comment == 'summit' || comment == 'peak') {
      return 'summit';
    }
    return 'post';
  }

  static bool _checkWaterAvailable(
    String name,
    String? desc, [
    String? cmt,
  ]) {
    final comment = (cmt ?? '').trim().toLowerCase();
    if (comment == 'water' || comment == 'air') return true;

    final text = '${name.toUpperCase()} ${(desc ?? '').toUpperCase()}';
    return text.contains('AIR') ||
        text.contains('WATER') ||
        text.contains('SPRING') ||
        text.contains('SUMBER') ||
        text.contains('BASECAMP');
  }

  static int? _extractTentCapacity(String name, String? desc, String type) {
    if (type != 'camp') return null;
    final text = '${name.toUpperCase()} ${(desc ?? '').toUpperCase()}';
    if (text.contains('SABANA') || text.contains('CAMP UTAMA')) return 50;
    return 20;
  }

  static String? _extractSignalInfo(String name, String? desc) {
    final text = '${name.toUpperCase()} ${(desc ?? '').toUpperCase()}';
    if (text.contains('BASECAMP')) return 'Telkomsel 4G, Indosat, XL';
    if (text.contains('POS 1')) return 'Telkomsel 2 Bar';
    if (text.contains('POS 2') || text.contains('POS 3')) {
      return 'Telkomsel 1 Bar';
    }
    return null;
  }

  static double _calculateHaversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}

class WaypointsFallback {
  static const defaultBasecamp = Waypoint(
    name: 'Basecamp',
    latitude: 0,
    longitude: 0,
    type: 'basecamp',
  );
}
