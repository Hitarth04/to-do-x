import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/models/task_model.dart';
import 'package:confetti/confetti.dart';

class HomeController extends GetxController {
  var tasks = <Task>[].obs;
  var selectedDate = DateTime.now().obs;
  final storage = GetStorage();

  // Theme State
  var isDarkMode = false.obs;

  // Search State
  var searchQuery = ''.obs;

  late ConfettiController confettiController;

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

    // FIX: Removed Get.changeThemeMode() from here.
    // main.dart already sets the correct theme on app launch.
    // Calling it here crashes the app because the UI is still building.

    // 3. Save Logic
    ever(tasks, (_) {
      storage.write('tasks', tasks.map((task) => task.toJson()).toList());
    });

    clearOldTasks();
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

      // 2. Search Filter (Safety check for null title)
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

  void addTask(
    String title,
    DateTime date,
    bool isHigh,
    String category,
    int color, {
    bool isReminder = false,
    int reminderMins = 0,
  }) {
    tasks.add(
      Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        date: date,
        isHighPriority: isHigh,
        category: category,
        color: color,
        isReminderEnabled: isReminder,
        reminderMinutesBefore: reminderMins,
      ),
    );
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
      tasks[index] = Task(
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
      tasks.refresh();
    }
  }

  void deleteTask(String taskId) {
    tasks.removeWhere((task) => task.id == taskId);
  }

  void toggleTaskStatus(Task task) {
    task.isCompleted = !task.isCompleted;
    task.completedAt = task.isCompleted ? DateTime.now() : null;
    tasks.refresh();

    // NEW: Check if all tasks are done
    if (completionProgress == 1.0 && task.isCompleted) {
      confettiController.play();
    }
  }

  @override
  void onClose() {
    confettiController.dispose(); // Clean up
    super.onClose();
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
