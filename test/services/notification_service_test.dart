import 'package:flutter_test/flutter_test.dart';
import 'package:aura/services/notification_service.dart';

void main() {
  test('local notification payload maps to an app destination', () {
    expect(NotificationService.routeForPayload('/home'), '/home');
    expect(NotificationService.routeForPayload('home'), isNull);
    expect(NotificationService.routeForPayload(null), isNull);
  });

  test('next daily reminder stays today when the time is still ahead', () {
    final now = DateTime(2026, 6, 4, 10, 30);
    final reminder = NotificationService.nextDailyReminder(now, 11);

    expect(reminder, DateTime(2026, 6, 4, 11));
  });

  test('next daily reminder moves to tomorrow after the scheduled time', () {
    final now = DateTime(2026, 6, 4, 20);
    final reminder = NotificationService.nextDailyReminder(now, 20);

    expect(reminder, DateTime(2026, 6, 5, 20));
  });
}
