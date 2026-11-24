import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latlong2/latlong.dart';
import 'package:mendaki/core/services/gpx_parser_service.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/offline_map_service.dart';
import 'package:mendaki/models/mountain.dart';

enum DownloadType { gpx, map }

@pragma('vm:entry-point')
void downloadNotificationTapBackground(NotificationResponse response) {
  if (response.actionId != null) {
    if (response.actionId!.startsWith('cancel_gpx_')) {
      final mountainId = response.actionId!.replaceFirst('cancel_gpx_', '');
      DownloadService.instance.cancelDownload(
        mountainId,
        type: DownloadType.gpx,
      );
    } else if (response.actionId!.startsWith('cancel_map_')) {
      final mountainId = response.actionId!.replaceFirst('cancel_map_', '');
      DownloadService.instance.cancelDownload(
        mountainId,
        type: DownloadType.map,
      );
    }
  }
}

class DownloadTask {
  final Mountain mountain;
  final DownloadType type;
  double progress;
  bool isCancelled;
  String statusText;
  DateTime lastNotificationTime;
  int lastNotificationProgress;

  DownloadTask({
    required this.mountain,
    required this.type,
    this.progress = 0.0,
    this.isCancelled = false,
    this.statusText = '',
  }) : lastNotificationTime = DateTime.fromMillisecondsSinceEpoch(0),
       lastNotificationProgress = -1;
}

/// Layanan terpusat untuk mengelola unduhan terpisah antara data GPX dan Peta Offline
class DownloadService extends ChangeNotifier {
  DownloadService._internal();
  static final DownloadService instance = DownloadService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Map<String, DownloadTask> _tasks = {};
  bool _isInitialized = false;

  static const String channelId = 'mountain_download_channel';
  static const String channelName = 'Unduhan Peta & GPX';
  static const String channelDesc =
      'Menampilkan progress unduhan data GPX dan map offline';

