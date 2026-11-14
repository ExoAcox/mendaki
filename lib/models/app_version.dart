class AppVersion {
  final String id;
  final String title;
  final String desc;
  final String? updateLink;
  final bool forceUpdate;
  final DateTime? createdAt;

  const AppVersion({
    required this.id,
    required this.title,
    required this.desc,
    this.updateLink,
    this.forceUpdate = false,
    this.createdAt,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Update Tersedia',
      desc: json['desc']?.toString() ?? '',
      updateLink: json['update_link'] as String?,
      forceUpdate: json['force_update'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'desc': desc,
      'update_link': updateLink,
      'force_update': forceUpdate,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

