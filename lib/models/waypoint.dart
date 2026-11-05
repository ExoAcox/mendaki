class Waypoint {
  final String name;
  final double latitude;
  final double longitude;
  final double? elevation;
  final String type; // basecamp, pos, water, camp, summit, hazard
  final String? description;
  final String? comment;
  final bool hasWater;
  final int? tentCapacity;
  final String? signalInfo;

  bool get isBasecamp =>
      type == 'basecamp' || name.toLowerCase().contains('basecamp');
  bool get isCamp {
    final cmt = (comment ?? '').trim().toLowerCase();
    final tp = type.toLowerCase();
    final nm = name.toLowerCase();
    return cmt == 'camp' ||
        cmt.contains('camp') ||
        tp == 'camp' ||
        nm.contains('camp') ||
        nm.contains('camping');
  }
  bool get isSummit =>
      type == 'summit' || name.toLowerCase().contains('puncak');

  const Waypoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.type = 'pos',
    this.description,
    this.comment,
    this.hasWater = false,
    this.tentCapacity,
    this.signalInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'type': type,
      'description': description,
      'comment': comment,
      'hasWater': hasWater,
      'tentCapacity': tentCapacity,
      'signalInfo': signalInfo,
    };
  }

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      elevation: (json['elevation'] as num?)?.toDouble(),
      type: json['type'] as String? ?? 'pos',
      description: json['description'] as String?,
      comment: json['comment'] as String?,
      hasWater: json['hasWater'] as bool? ?? false,
      tentCapacity: (json['tentCapacity'] as num?)?.toInt(),
      signalInfo: json['signalInfo'] as String?,
    );
  }
}

