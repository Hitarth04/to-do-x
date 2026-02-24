import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> init() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'task_channel',
        channelName: 'Task Reminders',
        channelDescription: 'Notification for task reminders',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        locked: true,
        playSound: true,
        criticalAlerts: true,
      ),
      // NEW: Dedicated Health Channel
      NotificationChannel(
        channelKey: 'health_channel',
        channelName: 'Health Reminders',
        channelDescription: 'Notifications for health tracking',
        defaultColor: Colors.pinkAccent,
        ledColor: Colors.pinkAccent,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
      ),
    ], debug: true);

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: 'task_channel',
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
        ],
      );
    }
  }

  static Future<void> scheduleNotification(
    int id,
    String title,
    DateTime time,
    int minutesBefore,
  ) async {
    if (time.isBefore(DateTime.now())) return;
    String bodyText = minutesBefore == 0
        ? "It's time for your task!"
        : "Is starting in $minutesBefore minutes!";
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'task_channel',
        title: title,
        body: bodyText,
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
      ),
      schedule: NotificationCalendar.fromDate(date: time),
    );
  }

  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  // ================= HEALTH NOTIFICATIONS =================

  static Future<void> schedulePeriodReminder(DateTime startDate) async {
    // Schedule exactly 7 days after the start date
    DateTime reminderTime = startDate.add(const Duration(days: 7));
    if (reminderTime.isBefore(DateTime.now())) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 9999, // Fixed ID so we can easily cancel it
        channelKey: 'health_channel',
        title: "Did your period end?",
        body:
            "It's been 7 days. Don't forget to log the end of your period to keep your predictions accurate!",
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: reminderTime),
    );
  }

  static Future<void> cancelPeriodReminder() async {
    await AwesomeNotifications().cancel(9999);
  }
}
