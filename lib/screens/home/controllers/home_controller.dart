import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:confetti/confetti.dart';
import '../../../data/models/task_model.dart';
import 'package:to_do_x/core/notification_service.dart';

class HomeController extends GetxController {
  var tasks = <Task>[].obs;
  var selectedDate = DateTime.now().obs;
  final storage = GetStorage();
  late ConfettiController confettiController;

  // Theme State
  var isDarkMode = false.obs;

  // Search State
  var searchQuery = ''.obs;

  final List<Map<String, dynamic>> categories = [
    {'name': 'General', 'color': 0xFF9E9E9E},
    {'name': 'Work', 'color': 0xFF2196F3},
    {'name': 'Personal', 'color': 0xFF4CAF50},
    {'name': 'Study', 'color': 0xFFFF9800},
    {'name': 'Health', 'color': 0xFFF44336},
  ];

  @override
  void onInit() {
    super.onInit();
    confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    // 1. Load Tasks
    var storedTasks = storage.read<List>('tasks');
    if (storedTasks != null) {
      tasks.assignAll(storedTasks.map((task) => Task.fromJson(task)).toList());
    }

    // 2. Load Theme Preference
    isDarkMode.value = storage.read('isDark') ?? false;

    // 3. Save Logic
    ever(tasks, (_) {
      storage.write('tasks', tasks.map((task) => task.toJson()).toList());
    });

    clearOldTasks();
  }

  @override
  void onClose() {
    confettiController.dispose();
    super.onClose();
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    storage.write('isDark', isDarkMode.value);
  }

  // --- Search & Filter Logic ---

  List<Task> get filteredTasks {
    var filtered = tasks.where((task) {
      // 1. Date Filter
      final isSameDate =
          task.date.year == selectedDate.value.year &&
          task.date.month == selectedDate.value.month &&
          task.date.day == selectedDate.value.day;

      // 2. Search Filter
      final matchesSearch = task.title.toLowerCase().contains(
        searchQuery.value.toLowerCase(),
      );

      return isSameDate && matchesSearch;
    }).toList();

    // Sort Logic
    filtered.sort((a, b) {
      if (a.isHighPriority && !b.isHighPriority) return -1;
      if (!a.isHighPriority && b.isHighPriority) return 1;
      bool aIsAllDay = a.date.hour == 0 && a.date.minute == 0;
      bool bIsAllDay = b.date.hour == 0 && b.date.minute == 0;
      if (!aIsAllDay && bIsAllDay) return -1;
      if (aIsAllDay && !bIsAllDay) return 1;
      return a.date.compareTo(b.date);
    });

    return filtered;
  }

  // Progress Calculation
  double get completionProgress {
    if (filteredTasks.isEmpty) return 0.0;
    int completed = filteredTasks.where((t) => t.isCompleted).length;
    return completed / filteredTasks.length;
  }

  String get progressText {
    if (filteredTasks.isEmpty) return "No tasks yet";
    int completed = filteredTasks.where((t) => t.isCompleted).length;
    return "$completed / ${filteredTasks.length} Completed";
  }

  // --- CRUD Operations ---

  void _scheduleTaskNotification(Task task) {
    // 1. Cancel any existing notification for this task ID
    NotificationService.cancelNotification(task.id.hashCode);

    if (!task.isReminderEnabled) return;

    DateTime? notifyAt;
    if (task.reminderMinutesBefore == 0) {
      // Logic for exact time
      notifyAt = task.date;
    } else {
      notifyAt = task.date.subtract(
        Duration(minutes: task.reminderMinutesBefore),
      );
    }

    if (notifyAt.isAfter(DateTime.now())) {
      NotificationService.scheduleNotification(
        task.id.hashCode, // Unique Int ID
        task.title,
        notifyAt,
        task.reminderMinutesBefore,
      );
    }
  }

  void addTask(
    String title,
    DateTime date,
    bool isHigh,
    String category,
    int color, {
    bool isReminder = false,
    int reminderMins = 0,
  }) {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: date,
      isHighPriority: isHigh,
      category: category,
      color: color,
      isReminderEnabled: isReminder,
      reminderMinutesBefore: reminderMins,
    );

    tasks.add(newTask);
    _scheduleTaskNotification(newTask);
  }

  void updateTask(
    Task task,
    String newTitle,
    DateTime newDate,
    bool isHigh,
    String newCategory,
    int newColor, {
    bool isReminder = false,
    int reminderMins = 0,
  }) {
    var index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final updatedTask = Task(
        id: task.id,
        title: newTitle,
        date: newDate,
        isHighPriority: isHigh,
        isCompleted: task.isCompleted,
        completedAt: task.completedAt,
        category: newCategory,
        color: newColor,
        isReminderEnabled: isReminder,
        reminderMinutesBefore: reminderMins,
      );

      tasks[index] = updatedTask;
      tasks.refresh();
      _scheduleTaskNotification(
        updatedTask,
      ); // Handles update/cancel automatically
    }
  }

  void deleteTask(String taskId) {
    NotificationService.cancelNotification(taskId.hashCode);
    tasks.removeWhere((task) => task.id == taskId);
  }

  void toggleTaskStatus(Task task) {
    task.isCompleted = !task.isCompleted;
    task.completedAt = task.isCompleted ? DateTime.now() : null;
    tasks.refresh();

    if (completionProgress == 1.0 && task.isCompleted) {
      confettiController.play();
    }
  }

  void clearOldTasks() {
    tasks.removeWhere((task) {
      if (task.isCompleted && task.completedAt != null) {
        return DateTime.now().difference(task.completedAt!).inHours >= 24;
      }
      return false;
    });
  }
}
