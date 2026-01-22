import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(settings);
  }

  // --- PRO MODE: Cancel a specific notification ---
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // --- PRO MODE: Cancel ALL (useful for "Reset Data" in settings) ---
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  static Future<void> scheduleNotification(int id, String title, DateTime date) async {
    // Schedule for 9:00 AM on the billing day
    // NOTE: In a real app, you might want 1 day BEFORE.
    // This logic schedules for 9AM on the due date.
    final scheduledDate = DateTime(date.year, date.month, date.day, 9, 0);

    // Handle past dates: If the calculated date is in the past,
    // we should strictly speaking calculate the NEXT cycle.
    // For now, we will just ensure we don't crash by checking:
    var tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) {
      // If date is passed, don't schedule, or schedule for next year/month.
      // For this snippet, we simply return to prevent crash.
      return;
    }

    await _notifications.zonedSchedule(
      id,
      'Bill Due: $title',
      'Don\'t forget to pay your subscription today!',
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sub_channel',
          'Subscriptions',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}