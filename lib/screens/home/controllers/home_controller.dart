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

    // Load tasks from storage
    var storedTasks = storage.read<List>('tasks');
    if (storedTasks != null) {
      tasks.assignAll(storedTasks.map((task) => Task.fromJson(task)).toList());
    }

    // Auto-save whenever 'tasks' list changes
    ever(tasks, (_) {
      storage.write('tasks', tasks.map((task) => task.toJson()).toList());
    });

    clearOldTasks();
  }

  List<Task> get filteredTasks {
    return tasks.where((task) {
      return task.date.year == selectedDate.value.year &&
          task.date.month == selectedDate.value.month &&
          task.date.day == selectedDate.value.day;
    }).toList();
  }

  void addTask(
    String title,
    DateTime date,
    bool isHigh, {
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
      ),
    );
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

  void deleteTask(String taskId) {
    tasks.removeWhere((task) => task.id == taskId);
    // The 'ever' worker will automatically update storage
  }

  List<DateTime> get taskDates => tasks
      .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
      .toList();
}
