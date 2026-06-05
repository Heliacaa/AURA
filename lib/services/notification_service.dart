import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../shared/models/user_model.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _waterReminderIds = [1101, 1102, 1103];
  static const _dailyGoalReminderId = 1201;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  void Function(String location)? _navigationHandler;
  String? _pendingLocation;
  String? _lastScheduleSignature;
  bool _initialized = false;

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> initialize() async {
    if (!_isSupported || _initialized) return;
    _initialized = true;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        _navigateForPayload(response.payload);
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _navigateForPayload(launchDetails?.notificationResponse?.payload);
    }
  }

  void setNavigationHandler(void Function(String location) handler) {
    _navigationHandler = handler;
    final pending = _pendingLocation;
    if (pending != null) {
      _pendingLocation = null;
      handler(pending);
    }
  }

  Future<void> syncForUser(UserModel? user) async {
    if (!_isSupported) return;
    if (user == null) {
      _lastScheduleSignature = null;
      await cancelAllReminders();
      return;
    }

    final preferences = user.notificationPreferences;
    final signature = [
      user.uid,
      preferences.waterReminders,
      preferences.dailyGoalReminder,
      user.dailyGoals.steps,
      user.dailyGoals.waterGlasses,
    ].join(':');
    if (_lastScheduleSignature == signature) return;

    await applyPreferences(
      preferences: preferences,
      dailyGoals: user.dailyGoals,
    );
    _lastScheduleSignature = signature;
  }

  Future<bool> requestLocalPermission() async {
    if (!_isSupported) return false;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  Future<void> applyPreferences({
    required NotificationPreferences preferences,
    required DailyGoals dailyGoals,
  }) async {
    if (!_isSupported) return;

    for (final id in _waterReminderIds) {
      await _plugin.cancel(id);
    }
    await _plugin.cancel(_dailyGoalReminderId);

    if (preferences.waterReminders) {
      await _scheduleDaily(
        id: _waterReminderIds[0],
        hour: 11,
        title: 'Su molası',
        body:
            'Günlük ${dailyGoals.waterGlasses} bardak su hedefin için bir bardak su içme zamanı.',
      );
      await _scheduleDaily(
        id: _waterReminderIds[1],
        hour: 15,
        title: 'Su içmeyi unutma',
        body: 'Kısa bir su molası enerji seviyeni tazeleyebilir.',
      );
      await _scheduleDaily(
        id: _waterReminderIds[2],
        hour: 19,
        title: 'Akşam su kontrolü',
        body: 'Bugünkü su hedefini tamamlamaya ne kadar kaldı?',
      );
    }

    if (preferences.dailyGoalReminder) {
      await _scheduleDaily(
        id: _dailyGoalReminderId,
        hour: 20,
        title: 'AURA günlük hedef kontrolü',
        body:
            '${dailyGoals.steps} adım ve ${dailyGoals.waterGlasses} bardak su hedeflerini kontrol et.',
      );
    }
  }

  Future<void> cancelAllReminders() async {
    if (!_isSupported) return;
    for (final id in [..._waterReminderIds, _dailyGoalReminderId]) {
      await _plugin.cancel(id);
    }
  }

  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  static String? routeForPayload(String? payload) {
    if (payload == null || !payload.startsWith('/')) return null;
    return payload;
  }

  static DateTime nextDailyReminder(DateTime now, int hour, [int minute = 0]) {
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/home',
    );
  }

  void _navigateForPayload(String? payload) {
    final location = routeForPayload(payload);
    if (location == null) return;
    final handler = _navigationHandler;
    if (handler == null) {
      _pendingLocation = location;
    } else {
      handler(location);
    }
  }
}
