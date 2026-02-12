import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/models/task_model.dart';

class HomeController extends GetxController {
  var tasks = <Task>[].obs;
  var selectedDate = DateTime.now().obs;
  final storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    var storedTasks = storage.read<List>('tasks');
    if (storedTasks != null) {
      tasks.assignAll(storedTasks.map((task) => Task.fromJson(task)).toList());
    }
    ever(tasks, (_) {
      storage.write('tasks', tasks.map((task) => task.toJson()).toList());
    });
    clearOldTasks();
  }

  List<Task> get filteredTasks {
    var filtered = tasks.where((task) {
      return task.date.year == selectedDate.value.year &&
          task.date.month == selectedDate.value.month &&
          task.date.day == selectedDate.value.day;
    }).toList();

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

  // UPDATED: Now accepts Category and Color
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
        isReminderEnabled: isReminder,
        reminderMinutesBefore: reminderMins,
        category: category,
        color: color,
      ),
    );
  }

  // NEW: Update Task Logic
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
        isReminderEnabled: isReminder,
        reminderMinutesBefore: reminderMins,
        category: newCategory,
        color: newColor,
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