  /// Inisialisasi notifikasi lokal
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _isInitialized = true;
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        '@drawable/ic_notification',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.actionId != null) {
            if (response.actionId!.startsWith('cancel_gpx_')) {
              final mountainId = response.actionId!.replaceFirst(
                'cancel_gpx_',
                '',
              );
              cancelDownload(mountainId, type: DownloadType.gpx);
            } else if (response.actionId!.startsWith('cancel_map_')) {
              final mountainId = response.actionId!.replaceFirst(
                'cancel_map_',
                '',
              );
              cancelDownload(mountainId, type: DownloadType.map);
            }
          }
        },
        onDidReceiveBackgroundNotificationResponse:
            downloadNotificationTapBackground,
      );

      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.low,
          enableVibration: false,
          playSound: false,
        );
        await androidImpl.createNotificationChannel(channel);
      }

      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosImpl != null) {
        await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('DownloadService initialize warning: $e');
    }
  }

  String _taskKey(String mountainId, DownloadType type) =>
      '${type.name}_$mountainId';

  int _getNotificationId(String mountainId, DownloadType type) {
    final base = mountainId.hashCode.abs() % 40000;
    return type == DownloadType.gpx ? base + 1000 : base + 50000;
  }

  // ==========================================
  // STATUS CHECKERS
  // ==========================================

  bool isDownloadingGpx(String mountainId) {
    final task = _tasks[_taskKey(mountainId, DownloadType.gpx)];
    return task != null && !task.isCancelled;
  }

  bool isDownloadingMap(String mountainId) {
    final task = _tasks[_taskKey(mountainId, DownloadType.map)];
    return task != null && !task.isCancelled;
  }

  double getGpxProgress(String mountainId) {
    return _tasks[_taskKey(mountainId, DownloadType.gpx)]?.progress ?? 0.0;
  }

  double getMapProgress(String mountainId) {
    return _tasks[_taskKey(mountainId, DownloadType.map)]?.progress ?? 0.0;
  }

  // ==========================================
  // 1. UNDUH HANYA GPX (TIDAK DENGAN MAP)
  // ==========================================

  Future<bool> startGpxDownload(Mountain mountain) async {
    final key = _taskKey(mountain.id, DownloadType.gpx);
    if (_tasks.containsKey(key)) return false;

    final task = DownloadTask(
      mountain: mountain,
      type: DownloadType.gpx,
      statusText: 'Mengunduh data GPX...',
    );
    _tasks[key] = task;
    notifyListeners();

    final notifId = _getNotificationId(mountain.id, DownloadType.gpx);

    try {
      await _showStartedNotification(task, notifId);
      await _updateNotificationProgress(task, 'Mengunduh data GPX...', 0.0);

      if (task.isCancelled) {
        await _handleCancelled(task, notifId);
        return false;
      }

      await GpxStorageService.downloadAndSaveGpx(
        mountainId: mountain.id,
        onProgress: (progress) {
          if (task.isCancelled) return;
          task.progress = progress;
          task.statusText = 'Mengunduh GPX... ${(progress * 100).toInt()}%';

          final percent = (progress * 100).toInt();
          final now = DateTime.now();
          if (percent - task.lastNotificationProgress >= 10 ||
              now.difference(task.lastNotificationTime).inMilliseconds >= 500 ||
              percent >= 100) {
            task.lastNotificationProgress = percent;
            task.lastNotificationTime = now;
            _updateNotificationProgress(
              task,
              'Mengunduh GPX... $percent%',
              progress,
            );
          }
          notifyListeners();
        },
      );

      if (task.isCancelled) {
        await _handleCancelled(task, notifId);
        return false;
      }

      // Simpan metadata gunung offline
      final updated = mountain.copyWith(isGpxReady: true);
      await GpxStorageService.saveDownloadedMountain(updated);

      _tasks.remove(key);
      notifyListeners();

      await _showCompletedNotification(
        mountain,
        DownloadType.gpx,
        'GPX Berhasil Diunduh',
        'Data GPX ${mountain.name} berhasil disimpan ke perangkat.',
        notifId,
      );
      return true;
    } catch (e) {
      debugPrint('Error downloading GPX for ${mountain.name}: $e');
      _tasks.remove(key);
      notifyListeners();
      await _showFailedNotification(mountain, DownloadType.gpx, notifId);
      return false;
    }
  }

  // ==========================================
  // 2. UNDUH HANYA MAP OFFLINE (TIDAK DENGAN GPX)
  // ==========================================

  Future<bool> startMapDownload(Mountain mountain) async {
    final key = _taskKey(mountain.id, DownloadType.map);
    if (_tasks.containsKey(key)) return false;

    final task = DownloadTask(
      mountain: mountain,
      type: DownloadType.map,
      statusText: 'Menyiapkan unduhan map...',
    );
    _tasks[key] = task;
    notifyListeners();

    final notifId = _getNotificationId(mountain.id, DownloadType.map);

    try {
      await _showStartedNotification(task, notifId);
      await _updateNotificationProgress(task, 'Menghitung area map...', 0.0);

      if (task.isCancelled) {
        await _handleCancelled(task, notifId);
        return false;
      }

      // Cari track points jika GPX sudah ada di lokal untuk bounding box akurat
      List<LatLng>? trackPoints;
      final gpxFile = await GpxStorageService.getLocalGpxFile(mountain.id);
      if (gpxFile != null && await gpxFile.exists()) {
        try {
          final gpxData = await GpxParserService.parseFile(gpxFile);
          trackPoints = gpxData.tracks
              .expand((t) => t.trackPoints)
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList();
        } catch (e) {
          debugPrint('Info: parse GPX for map bounding box failed: $e');
        }
      }

      if (task.isCancelled) {
        await _handleCancelled(task, notifId);
        return false;
      }

      await OfflineMapService.downloadOfflineMap(
        mountainId: mountain.id,
        centerLat: mountain.latitude ?? -7.455,
        centerLng: mountain.longitude ?? 110.435,
        trackPoints: trackPoints,
        minZoom: 16,
        maxZoom: 16,
        isCancelled: () => task.isCancelled,
        onProgress: (downloaded, total) {
          if (task.isCancelled) return;
          final currentProgress = total > 0 ? downloaded / total : 0.0;
          final percent = (currentProgress * 100).toInt();

          task.progress = currentProgress;
          task.statusText = 'Mengunduh Map... $percent%';

          final now = DateTime.now();
          if (percent - task.lastNotificationProgress >= 3 ||
              now.difference(task.lastNotificationTime).inMilliseconds >= 400 ||
              percent >= 100) {
            task.lastNotificationProgress = percent;
            task.lastNotificationTime = now;
            _updateNotificationProgress(
              task,
              'Mengunduh map... $percent%',
              currentProgress,
            );
          }
          notifyListeners();
        },
      );

      if (task.isCancelled) {
        await _handleCancelled(task, notifId);
        return false;
      }

      // Tandai map ready
      final updated = mountain.copyWith(isMapReady: true);
      await GpxStorageService.saveDownloadedMountain(updated);

      _tasks.remove(key);
      notifyListeners();

      await _showCompletedNotification(
        mountain,
        DownloadType.map,
        'Map Berhasil Diunduh',
        'Map ${mountain.name} berhasil disimpan ke perangkat.',
        notifId,
      );
      return true;
    } catch (e) {
      debugPrint('Error downloading map for ${mountain.name}: $e');
      _tasks.remove(key);
      notifyListeners();
      await _showFailedNotification(mountain, DownloadType.map, notifId);
      return false;
    }
  }

  // ==========================================
  // PEMBATALAN UNDUHAN
  // ==========================================

  Future<void> cancelDownload(String mountainId, {DownloadType? type}) async {
    final targets = <DownloadTask>[];

    if (type == null || type == DownloadType.gpx) {
      final task = _tasks[_taskKey(mountainId, DownloadType.gpx)];
      if (task != null) targets.add(task);
    }
    if (type == null || type == DownloadType.map) {
      final task = _tasks[_taskKey(mountainId, DownloadType.map)];
      if (task != null) targets.add(task);
    }

    for (final task in targets) {
      task.isCancelled = true;
      task.statusText = 'Membatalkan unduhan...';
      notifyListeners();

      final notifId = _getNotificationId(mountainId, task.type);
      await _handleCancelled(task, notifId);
    }
  }

  Future<void> _handleCancelled(DownloadTask task, int notifId) async {
    _tasks.remove(_taskKey(task.mountain.id, task.type));
    notifyListeners();

    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return;

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.low,
        priority: Priority.low,
        autoCancel: true,
        ongoing: false,
        onlyAlertOnce: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final typeLabel = task.type == DownloadType.gpx ? 'GPX' : 'map';
      await _notificationsPlugin.show(
        id: notifId,
        title: 'Unduhan Dibatalkan',
        body: 'Unduhan $typeLabel ${task.mountain.name} telah dibatalkan.',
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
        ),
      );

      Future.delayed(const Duration(seconds: 3), () async {
        try {
          await _notificationsPlugin.cancel(id: notifId);
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Notification cancel error: $e');
    }
  }

  Future<void> _showStartedNotification(DownloadTask task, int notifId) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final typeLabel = task.type == DownloadType.gpx ? 'GPX' : 'Map';
        final title = 'Mengunduh $typeLabel ${task.mountain.name}';
        final body = task.type == DownloadType.gpx
            ? 'Mulai mengunduh data GPX...'
            : 'Mulai mengunduh map offline...';

        const darwinDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        );

        await _notificationsPlugin.show(
          id: notifId,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(iOS: darwinDetails),
        );
      }
    } catch (e) {
      debugPrint('Started notification error: $e');
    }
  }

  Future<void> _updateNotificationProgress(
    DownloadTask task,
    String body,
    double progress,
  ) async {
    task.progress = progress;
    task.statusText = body;

    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final percent = (progress * 100).clamp(0, 100).toInt();
      final actionId = task.type == DownloadType.gpx
          ? 'cancel_gpx_${task.mountain.id}'
          : 'cancel_map_${task.mountain.id}';
      final title = task.type == DownloadType.gpx
          ? 'Mengunduh GPX ${task.mountain.name}'
          : 'Mengunduh Map ${task.mountain.name}';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: percent,
        onlyAlertOnce: true,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            actionId,
            'Batal',
            showsUserInterface: false,
            cancelNotification: false,
          ),
        ],
      );

      await _notificationsPlugin.show(
        id: _getNotificationId(task.mountain.id, task.type),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint('Update notification error: $e');
    }
  }

  Future<void> _showCompletedNotification(
    Mountain mountain,
    DownloadType type,
    String title,
    String body,
    int notifId,
  ) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        ongoing: false,
        autoCancel: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _notificationsPlugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
        ),
      );
    } catch (e) {
      debugPrint('Completed notification error: $e');
    }
  }

  Future<void> _showFailedNotification(
    Mountain mountain,
    DownloadType type,
    int notifId,
  ) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final typeLabel = type == DownloadType.gpx ? 'GPX' : 'Map';
      await _notificationsPlugin.show(
        id: notifId,
        title: 'Unduhan Gagal',
        body: 'Gagal mengunduh $typeLabel ${mountain.name}. Silakan coba lagi.',
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
        ),
      );
    } catch (e) {
      debugPrint('Failed notification error: $e');
    }
  }
}
