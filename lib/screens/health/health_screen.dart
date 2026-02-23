import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/health_controller.dart';

class HealthScreen extends StatelessWidget {
  HealthScreen({super.key});

  final HealthController controller = Get.put(HealthController());

  final Rx<DateTime> selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Period Tracker")),
      body: Column(
        children: [
          /// HEADER
          _buildHeader(),

          /// CALENDAR
          Expanded(child: Obx(() => _buildCalendarGrid())),

          _buildLegend(),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPeriodToday(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Obx(() {
      final predicted = controller.predictedNextPeriod.value;

      final avg = controller.averageCycleLength.value;

      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              "Average Cycle : $avg days",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 6),

            Text(
              "Next Period : "
              "${predicted.day}/${predicted.month}/${predicted.year}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    });
  }

  // ================= CALENDAR =================

  Widget _buildCalendarGrid() {
    final month = selectedMonth.value;

    final firstDay = DateTime(month.year, month.month, 1);

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final startWeekday = firstDay.weekday % 7;

    final totalCells = startWeekday + daysInMonth;

    return GridView.builder(
      padding: const EdgeInsets.all(10),

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),

      itemCount: totalCells,

      itemBuilder: (context, index) {
        if (index < startWeekday) {
          return const SizedBox();
        }

        final day = index - startWeekday + 1;

        final date = DateTime(month.year, month.month, day);

        final today = DateTime.now();

        final isToday =
            today.year == date.year &&
            today.month == date.month &&
            today.day == date.day;

        final isLogged = controller.isPeriodDay(date);

        final isPredicted = controller.isPredictedPeriodDay(date);

        Color bgColor = Colors.transparent;

        if (isLogged) {
          bgColor = Colors.red.shade300;
        } else if (isPredicted) {
          bgColor = Colors.pink.shade100;
        }

        return GestureDetector(
          onLongPress: () => _showDeleteDialog(date),

          child: Container(
            margin: const EdgeInsets.all(4),

            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),

              border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
            ),

            child: Center(
              child: Text("$day", style: const TextStyle(fontSize: 16)),
            ),
          ),
        );
      },
    );
  }

  // ================= LEGEND =================

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendBox(Colors.red.shade300, "Logged"),

          _legendBox(Colors.pink.shade100, "Predicted"),

          _legendBox(
            Colors.white,
            "Today",
            border: Border.all(color: Colors.blue, width: 2),
          ),
        ],
      ),
    );
  }

  Widget _legendBox(Color color, String label, {Border? border}) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border,
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  // ================= ACTIONS =================

  void _addPeriodToday() {
    controller.logPeriod(DateTime.now());

    Get.snackbar(
      "Added",
      "Today's period logged",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showDeleteDialog(DateTime date) {
    Get.defaultDialog(
      title: "Delete Log?",
      middleText: "Remove this period log?",

      textConfirm: "Delete",
      textCancel: "Cancel",

      onConfirm: () {
        controller.deleteLog(date);

        Get.back();
      },
    );
  }
}
