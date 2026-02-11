import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // FIX: Added 'minutesBefore' parameter to customize the message
  static Future<void> scheduleNotification(
    int id,
    String taskTitle,
    DateTime scheduledTime,
    int minutesBefore,
  ) async {
    // Logic: Safety check - cannot schedule in the past
    if (scheduledTime.isBefore(DateTime.now())) return;

    // Logic: Custom Message based on user preference
    String bodyText;
    if (minutesBefore == 0) {
      bodyText = "It's time for your task!";
    } else {
      bodyText = "Is starting in $minutesBefore minutes!";
    }

    await _notifications.zonedSchedule(
      id,
      taskTitle, // Notification Title = Task Name
      bodyText, // Notification Body = "Is starting in X minutes!"
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
