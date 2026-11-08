class Waypoint {
  final String name;
  final double latitude;
  final double longitude;
  final double? elevation;
  final String type; // post, basecamp, camp, summit
  final String? description;
  final String? comment;
  final bool hasWater;
  final int? tentCapacity;
  final String? signalInfo;

  bool get isBasecamp =>
      type == 'basecamp' || (comment ?? '').trim().toLowerCase() == 'basecamp';
  bool get isCamp =>
      type == 'camp' || (comment ?? '').trim().toLowerCase() == 'camp';
  bool get isSummit {
    final cmt = (comment ?? '').trim().toLowerCase();
    return type == 'summit' || cmt == 'summit' || cmt == 'peak';
  }
  bool get isPost => !isBasecamp && !isCamp && !isSummit;

  const Waypoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.type = 'post',
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
    final rawType = json['type'] as String? ?? 'post';
    final normalizedType = rawType == 'pos' ? 'post' : rawType;
    return Waypoint(
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      elevation: (json['elevation'] as num?)?.toDouble(),
      type: normalizedType,
      description: json['description'] as String?,
      comment: json['comment'] as String?,
      hasWater: json['hasWater'] as bool? ?? false,
      tentCapacity: (json['tentCapacity'] as num?)?.toInt(),
      signalInfo: json['signalInfo'] as String?,
    );
  }
}

