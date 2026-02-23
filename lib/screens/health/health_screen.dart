import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'controllers/health_controller.dart';
import '../../core/app_colors.dart';

class HealthScreen extends StatelessWidget {
  HealthScreen({super.key});

  final HealthController controller = Get.put(HealthController());
  final Rx<DateTime> selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          "Cycle Tracking",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.undo, color: textColor),
            onPressed: () => _showUndoDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. CIRCULAR STATUS DASHBOARD
            _buildCircularDashboard(context),
            const SizedBox(height: 30),

            // 2. CALENDAR HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final current = selectedMonth.value;
                    selectedMonth.value = DateTime(
                      current.year,
                      current.month - 1,
                    );
                  },
                ),
                Obx(
                  () => Text(
                    DateFormat('MMMM yyyy').format(selectedMonth.value),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final current = selectedMonth.value;
                    selectedMonth.value = DateTime(
                      current.year,
                      current.month + 1,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 3. CALENDAR GRID
            Obx(() => _buildCalendarGrid(context)),
            const SizedBox(height: 15),

            // 4. LEGEND
            _buildLegend(isDark),
            const SizedBox(height: 30),

            // 5. START / STOP BUTTON
            Obx(() {
              bool isActive = controller.isPeriodActive;
              return SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? (isDark ? Colors.grey[800] : Colors.black87)
                        : Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: isActive ? 0 : 5,
                  ),
                  onPressed: () => _showActionDialog(context, isActive),
                  child: Text(
                    isActive ? "Log Period Ended" : "Log Period Started",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ================= CIRCULAR DASHBOARD =================
  Widget _buildCircularDashboard(BuildContext context) {
    return Obx(() {
      bool isActive = controller.isPeriodActive;
      int daysUntil = controller.predictedNextPeriod.value
          .difference(DateTime.now())
          .inDays;

      String mainText;
      String subText;

      if (isActive) {
        int dayOfPeriod =
            DateTime.now().difference(controller.logs.first.startDate).inDays +
            1;
        mainText = "Day $dayOfPeriod";
        subText = "of period";
      } else {
        if (daysUntil == 0) {
          mainText = "Today";
          subText = "Period expected";
        } else if (daysUntil < 0) {
          mainText = "${daysUntil.abs()} Days";
          subText = "Late";
        } else {
          mainText = "$daysUntil";
          subText = "Days to go";
        }
      }

      return Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: isActive
                ? [Colors.pinkAccent.shade100, Colors.redAccent]
                : [AppColors.primary.withOpacity(0.5), AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? Colors.redAccent : AppColors.primary)
                  .withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.water_drop,
                  color: isActive ? Colors.redAccent : Colors.grey,
                  size: 28,
                ),
                const SizedBox(height: 10),
                Text(
                  mainText,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? Colors.redAccent
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  subText,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ================= CALENDAR GRID =================
  Widget _buildCalendarGrid(BuildContext context) {
    final month = selectedMonth.value;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: daysInMonth + (firstWeekday - 1),
      itemBuilder: (context, index) {
        if (index < firstWeekday - 1) return const SizedBox.shrink();

        final day = index - (firstWeekday - 1) + 1;
        final date = DateTime(month.year, month.month, day);

        bool isPeriod = controller.isPeriodDay(date);
        bool isPredicted = controller.isPredictedPeriodDay(date);
        bool isToday =
            date.day == DateTime.now().day &&
            date.month == DateTime.now().month &&
            date.year == DateTime.now().year;

        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Use the button below to log dates.",
                  style: GoogleFonts.poppins(),
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPeriod
                  ? Colors.redAccent
                  : (isPredicted
                        ? Colors.pink.withOpacity(0.15)
                        : Colors.transparent),
              border: isToday
                  ? Border.all(
                      color: isPeriod ? Colors.white : AppColors.primary,
                      width: 2,
                    )
                  : (isPredicted
                        ? Border.all(color: Colors.pinkAccent, width: 1)
                        : null),
              shape: BoxShape.circle,
            ),
            child: Text(
              "$day",
              style: TextStyle(
                color: isPeriod
                    ? Colors.white
                    : (isPredicted
                          ? Colors.pinkAccent
                          : Theme.of(context).textTheme.bodyMedium?.color),
                fontWeight: isPeriod || isToday || isPredicted
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= LEGEND =================
  Widget _buildLegend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.redAccent, "Period"),
        const SizedBox(width: 20),
        _legendItem(
          Colors.pink.withOpacity(0.2),
          "Predicted",
          borderColor: Colors.pinkAccent,
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label, {Color? borderColor}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  // ================= BOTTOM SHEET LOGGING =================
  void _showActionDialog(BuildContext context, bool isActive) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isActive
                  ? "When did your period end?"
                  : "When did your period start?",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.today, color: AppColors.primary),
              ),
              title: Text(
                "Today",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                if (isActive) {
                  controller.endPeriod(DateTime.now());
                } else {
                  controller.startPeriod(DateTime.now());
                }
                Get.back();
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, color: Colors.orange),
              ),
              title: Text(
                "Yesterday",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                final yesterday = DateTime.now().subtract(
                  const Duration(days: 1),
                );
                if (isActive) {
                  controller.endPeriod(yesterday);
                } else {
                  controller.startPeriod(yesterday);
                }
                Get.back();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showUndoDialog() {
    Get.defaultDialog(
      title: "Undo Last Log?",
      titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      middleText: "This will delete the most recent period entry.",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        controller.deleteLatestLog();
        Get.back();
      },
    );
  }
}
