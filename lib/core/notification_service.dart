import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> init() async {
    // 1. Initialize the plugin
    await AwesomeNotifications().initialize(
      null, // uses the default app icon
      [
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
      ],
      // Debug mode helps you see logs in the console
      debug: true,
    );

    // 2. Request Permissions (Updated for 0.10.x)
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
        autoDismissible: false, // User must interact to dismiss
      ),
      schedule: NotificationCalendar.fromDate(date: time),
    );
  }

  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }
}
