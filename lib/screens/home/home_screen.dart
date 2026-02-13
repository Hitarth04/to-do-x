import 'package:flutter/material.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:to_do_x/screens/home/widgets/task_card.dart';
import 'package:to_do_x/screens/home/widgets/special_fab.dart';
import 'controllers/home_controller.dart';
import '../../../core/app_colors.dart';
import '../../data/models/task_model.dart';
import '../notes/notes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EasyInfiniteDateTimelineController _calendarController =
      EasyInfiniteDateTimelineController();

  Worker? _dateWorker;

  @override
  void initState() {
    super.initState();
    // Safe initialization
    final controller = Get.put(HomeController(), permanent: false);

    // FIX: Initialize the listener only ONCE
    _dateWorker = ever(controller.selectedDate, (DateTime date) {
      try {
        _calendarController.animateToDate(date);
      } catch (e) {
        debugPrint("Calendar sync error: $e");
      }
    });
  }

  @override
  void dispose() {
    _dateWorker?.dispose(); // Prevent Memory Leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'My Tasks',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                controller.isDarkMode.value
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: controller.isDarkMode.value
                    ? Colors.yellow
                    : Colors.grey[800],
              ),
              onPressed: () => controller.toggleTheme(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AppColors.primary),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: controller.selectedDate.value,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) controller.selectedDate.value = picked;
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              _buildHorizontalCalendar(controller, context),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Dashboard
                    Obx(() {
                      if (controller.filteredTasks.isEmpty &&
                          controller.searchQuery.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return _buildDashboard(controller);
                    }),

                    const SizedBox(height: 15),

                    // Search Bar
                    TextField(
                      onChanged: (val) => controller.searchQuery.value = val,
                      decoration: InputDecoration(
                        hintText: "Search tasks...",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Obx(
                  () => controller.filteredTasks.isEmpty
                      ? Center(
                          child: Text(
                            controller.searchQuery.value.isEmpty
                                ? 'No tasks for today!'
                                : 'No matching tasks found',
                            style: GoogleFonts.poppins(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: controller.filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = controller.filteredTasks[index];
                            final bool isAllDay =
                                task.date.hour == 0 && task.date.minute == 0;
                            String formattedTime = isAllDay
                                ? "All Day"
                                : DateFormat('hh:mm a').format(task.date);

                            return Dismissible(
                              key: Key(task.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) {
                                final deletedTask = task;
                                final int globalIndex = controller.tasks
                                    .indexOf(task);
                                controller.deleteTask(task.id);

                                Get.snackbar(
                                  "Task Deleted",
                                  "${task.title} was removed",
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.black87,
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(10),
                                  duration: const Duration(seconds: 4),
                                  mainButton: TextButton(
                                    onPressed: () {
                                      if (globalIndex >= 0) {
                                        controller.tasks.insert(
                                          globalIndex,
                                          deletedTask,
                                        );
                                      } else {
                                        controller.tasks.add(deletedTask);
                                      }
                                      if (Get.isSnackbarOpen) Get.back();
                                    },
                                    child: const Text(
                                      "UNDO",
                                      style: TextStyle(color: Colors.yellow),
                                    ),
                                  ),
                                );
                              },
                              child: TaskCard(
                                title: task.title,
                                time: formattedTime,
                                category: task.category,
                                color: task.color,
                                onToggle: () =>
                                    controller.toggleTaskStatus(task),
                                isHigh: task.isHighPriority,
                                isDone: task.isCompleted,
                                onEdit: () => _showAddTaskSheet(
                                  context,
                                  taskToEdit: task,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: controller.confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDialFab(
        onTask: () => _showAddTaskSheet(context),
        onNote: () => Get.to(() => const NotesScreen()),
      ),
    );
  }

  Widget _buildDashboard(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daily Progress",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "${(controller.completionProgress * 100).toInt()}%",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: controller.completionProgress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Text(
            controller.progressText,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar(
    HomeController controller,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveBg = Theme.of(context).cardColor;
    final inactiveText = isDark ? Colors.white : Colors.grey;
    final todayText = isDark ? Colors.white : Colors.black;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => Text(
                  DateFormat('MMMM yyyy').format(controller.selectedDate.value),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => controller.selectedDate.value = controller
                        .selectedDate
                        .value
                        .subtract(const Duration(days: 7)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => controller.selectedDate.value = controller
                        .selectedDate
                        .value
                        .add(const Duration(days: 7)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Obx(
          () => EasyInfiniteDateTimeLine(
            controller: _calendarController,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            focusDate: controller.selectedDate.value,
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChange: (date) => controller.selectedDate.value = date,
            showTimelineHeader: false,
            dayProps: EasyDayProps(
              dayStructure: DayStructure.dayStrDayNum,
              activeDayStyle: DayStyle(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                dayNumStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                dayStrStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              todayStyle: DayStyle(
                decoration: BoxDecoration(
                  color: inactiveBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                dayNumStyle: TextStyle(
                  color: todayText,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                dayStrStyle: TextStyle(color: todayText, fontSize: 12),
              ),
              inactiveDayStyle: DayStyle(
                decoration: BoxDecoration(
                  color: inactiveBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey.shade100,
                  ),
                ),
                dayNumStyle: TextStyle(
                  color: inactiveText,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                dayStrStyle: TextStyle(color: inactiveText, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddTaskSheet(BuildContext context, {Task? taskToEdit}) {
    final HomeController controller = Get.find<HomeController>();
    final TextEditingController taskController = TextEditingController();

    final bool isEditing = taskToEdit != null;

    if (isEditing) {
      taskController.text = taskToEdit.title;
    }

    DateTime selectedDate = isEditing
        ? taskToEdit!.date
        : controller.selectedDate.value;
    bool hasTime =
        isEditing &&
        (taskToEdit!.date.hour != 0 || taskToEdit!.date.minute != 0);
    TimeOfDay? pickedTime = hasTime
        ? TimeOfDay.fromDateTime(taskToEdit!.date)
        : null;

    bool isHighPriority = isEditing ? taskToEdit!.isHighPriority : false;
    bool isReminderOn = isEditing ? taskToEdit!.isReminderEnabled : false;
    int minutesBefore = isEditing ? taskToEdit!.reminderMinutesBefore : 15;

    String selectedCategory = isEditing
        ? taskToEdit!.category
        : controller.categories.isNotEmpty
        ? controller.categories[0]['name']
        : 'General';
    int selectedColor = isEditing
        ? taskToEdit!.color
        : controller.categories.isNotEmpty
        ? controller.categories[0]['color']
        : 0xFF6C63FF;
    TimeOfDay? exactReminderTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? "Edit Task" : "New Task",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: taskController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: "What needs to be done?",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),
                    Text(
                      "Category",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: controller.categories.map((cat) {
                          bool isSelected = selectedCategory == cat['name'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(cat['name']),
                              selected: isSelected,
                              selectedColor: Color(
                                cat['color'],
                              ).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Color(cat['color'])
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey.shade100,
                              side: BorderSide(
                                color: isSelected
                                    ? Color(cat['color'])
                                    : Colors.transparent,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setSheetState(() {
                                    selectedCategory = cat['name'];
                                    selectedColor = cat['color'];
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        DateFormat('dd MMM, yyyy').format(selectedDate),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null)
                          setSheetState(() => selectedDate = date);
                      },
                    ),

                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(pickedTime?.format(context) ?? "All Day"),
                      trailing: pickedTime != null
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setSheetState(() => pickedTime = null),
                            )
                          : const Icon(Icons.arrow_drop_down),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null)
                          setSheetState(() => pickedTime = time);
                      },
                    ),

                    SwitchListTile(
                      title: const Text("Set Reminder"),
                      value: isReminderOn,
                      onChanged: (val) =>
                          setSheetState(() => isReminderOn = val),
                    ),

                    if (isReminderOn) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButton<int>(
                          value: minutesBefore,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 15,
                              child: Text("15 Mins Prior"),
                            ),
                            DropdownMenuItem(
                              value: 30,
                              child: Text("30 Mins Prior"),
                            ),
                            DropdownMenuItem(
                              value: 0,
                              child: Text("Custom/Exact Time"),
                            ),
                          ],
                          onChanged: (val) =>
                              setSheetState(() => minutesBefore = val!),
                        ),
                      ),
                      if (minutesBefore == 0)
                        ListTile(
                          leading: const Icon(Icons.timer_outlined),
                          title: Text(
                            exactReminderTime?.format(context) ??
                                "Select Exact Time",
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null)
                              setSheetState(() => exactReminderTime = time);
                          },
                        ),
                    ],

                    SwitchListTile(
                      title: const Text("High Priority"),
                      value: isHighPriority,
                      onChanged: (val) =>
                          setSheetState(() => isHighPriority = val),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Color(selectedColor),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (taskController.text.isNotEmpty) {
                            final DateTime taskDateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              pickedTime?.hour ?? 0,
                              pickedTime?.minute ?? 0,
                            );

                            if (isEditing) {
                              controller.updateTask(
                                taskToEdit!,
                                taskController.text,
                                taskDateTime,
                                isHighPriority,
                                selectedCategory,
                                selectedColor,
                                isReminder: isReminderOn,
                                reminderMins: minutesBefore,
                              );
                            } else {
                              controller.addTask(
                                taskController.text,
                                taskDateTime,
                                isHighPriority,
                                selectedCategory,
                                selectedColor,
                                isReminder: isReminderOn,
                                reminderMins: minutesBefore,
                              );
                            }
                            Navigator.pop(context);
                          }
                        },
                        child: Text(isEditing ? "Update Task" : "Create Task"),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
