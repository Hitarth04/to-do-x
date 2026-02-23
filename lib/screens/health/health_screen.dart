import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'controllers/health_controller.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final HealthController controller = Get.put(HealthController());
  DateTime _focusedMonth = DateTime.now();

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. CYCLE STATUS CARD
            _buildStatusCard(context),
            const SizedBox(height: 30),

            // 2. CALENDAR HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(
                    () => _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(
                    () => _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 3. CALENDAR GRID
            _buildCalendarGrid(),

            const SizedBox(height: 30),

            // 4. LOG BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () => _handleDateSelection(DateTime.now()),
                child: Text(
                  "Log Period Started Today",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Obx(() {
      int daysUntil = controller.predictedNextPeriod.value
          .difference(DateTime.now())
          .inDays;
      String statusText = daysUntil > 0
          ? "$daysUntil Days until next period"
          : "Period might be late";
      if (controller.isPeriodDay(DateTime.now())) statusText = "Period Day";

      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.redAccent.shade100, Colors.redAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Cycle Status",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Avg Cycle: ${controller.averageCycleLength.value} Days",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 30),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCalendarGrid() {
    int daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;

    int firstWeekday = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    ).weekday; // 1=Mon, 7=Sun

    return Obx(() {
      /// ✅ Explicit reactive dependency (IMPORTANT)
      controller.logs.length;
      controller.predictedNextPeriod.value;
      controller.periodDuration.value;

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
          if (index < firstWeekday - 1) {
            return const SizedBox.shrink();
          }

          final day = index - (firstWeekday - 1) + 1;

          final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);

          final now = DateTime.now();

          bool isPeriod = controller.isPeriodDay(date);
          bool isPredicted = controller.isPredictedPeriodDay(date);

          bool isToday =
              date.day == now.day &&
              date.month == now.month &&
              date.year == now.year;

          return GestureDetector(
            onTap: () => _handleDateSelection(date),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isPeriod
                    ? Colors.redAccent
                    : (isPredicted
                          ? Colors.red.withOpacity(0.1)
                          : Colors.transparent),
                border: isToday
                    ? Border.all(color: Colors.redAccent, width: 2)
                    : (isPredicted
                          ? Border.all(color: Colors.redAccent, width: 1)
                          : null),
                shape: BoxShape.circle,
              ),
              child: Text(
                "$day",
                style: TextStyle(
                  color: isPeriod
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: (isPeriod || isToday)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _handleDateSelection(DateTime date) {
    // 1. Check Outlier
    if (controller.checkIsOutlier(date)) {
      Get.defaultDialog(
        title: "Irregular Cycle?",
        titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        middleText:
            "This cycle gap is unusual. Do you want to include it in your future predictions?",
        textConfirm: "Yes, Update",
        textCancel: "No, Ignore",
        confirmTextColor: Colors.white,
        buttonColor: Colors.redAccent,
        onConfirm: () {
          controller.logPeriod(date, ignoreForPrediction: false);
          Get.back();
        },
        onCancel: () {
          controller.logPeriod(date, ignoreForPrediction: true);
        },
      );
    } else {
      // Toggle logic: If already exists, delete it. Else add it.
      if (controller.isPeriodDay(date)) {
        controller.deleteLog(date);
      } else {
        controller.logPeriod(date);
      }
    }
  }
}
