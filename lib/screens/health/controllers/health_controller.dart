import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class PeriodLog {
  DateTime startDate;
  DateTime? endDate; // Null means the period is currently active
  bool isIgnored;

  PeriodLog({required this.startDate, this.endDate, this.isIgnored = false});

  factory PeriodLog.fromJson(Map<String, dynamic> json) {
    return PeriodLog(
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isIgnored: json['isIgnored'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isIgnored': isIgnored,
    };
  }
}

class HealthController extends GetxController {
  final storage = GetStorage();

  // STATE
  final logs = <PeriodLog>[].obs;
  final averageCycleLength = 28.obs;
  final averageBleedLength = 5.obs; // Dynamically learns how long they bleed
  final predictedNextPeriod = DateTime.now().obs;

  bool get isPeriodActive => logs.isNotEmpty && logs.first.endDate == null;

  @override
  void onInit() {
    super.onInit();
    _loadLogs();
    _calculateStats();

    // Auto-save and Auto-sync UI whenever logs change
    ever<List<PeriodLog>>(logs, (_) {
      _saveLogs();
      _calculateStats();
      update([
        'calendar',
      ]); // Forces the Home Screen horizontal calendar to redraw
    });
  }

  void _loadLogs() {
    final stored = storage.read('period_logs');
    if (stored != null && stored is List) {
      logs.assignAll(
        stored
            .map((e) => PeriodLog.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
      logs.sort((a, b) => b.startDate.compareTo(a.startDate)); // Newest first
    }
  }

  void _saveLogs() {
    storage.write('period_logs', logs.map((e) => e.toJson()).toList());
  }

  // ================= ACTIONS (START / STOP) =================

  void startPeriod(DateTime date) {
    if (isPeriodActive) return; // Prevent double start

    // Outlier check (If gap is weird, flag it to ignore in math)
    bool ignore = false;
    if (logs.isNotEmpty) {
      final gap = date.difference(logs.first.startDate).inDays;
      if (gap < 21 || gap > 35) ignore = true;
    }

    logs.insert(0, PeriodLog(startDate: date, isIgnored: ignore));
  }

  void endPeriod(DateTime date) {
    if (!isPeriodActive) return;

    // Prevent ending before starting
    if (date.isBefore(logs.first.startDate)) {
      date = logs.first.startDate;
    }

    logs.first.endDate = date;
    logs.refresh(); // Triggers the 'ever' listener
  }

  void deleteLatestLog() {
    if (logs.isNotEmpty) {
      logs.removeAt(0);
      update(['calendar']);
    }
  }

  // ================= THE MATH ENGINE =================

  void _calculateStats() {
    if (logs.isEmpty) {
      predictedNextPeriod.value = DateTime.now();
      return;
    }

    // 1. AUTO-CAP SECURITY
    // If a user forgets to stop their period for 8 days, auto-close it to their average
    if (isPeriodActive) {
      final daysActive = DateTime.now().difference(logs.first.startDate).inDays;
      if (daysActive > 7) {
        logs.first.endDate = logs.first.startDate.add(
          Duration(days: averageBleedLength.value - 1),
        );
      }
    }

    // 2. BLEEDING LENGTH AVERAGE
    List<int> bleedLengths = [];
    for (var log in logs) {
      if (log.endDate != null) {
        // +1 to make it inclusive (e.g., 1st to 5th = 5 days)
        bleedLengths.add(log.endDate!.difference(log.startDate).inDays + 1);
      }
    }
    if (bleedLengths.isNotEmpty) {
      averageBleedLength.value =
          (bleedLengths.reduce((a, b) => a + b) / bleedLengths.length).round();
    } else {
      averageBleedLength.value = 5; // Default
    }

    // 3. CYCLE LENGTH AVERAGE (Weighted)
    if (logs.length >= 2) {
      List<int> cycleLengths = [];
      for (int i = 0; i < logs.length - 1; i++) {
        if (logs[i].isIgnored) continue;
        final gap = logs[i].startDate.difference(logs[i + 1].startDate).inDays;
        if (gap >= 15 && gap <= 60) cycleLengths.add(gap);
      }

      if (cycleLengths.isNotEmpty) {
        double weightedSum = 0;
        double totalWeight = 0;
        for (int i = 0; i < cycleLengths.length; i++) {
          double weight = (i == 0) ? 0.5 : (i == 1 ? 0.3 : 0.2);
          weightedSum += cycleLengths[i] * weight;
          totalWeight += weight;
        }
        averageCycleLength.value = (weightedSum / totalWeight).round();
      }
    }

    // 4. PREDICT NEXT PERIOD
    predictedNextPeriod.value = logs.first.startDate.add(
      Duration(days: averageCycleLength.value),
    );
  }

  // ================= CALENDAR HELPERS =================

  bool isPeriodDay(DateTime date) {
    DateTime target = _normalize(date);
    for (var log in logs) {
      DateTime start = _normalize(log.startDate);
      // If active, pretend the end date is "today" for drawing purposes
      DateTime end = log.endDate != null
          ? _normalize(log.endDate!)
          : _normalize(DateTime.now());

      if ((target.isAfter(start) || target.isAtSameMomentAs(start)) &&
          (target.isBefore(end) || target.isAtSameMomentAs(end))) {
        return true;
      }
    }
    return false;
  }

  bool isPredictedPeriodDay(DateTime date) {
    if (logs.isEmpty || isPeriodDay(date)) return false;

    DateTime target = _normalize(date);
    DateTime predictStart = _normalize(predictedNextPeriod.value);
    DateTime predictEnd = predictStart.add(
      Duration(days: averageBleedLength.value - 1),
    );

    if ((target.isAfter(predictStart) ||
            target.isAtSameMomentAs(predictStart)) &&
        (target.isBefore(predictEnd) || target.isAtSameMomentAs(predictEnd))) {
      return true;
    }
    return false;
  }

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
