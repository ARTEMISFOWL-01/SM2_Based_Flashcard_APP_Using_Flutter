import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings);
    tz.initializeTimeZones();
  }

  static Future scheduleDailyReminder() async {
    await _notifications.zonedSchedule(
      0,
      'Study Reminder 📚',
      'Time to review your flashcards!',
      _nextInstanceOf8PM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_channel',
          'Study Reminders',
          importance: Importance.high,
        ),
      ),
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static tz.TZDateTime _nextInstanceOf8PM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
