import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // flutter_local_notifications does not support web
    if (kIsWeb) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
  }

  Future<void> showCoachingNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    const androidDetails = AndroidNotificationDetails(
      'aura_coaching',
      'Coaching Notifications',
      channelDescription: 'AURA proactive coaching notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> showGoalProgressNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    const androidDetails = AndroidNotificationDetails(
      'aura_goals',
      'Goal Notifications',
      channelDescription: 'AURA goal progress notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
      title,
      body,
      details,
    );
  }
}
