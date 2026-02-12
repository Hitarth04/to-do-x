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

  // FIX: Added 'minutesBefore' parameter to match HomeScreen call
  static Future<void> scheduleNotification(
    int id,
    String title,
    DateTime time,
    int minutesBefore,
  ) async {
    // 1. Safety check for past times
    if (time.isBefore(DateTime.now())) {
      print("NotificationService: Time is in the past. Skipping.");
      return;
    }

    // 2. Custom Message Logic
    String bodyText = minutesBefore == 0
        ? "It's time for your task!"
        : "Is starting in $minutesBefore minutes!";

    // 3. CRITICAL FIX: Convert to UTC
    // This bypasses local timezone issues that cause notifications to fail
    final tz.TZDateTime scheduledTimeUTC = tz.TZDateTime.from(
      time.toUtc(),
      tz.UTC,
    );

    print(
      "NotificationService: Scheduling '$title' for $scheduledTimeUTC (UTC)",
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title, // Title of notification
        bodyText, // Body text (e.g. "Is starting in 15 minutes!")
        scheduledTimeUTC,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Reminders',
            channelDescription: 'Task Deadlines',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print("NotificationService Error: $e");
    }
  }
}
