import 'package:flutter/material.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:to_do_x/core/notification_service.dart';
import 'package:to_do_x/screens/home/widgets/task_card.dart';
import 'controllers/home_controller.dart';
import '../../../core/app_colors.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final EasyInfiniteDateTimelineController _calendarController =
      EasyInfiniteDateTimelineController();

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

    ever(controller.selectedDate, (DateTime date) {
      _calendarController.animateToDate(date);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'My Tasks',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
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
      body: Column(
        children: [
          _buildHorizontalCalendar(controller),
          const SizedBox(height: 20),
          Expanded(
            child: Obx(
              () => controller.filteredTasks.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks for today!',
                        style: GoogleFonts.poppins(),
                      ),
                    )
                  : ListView.builder(
                      itemCount: controller.filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = controller.filteredTasks[index];
                        String formattedTime =
                            (task.date.hour == 0 && task.date.minute == 0)
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
                            final int globalIndex = controller.tasks.indexOf(
                              task,
                            );

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
                                  if (globalIndex >= 0 &&
                                      globalIndex <= controller.tasks.length) {
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
                                  style: TextStyle(
                                    color: Colors.yellow,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: TaskCard(
                            title: task.title,
                            time: formattedTime,
                            onToggle: () => controller.toggleTaskStatus(task),
                            isHigh: task.isHighPriority,
                            isDone: task.isCompleted,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final TextEditingController taskController = TextEditingController();

    DateTime selectedDate = controller.selectedDate.value;
    TimeOfDay? pickedTime;
    bool isHighPriority = false;
    bool isReminderOn = false;
    int minutesBefore = 15;
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
                      "New Task",
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
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setSheetState(() => selectedDate = date);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(pickedTime?.format(context) ?? "All Day"),
                      trailing: pickedTime != null
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () {
                                setSheetState(() => pickedTime = null);
                              },
                            )
                          : const Icon(Icons.arrow_drop_down),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setSheetState(() => pickedTime = time);
                        }
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
                            if (time != null) {
                              setSheetState(() => exactReminderTime = time);
                            }
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

                            if (isReminderOn) {
                              DateTime? notifyAt;
                              bool timeSelected = true;

                              if (minutesBefore == 0) {
                                if (exactReminderTime != null) {
                                  notifyAt = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    exactReminderTime!.hour,
                                    exactReminderTime!.minute,
                                  );
                                } else {
                                  timeSelected = false;
                                }
                              } else {
                                notifyAt = taskDateTime.subtract(
                                  Duration(minutes: minutesBefore),
                                );
                              }

                              if (!timeSelected) {
                                Get.snackbar(
                                  "Missing Info",
                                  "Please select an exact time for the reminder",
                                  backgroundColor: Colors.redAccent,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              if (notifyAt != null &&
                                  notifyAt.isAfter(DateTime.now())) {
                                // The ID must be a unique Integer within the valid range.
                                // Using milliseconds can sometimes overflow 32-bit integers on Android.
                                // A safer way is to use a truncated timestamp or a random int.
                                int uniqueId = DateTime.now()
                                    .millisecondsSinceEpoch
                                    .remainder(100000);

                                NotificationService.scheduleNotification(
                                  uniqueId,
                                  taskController.text,
                                  notifyAt,
                                  minutesBefore,
                                );
                              } else {
                                Get.snackbar(
                                  "Warning",
                                  "Reminder time is in the past! Task saved without reminder.",
                                  backgroundColor: Colors.orangeAccent,
                                  colorText: Colors.white,
                                );
                              }
                            }

                            controller.addTask(
                              taskController.text,
                              taskDateTime,
                              isHighPriority,
                              isReminder: isReminderOn,
                              reminderMins: minutesBefore,
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Create Task"),
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

  Widget _buildHorizontalCalendar(HomeController controller) {
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
            itemBuilder: (context, date, isSelected, onTap) => Obx(() {
              bool hasTask = controller.tasks.any(
                (t) =>
                    t.date.year == date.year &&
                    t.date.month == date.month &&
                    t.date.day == date.day,
              );
              return InkWell(
                onTap: onTap,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade100,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date),
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (hasTask)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
